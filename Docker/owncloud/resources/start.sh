#!/bin/bash

# Create SSL certificates if they don't exist
if [ ! -f /etc/httpd/ssl/server.key ]; then
	mkdir -p /etc/httpd/ssl
	KEY=/etc/httpd/ssl/server.key
	DOMAIN=$(hostname)
	export PASSPHRASE=$(head -c 128 /dev/urandom  | uuencode - | grep -v "^end" | tr "\n" "d")
	SUBJ="
C=NO
ST=Norway
O=Oslo
localityName=Oslo
commonName=$DOMAIN
organizationalUnitName=
emailAddress=ragnar@raghon.no
"
	openssl genrsa -des3 -out /etc/httpd/ssl/server.key -passout env:PASSPHRASE 2048
	openssl req -new -batch -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key $KEY -out /tmp/$DOMAIN.csr -passin env:PASSPHRASE 
	cp $KEY $KEY.orig
	openssl rsa -in $KEY.orig -out $KEY -passin env:PASSPHRASE
	openssl x509 -req -days 365 -in /tmp/$DOMAIN.csr -signkey $KEY -out /etc/httpd/ssl/server.crt
fi

# fix permissions

chown apache:apache /var/www/html/owncloud/data

# Configure owncloud apps

console="php /var/www/html/owncloud/console.php"


/usr/bin/mysqld_safe &

sleep 10
# Configure owncloud
sudo -u apache php /var/www/html/owncloud/index.php
sudo -u apache php /var/www/html/owncloud/cron.php

mysql -h localhost -u owncloud -powncloudsql owncloud -e "update appconfig set configvalue = 'cron' where appid = 'core' and configkey='backgroundjobs_mode';"

$console app:disable calendar
$console app:disable gallery
$console app:disable contacts
$console app:disable firstrunwizard

$console app:enable files_encryption
$console app:enable files_external


/usr/sbin/apachectl -D FOREGROUND
