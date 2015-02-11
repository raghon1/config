#!/bin/bash
#

dbs="te-ccnet-db te-seafile-db te-seahub-db"

dbserver=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' fil-te.cloudwalker.no-db)

mkdir -p /backup/databases
for db in $dbs; do
	mysqldump -h $dbserver -uroot -pjeyb-fu-hen-ayn- --opt $db > /backup/databases/$db-db.sql.`date +"%Y-%m-%d-%H-%M-%S"`
done
