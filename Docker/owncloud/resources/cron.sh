#!/bin/bash
#

docks=$(docker ps -f status=running | awk '$1~/[0-9]./ && $2~/owncloud/ {print $1}')

for d in $docks ; do
	docker exec $d php -f /var/www/html/owncloud/cron.php
done
