#!/bin/bash
#

export PATH=$PATH:/usr/local/bin

authurl=https://ams01.objectstorage.service.networklayer.com/auth/v1.0/
tenant=ams01

ams_authurl=https://ams01.objectstorage.service.networklayer.com/auth/v1.0/
ams_tenant=ams01

par_authurl=https://par01.objectstorage.service.networklayer.com/auth/v1.0/
par_tenant=par01

case $1 in
	mount)
		cloudfuse -o authurl=$ams_authurl,tenant=$ams_tenant,gid=995,umask=007,uid=997,allow_other /objectStorage;;

	umount)
		umount /objectStorage;;
	start)
		cloudfuse -o authurl=$ams_authurl,tenant=$ams_tenant,gid=995,umask=007,uid=997,allow_other /objectStorage
		cloudfuse -o authurl=$par_authurl,tenant=$par_tenant,gid=995,umask=007,uid=997,allow_other /backup
		docker start seafile-db
		sleep 10
		sudo -u seafile /opt/seafile/seafile-server-latest/seafile.sh start
		sudo -u seafile /opt/seafile/seafile-server-latest/seahub.sh start-fastcgi
		;;
	stop)
		sudo -u seafile /opt/seafile/seafile-server-latest/seahub.sh stop
		sudo -u seafile /opt/seafile/seafile-server-latest/seafile.sh stop
		docker stop seafile-db
		umount /objectStorage
		umount /backup
		;;
	status)
		docker ps fil-te.cloudwalker.no-db
		ps -ef | grep sea
		;;
	*)
		echo "Usage : $0 {start|stop|status}";;
esac
