#!/bin/sh

set -eu

/opt/seafile/seafile-server-latest/seafile.sh stop
umount.s3ql /opt/seafile/seafile-data
