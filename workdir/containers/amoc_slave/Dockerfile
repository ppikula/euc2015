FROM centos:7
MAINTAINER examples@docker.com

RUN yum install -y epel-release
RUN yum install -y supervisor openssh-server
RUN echo 'root:root' |chpasswd && sshd-keygen

COPY supervisor.conf /etc/supervisor/supervisord.conf
COPY run.sh /opt/run.sh

EXPOSE 22

CMD ["/opt/run.sh"]
