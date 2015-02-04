=================
Installer seafile
=================

Registrer i dns
---------------

Finn ny ip, og registrer den på domeneshop.no
ps : legg inn IN A eller CNAME

Hent div skript fra eget GIT repo
---------------------------------

yum install git vim
cd
mkdir GIT
cd GIT
git clone git@github.com:raghon1/config.git

Sett opp ObjectStorage
======================

Sett opp cloudfuse ::

        yum install fuse gcc make fuse-devel curl-devel libxml2-devel openssl-devel
        cd ~/GIT
        git clone https://github.com/redbo/cloudfuse.git
        cd cloudfuse
        ./configure
        make 
        make install

Autoload fuse kernelmodule at boot::

        echo fuse > /etc/modules-load.d/cloudfuse.conf

Make startup script for seafile and cloudfuse
---------------------------------------------
mkdir -p /opt/cloudwalker/bin

Lag ett skript::

        cat << !! > /opt/cloudwalker/bin
        #!/bin/bash
        #

        username=<USERNAME>
        api_key=<APIKEY>
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
        !!

chmod 500 /opt/cloudwalker/bin/seafile.sh
        

Lag nytt SSL cert
=================

su - root
cd GIT/config/scripts/ssl
generate.sh -s seafile.cloudwalker.no

Install database
================

Install docker::
        
        yum intall docker
        systemctl enable docker
        systemctl start docker

Install mysql docker::

        docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=<password> --name seafile-db orchardup/mysql
        docker stop seafile-db
        docker start seafile-db

Install SeaFile
===============

cd /tmp
wget https://bitbucket.org/haiwen/seafile/downloads/seafile-server_4.0.5_x86-64.tar.gz
mkdir /opt/seafile
cd /opt/seafile
tar zxf /tmp/seafile-server_4.0.5_x86-64.tar.gz
cd seafile-server*

yum install python-imaging MySQL-python python-simplejson python-setuptools
yum install sendmail 

Install MySQL client::
        
        yum install mariadb

Configure my.cnf for mysql root password::

        Create a file $HOME/.my.cnf and paste in the following. PS replace password

        [client]
        user="root"
        pass="<password>"

        chmod 400 $HOME/.my.cnf

Precreate som databases::

        mysql -P3306 -h 127.0.01 -e "create database \`ccnet-db\`;create database \`seafile-db\`; create database \`seahub-db\`;" 
        mysql -P3306 -h 127.0.01 -e "create user 'seafile'@'%' identified by 'password';"

        mysql -P3306 -h 127.0.01 -e "GRANT ALL PRIVILEGES ON \`ccnet-db\`.* to \`seafile\`@\`%\`;"
        mysql -P3306 -h 127.0.01 -e "GRANT ALL PRIVILEGES ON \`seafile-db\`.* to \`seafile\`@\`%\`;"
        mysql -P3306 -h 127.0.01 -e "GRANT ALL PRIVILEGES ON \`seahub-db\`.* to \`seafile\`@\`%\`;"

        mysql -P3306 -h 127.0.01 -e "drop database \`ccnet-db\`;drop database \`seafile-db\`; drop database \`seahub-db\` "


Seafile config
==============

cd /opt/seafile/seafile-server-4.0.5
./setup-seafile-mysql.sh

PS use seafile as user, and connect to created databases.

Install nginx
=============

Get from EPEL repo::

        yum install epel-release
        yum install nginx
        
Add config for seafile server
-----------------------------

cat << !! > /etc/nging/conf.d/seafile.conf
server {
        listen       80;
        server_name  seafile.cloudwalker.no;
        rewrite ^ https://$http_host$request_uri? permanent;    # force redirect http to https
    }
    server {
        listen 443;
        ssl on;
        ssl_certificate /etc/nginx/certs/seafile.crt;            # path to your cacert.pem
        ssl_certificate_key /etc/nginx/certs/seafile.key;    # path to your privkey.pem
        server_name seafile.cloudwalker.no;
        location / {
            fastcgi_pass    127.0.0.1:8000;
            fastcgi_param   SCRIPT_FILENAME     $document_root$fastcgi_script_name;
            fastcgi_param   PATH_INFO           $fastcgi_script_name;

            fastcgi_param   SERVER_PROTOCOL    $server_protocol;
            fastcgi_param   QUERY_STRING        $query_string;
            fastcgi_param   REQUEST_METHOD      $request_method;
            fastcgi_param   CONTENT_TYPE        $content_type;
            fastcgi_param   CONTENT_LENGTH      $content_length;
            fastcgi_param   SERVER_ADDR         $server_addr;
            fastcgi_param   SERVER_PORT         $server_port;
            fastcgi_param   SERVER_NAME         $server_name;
            fastcgi_param   HTTPS               on;
            fastcgi_param   HTTP_SCHEME         https;

            access_log      /var/log/nginx/seafile.access.log;
            error_log       /var/log/nginx/seafile.error.log;
        }
        location /seafhttp {
            rewrite ^/seafhttp(.*)$ $1 break;
            proxy_pass http://127.0.0.1:8082;
            client_max_body_size 0;
            proxy_connect_timeout  36000s;
            proxy_read_timeout  36000s;
        }
        location /media {
            root /opt/seafile/seafile-server-latest/seahub;
        }
    }
!!


Add SSL certs to nginx::
        
        mkdir /etc/nginx/certs
        cp /var/tmp/ssl-generate/kunder/seafile.cloudwalker.no/seafile.cloudwalker.no.crt /etc/nginx/certs
        cp /var/tmp/ssl-generate/kunder/seafile.cloudwalker.no/seafile.cloudwalker.no.key /etc/nginx/certs


Endre Service Url for seafile
-----------------------------

editer /opt/seafile/ccnet/ccnet.conf, og endre service url til https://seafile.cloudwalker.no


Change TIMEZONE
===============

timedatectl set-timezone Europe/Oslo


Enable firewall
===============

Ip tables oppsett::

        yum -y install iptables-services
        iptables -P INPUT ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -j ACCEPT
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        iptables -A INPUT -p tcp --dport 10001 -j ACCEPT
        iptables -A INPUT -p tcp --dport 12001 -j ACCEPT
        iptables -P INPUT DROP
        iptables -P OUTPUT ACCEPT
         /sbin/service iptables save
