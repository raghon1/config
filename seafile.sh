#!/bin/bash
#

username=SLOS410594-2:sl410594-rh
api_key=ac5e4f5c23b039ec5d86068a7d520ed01bbd67ff9cc94f0a1413fe415471c54b
authurl=https://ams01.objectstorage.service.networklayer.com/auth/v1.0/
tenant=ams01

ams_authurl=https://ams01.objectstorage.service.networklayer.com/auth/v1.0/
ams_tenant=ams01

par_authurl=https://par01.objectstorage.service.networklayer.com/auth/v1.0/
par_tenant=par01

case $1 in 
	start)
		cloudfuse -o username=$username,api_key=$api_key,authurl=$ams_authurl,tenant=$ams_tenant,gid=0,umask=007,uid=0,allow_other /objectStorage
		cloudfuse -o username=$username,api_key=$api_key,authurl=$par_authurl,tenant=$par_tenant,gid=0,umask=007,uid=0,allow_other /backup
		docker start fil-te.cloudwalker.no-db
		sleep 10
		(cd /opt/seafile/seafile-latest ; ./seafile.sh start)
		(cd /opt/seafile/seafile-latest ; ./seahub.sh start-fastcgi)
		;;
	stop)
		(cd /opt/seafile/seafile-latest ;  ./seahub.sh stop)
		(cd /opt/seafile/seafile-latest ;  ./seafile.sh stop)
		docker stop fil-te.cloudwalker.no-db
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

