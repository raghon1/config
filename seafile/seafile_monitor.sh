#!/bin/bash
#

runlevel=$(who -r | awk '{print $2}')
[ $runlevel -ne 3 ] && exit 0

stores="/objectStorage /backup"

seafile_restart() {
	/opt/cloudwalker/bin/seafile.sh stop
	/opt/cloudwalker/bin/seafile.sh start
	exit 0
}

for fs in $stores ; do 
	df -ht fuse.cloudfuse $fs >/dev/null 2>&1
	if [ $? -ne 0 ] ; then
		echo "WARNING: $fs not mounted, restarting seafile"
		seafile_restart
	fi
	pid_seahub=$(cat /opt/seafile/seafile-server-latest/runtime/seahub.pid)
	ps -p $pid_seahub -o cmd=  | grep 'seahub/manage.py' >/dev/null 2>&1
	if [ $? -ne 0 ] ; then
		echo "WARNING: seahub process has stopped, restarting seafile"
		seafile_restart
	fi
	pid_ccnet=$(cat /opt/seafile/pids/ccnet.pid)
	ps -p $pid_ccnet -o cmd=  | grep 'ccnet-server' >/dev/null 2>&1
	if [ $? -ne 0 ] ; then
		echo "WARNING: ccnet process has stopped, restarting seafile"
		seafile_restart
	fi
	pid_seafile=$(cat /opt/seafile/pids/seaf-server.pid)
	ps -p $pid_seafile -o cmd=  | grep 'seaf-server' >/dev/null 2>&1
	if [ $? -ne 0 ] ; then
		echo "WARNING: seaf-server process has stopped, restarting seafile"
		seafile_restart
	fi
done
