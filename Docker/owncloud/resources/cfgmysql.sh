#!/bin/bash -x

rm -rf /var/lib/mysql/*
/usr/bin/mysql_install_db
chown -R mysql:mysql /var/lib/mysql
/usr/bin/mysqld_safe &
sleep 5
/usr/bin/mysqladmin -u root password newroot
/usr/bin/mysql -u root -pnewroot -e "CREATE DATABASE owncloud; GRANT ALL ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY 'owncloudsql';"
pkill -f mysqld
