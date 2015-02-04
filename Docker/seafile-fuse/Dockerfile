FROM centos:7
MAINTAINER ragnar.hongset@raghon.no

# Adds required packages
RUN yum --releasever=7 -y install git fuse && \
	yum clean all --releasever=7

# Install Cloudfuse
RUN yum --releasever=7 -y install gcc make fuse-devel curl-devel \
	libxml2-devel openssl-devel && \
	yum clean all --releasever=7
RUN cd /usr/local && git clone https://github.com/redbo/cloudfuse.git
RUN cd /usr/local/cloudfuse && git checkout 21358f159d13c6196cee17652fd3d415dfd984f3
RUN cd /usr/local/cloudfuse && ./configure && make && make install
RUN yum --releasever=7 -y remove \*-devel && \
	yum clean all --releasever=7
RUN mkdir /var/cloudfuse

ADD assets/ /root/config/

# Install seafile requirements
RUN yum --releasever=7 -y install epel-release
RUN yum --releasever=7 -y install nginx python-imaging MySQL-python python-simplejson python-setuptools sendmail tar

ENV SERVER_NAME example
ENV SERVER_ADDR seafile.example.com
ENV ADMIN_EMAIL admin@example.com
ENV ADMIN_PASSWORD changeme!

RUN mkdir /opt/seafile
WORKDIR /opt/seafile
RUN curl -L -O https://bitbucket.org/haiwen/seafile/downloads/seafile-server_4.0.5_x86-64.tar.gz
RUN tar xzf seafile-server_*
RUN mkdir installed
RUN mv seafile-server_* installed

# Install DnsMasq service.
RUN mkdir -p /etc/service/dnsmasq
ADD service-dnsmasq.sh /etc/service/dnsmasq/run

# Install Seafile service.
RUN mkdir /etc/service/seafile
ADD service-seafile-run.sh /etc/service/seafile/run
ADD service-seafile-stop.sh /etc/service/seafile/stop

# Install Seahub service.
RUN mkdir /etc/service/seahub
ADD service-seahub-run.sh /etc/service/seahub/run
ADD service-seahub-stop.sh /etc/service/seahub/stop

# Install Nginx.
RUN mkdir /etc/service/nginx
ADD service-nginx.sh /etc/service/nginx/run
ADD seafile-nginx.conf /etc/nginx/sites-available/seafile

# Expose needed ports.
EXPOSE 10001 12001 8000 8082

RUN mkdir /opt/seafile/logs

VOLUME /etc
VOLUME /opt/seafile
VOLUME /etc/service/seafile
VOLUME /etc/service/seahub

ADD bootstrap-data.sh /usr/local/sbin/bootstrap
CMD /sbin/my_init
EXPOSE 22
