#!/bin/ksh
#

# ZFS snapshot backup using TSM
# Developed by Ragnar @ RagHon Consulting
#
# Usage, edit the first lines in this script to say which filesystems to
# include/exclude.

# PS : if include_fs="", all zfs filesystems will be backed up. This require that
# the TSM configuration exclude all zfs filesystems!!!!
# Its reccomended to use include_fs and only snap backup those filesystems having dynamic data

# Create code in the freeze and thaw functions, to set your application(s) in a backup modus, or stop them
# use the thaw function to reenable the applications.


include_fs="datapool/data datapool/mycom dbpool/backup"
#include_fs=""
exclude_fs=""

# Define following vars, if using netapp snapshot

# NETAPP="snapshot"
# NETAPP="snapvault"
# NETAPP="no"
NETAPP="snapshot"
ZFS="yes"
LVM="no"
lvm_snap_size="12M"

# Maximum number of snapshots to keep on the filer
VERSIONS=2

freezeFail="thaw"

FILER="v85z2f1-mgmt.nsc.no"
USER="snap_mpmtest"
VOLUME="mpm_test_flatfiles"
SSH_KEY="/etc/adsm/aux1/keys/snap_mpmtest"

out="-u2"

# Freeze function, add commands to set applications in
# a quite state.
freeze() {
        ${no_exec} print "Fryser Mycom system til backup modus"

        MYCOM=/opt/mycom/shell/admin/backup
        export STREAM_NUMBER=0
        export STREAM_COUNT=1
        ${no_exec} ${MYCOM}/bpstart_notify.MycomBackup $(hostname) TNLV1 TSMCMD FULL
        return $?
}

# Thaw function, add commands to online applications
#
thaw() {
        MYCOM=/opt/mycom/shell/admin/backup
        export STREAM_NUMBER=0
        export STREAM_COUNT=1
        ${no_exec} print "Tiner Mycom system fra backup modus"
        ${no_exec} ${MYCOM}/bpend_notify.MycomBackup $(hostname) TNLV1 TSMCMD FULL 0
        return $?
}


# #########################################
# TSM variables
# #########################################
LC_TIME='C'
LANG='no_NO'
DSM_LOG='/var/log/tsm/aux1'
DSM_DIR='/opt/tivoli/tsm/client/ba/bin'
DSM_CONFIG='/etc/adsm/aux1/dsm.opt'
export LC_TIME LANG DSM_LOG DSM_DIR DSM_CONFIG
errorLog=${DSM_LOG}/ZFS_snap.err
Log=${DSM_LOG}/ZFS_snap.log

# Redir STDOUT to ${Log} and STDERR to ${errorLog}
exec 4>&2 5>&1
exec 1> ${Log}
exec 2> ${errorLog}

# #########################################
# Do not edit below this line !!!
# #########################################

zfs=/usr/sbin/zfs
lvm=/sbin/lvm


# If ${include_fs} aint defined, find all zfs filesytems in the system
# PS : not reccomended!!!
[ -z "${include_fs}" -a "${ZFS}" == "yes" ] && include_fs=$(${zfs} list -o name -Ht filesystem)


# Try to figure out where the filesystem is mounted
check_fs() {
        fs=$1

	if [ -f ${zfs} ] ; then
		mounted=$(${zfs} get -Ho value mounted ${fs})
		mountpoint=$(${zfs} list -Ht filesystem -o mountpoint ${fs})
	elif [ -f ${lvm} ] ; then
		dev=$(${lvm} lvdisplay  --noheadings -C -o lv_path ${fs})
		if df ${dev} >/dev/null 2>&1 ; then
			mounted="yes"
			mountpoint=$(df -P  $(${lvm} lvdisplay  --noheadings -C -o lv_path ${fs}) | awk '!/Filesystem/ {print $6}')
			:
		else
			mounted="no"
		fi
	fi
        if [ "${mounted}" = "no" ] ; then
                print "Skipping ${fs}, not mounted," 2>> ${errorLog}
                return 1
        fi
        if [ "${mountpoint}" = "legacy" ] ; then
                vfstab=$(nawk '$1 == "'${fs}'" {print $3}' /etc/vfstab)
                if [ -z "${vfstab}" ] ; then
                        mounted=$(mount | nawk '$3 == "'${fs}'" {print $1}')
                        if [ -z "${mounted}" ] ; then
                                print "${fs} not defined as mountable in zfs or vfstab" >&2
                                return 1
                        fi
                        mountpoint=${mounted}
                elif [ -d "${vfstab}/.zfs/snapshot" ] ; then
                        mountpoint=${vfstab}
                else
                        print "${fs} mounted in vfstab, but not a zfs filesystem" >&2
                fi
        fi
}

# Destroy snapshot
rm_snapshot() {
        fs=$1
	if [ ${ZFS} == "yes" ] ; then 
		if ${zfs} list -t snapshot ${fs}@tsmbackup >/dev/null 2>&1 ; then
			if ! zfs destroy ${fs}@tsmbackup ; then
				print "Not able to destroy ${fs}@tsmbackup" >&2
				print "EXITING " >&2
				return 1
			fi
		fi
	else
		if ${lvm} lvdisplay --noheadings -C -o lv_path ${fs}_tsmbackup >/dev/null 3>&1 ; then
			snapdev=$(${lvm} lvdisplay  --noheadings -C -o lv_path ${fs}_tsmbackup | awk '{print $1}')
			set -x
			if df -P ${snapdev} ; then
				umount -f ${snapdev}
				rmdir ${mountpoint}/.zfs/snapshot/tsmbackup
				rmdir ${mountpoint}/.zfs/snapshot
				rmdir ${mountpoint}/.zfs
			fi
			set -
			if ! $lvm lvremove -f ${fs}_tsmbackup ; then
				print "Not able to destroy ${fs}@tsmbackup" >&2
				print "EXITING " >&2
				return 1
			fi
		fi
	fi
}

# Create ZFS snapshot
mk_snapshot() {
        fs=$1
        rm_snapshot ${fs}
	if [ $ZFS == "yes" ] ; then
		if ! zfs snapshot ${fs}@tsmbackup >/dev/null 2>&1 ; then
			print "Not able to create ${fs}@tsmbackup" ${out}>&2
			print "EXITING" ${out}>> ${errorLog}
			return 1
		fi
	elif [ $LVM == "yes" ] ; then
		# make lvm snapshot
		if ! ${lvm} lvcreate --snapshot --size ${lvm_snap_size} -n ${fs#*/}_tsmbackup ${fs} 3>&1 ; then
			print "Not able to create ${fs}@tsmbackup" ${out}>&2
			print "EXITING" ${out}>> ${errorLog}
			return 1
		else 
			snapdev=$(${lvm} lvdisplay  --noheadings -C -o lv_path ${fs}_tsmbackup)
                	echo TEST ${mountpoint} $snapdev
			mkdir -p ${mountpoint}/.zfs/snapshot/tsmbackup
			mount -r ${snapdev} ${mountpoint}/.zfs/snapshot/tsmbackup
			# on linux we need to mount the snapshot somwhere
		fi
	fi
}

list_netapp_snapshots() {
        snap_show="$ssh_filer snapshot show -volume ${VOLUME} -comment \"snapbkp\" -fields vserver,volume,snapshot,comment,state -busy false"
        snap_show_out=$($snap_show 2>&1)
        snap_list=$(print "$snap_show_out" | nawk '$4 == "snapbkp" {print $3}')

        snapCount=$(print "$snap_list" | wc -l | sed 's/ //g')
}

# Create Netapp snapshot
mk_netapp_snapshot() {
        DAY=$(/usr/bin/date '+%a')
        DATE=$(/usr/bin/date '+%a.%d.%m.%Y')
        DATE2=$(/usr/bin/date '+%Y%m%d')

        # Create SNAP
        VAULT="nightly"
        [ $DAY = "Sun" ] && VAULT="weekly"

        print "Creating NETAPP snapshot ${vault} on volume ${VOLUME} ${DATE}"

        case $NETAPP in
                snapshot)
                        ssh_filer="/usr/bin/ssh -i ${SSH_KEY} ${USER}@${FILER}"
                        snapcmd="/usr/bin/ssh -i ${SSH_KEY} ${USER}@${FILER} snapshot create -volume ${VOLUME} -snapshot ${VOLUME}.${DATE2}"
                        if [ -z "${no_exec}" ] ; then
                                if ! $snapcmd ; then
                                        return 1
                                fi
                        else
                                print -u4 "$snapcmd"
                        fi
                        list_netapp_snapshots

                        nr=1
                        while [ $snapCount -gt $VERSIONS ] ; do
                                rm_snapshot=$(print "$snap_list" | head -$nr | tail -1)
                                if [ -n "${rm_snaps_error}" ] ; then
                                        for rm in ${rm_snaps_error} ; do
                                                if [ $rm == $rm_snapshot ] ; then
                                                        continue
                                                fi
                                        done
                                fi
                                snap_delete="$ssh_filer snapshot delete -volume ${VOLUME} -snapshot $rm_snapshot"
                                if [ -z "${no_exec}" ] ; then
                                        exec_snap_delete=$($snap_delete 2>&1)
                                else
                                        print -u4 $snap_delete
                                        if ! $snap_delete ; then
                                                rm_snaps_error="$rm_snaps_error$rm_snapshot "
                                                print "Not able to delete $rm_snapshot"
                                                list_netapp_snapshots
                                                let snapCount=${snapCount}-$nr
                                                let nr=$nr+1
                                                continue
                                        fi
                                fi
                                list_netapp_snapshots
                        done

                        ;;
                snapvault)
                        netappsnap=$(/usr/bin/ssh -i ${SSH_KEY} ${USER}@${FILER} snapvault snap create -w ${VOLUME} ${VOLUME}_${VAULT} 2>&1)
                        snapstat=$(print "${netappsnap}" | grep "Snapshot creation successful")
                        case ${snapstat} in
                                *successful*)
                                        return 0
                                        ;;
                        esac
                        ;;
                        *)
                                print -u4 "Please correct the variable \$NETAPP, and rerun"
                                exit 1
                        ;;
        esac

        snapstat=$(print "${netappsnap}" | grep "0")

        case ${snapstat} in
                *0*)
                        return 0
                        ;;
        esac


        if [ -n "${netappsnap}" ] ; then
                return 1
        else
                return 0
        fi
}

# Backup snapshot to TSM
backup() {
        fs=$1
        mountpoint=$2
        no_exec=$3
        if [ -z "${no_exec}" ] ; then
                dsmc i -quiet -snapshotroot=${mountpoint}/.zfs/snapshot/tsmbackup ${mountpoint}
                rm_snapshot ${fs}
        else
                print -u4 dsmc i -quiet -snapshotroot=${mountpoint}/.zfs/snapshot/tsmbackup ${mountpoint}
                print -u4 rm_snapshot ${fs}
        fi
}

help() {
        print -u4 "Usage: $0 [-v] [-n] [-h]

        $0      :->     without any arguments, execute backup
        $0 -n   :->     execute, but dont execute dsmc, but print out the commands to the logfile
        $0 -v   :->     print version number of this script
        $0 -h   :->     print this help file

        "
        exit 1
}
while getopts vnh name ; do
        case $name in
                v) print -u4 VERSION 1.3 ; exit 0;;
                n)  out="-u4" ; no_exec="print -u4";;
                h) help;;
        esac
done

# Stop or place apps in backup modus
if ! freeze ; then
        if [ "${freezeFail}" = "thaw" ] ; then
                print ${out} "not able to freeze, thaw application"
                thaw
        fi
        print ${out} "not able to freeze, exiting"
        exit 1
fi

# Do netapp snapshot
if [ "${NETAPP}" != "no" ] ; then
        if ! mk_netapp_snapshot ; then
                if [ "${freezeFail}" = "thaw" ] ; then
                        print -${out} "not able to snap netapp, thaw application"
                        thaw
                fi
                exit 1
        fi
fi

if [ "${ZFS}" == "yes" -o "${LVM}" == "yes" ] ; then
        for include in ${include_fs} ; do
                skip=0
                for exclude in ${exclude_fs} ; do
                        if [ "${include}" = "${exclude}" ] ; then
                                print excluding $exclude 2>> ${errorLog}
                                skip=1
                        fi
                done
                [ "${skip}" -eq 1 ] && continue

                if check_fs ${include} ; then
                        if ! ${no_exec} ${no_exec} mk_snapshot ${include} ; then
                                if [ "${freezeFail}" = "thaw" ] ; then
                                        print -${out} "not able to snap zfs, thaw application"
                                        thaw
                                fi
                                exit 1
                        fi
                        do_backup="${do_backup} ${include}:${mountpoint}"
                fi
        done
fi

# Unfreeze applications, but do not wait for them to start!!!
# PS : you will not get a warning from this script if applications don't start
thaw &

# Loop all filesystems and do backup
for bkp in ${do_backup} ; do
        IFS=:
        set -A BKP ${bkp}
        fs=${bkp[0]}
        mountpoint=${bkp[1]}
        backup ${fs} ${mountpoint} ${no_exec}
done
