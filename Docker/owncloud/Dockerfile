FROM centos:7
MAINTAINER Ragnar Hongset "ragnar@raghon.no"
RUN yum install -y httpd php php-mysql mariadb-server mariadb sqlite php-dom php-mbstring php-gd php-pdo wget hostname sharutils openssl mod_ssl
RUN wget http://download.opensuse.org/repositories/isv:ownCloud:community/CentOS_CentOS-7/isv:ownCloud:community.repo -O /etc/yum.repos.d/ownCloud.repo
RUN yum install -y owncloud

# For later add nginx
#RUN rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
#RUN yum install -y nginx


#RUN apt-get install -y apache2 php5 php5-gd php-xml-parser php5-intl php5-sqlite mysql-server-5.5 smbclient curl libcurl3 php5-mysql php5-curl bzip2 wget vim openssl ssl-cert sharutils

RUN mkdir /etc/httpd/ssl

RUN chown -R mysql:mysql /var/lib/mysql

ADD resources/cfgmysql.sh /tmp/
RUN chmod +x /tmp/cfgmysql.sh
RUN /tmp/cfgmysql.sh
RUN rm /tmp/cfgmysql.sh

#ADD resources/001-owncloud.conf /etc/httpd/conf.d/
ADD resources/start.sh /
ADD resources/autoconfig.php /var/www/html/owncloud/config/autoconfig.php

RUN chmod +x /start.sh

EXPOSE	80 443

CMD ["/start.sh"]
