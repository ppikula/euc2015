FROM centos:7
MAINTAINER pawel.pikula@erlang-solutions.com

WORKDIR /root/

RUN yum install -y epel-release wget \
    && wget http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm \
    && rpm -Uvh erlang-solutions-1.0-1.noarch.rpm \
    && yum install -y supervisor openssh-server erlang-base erlang-dev libselinux-python \
                      tar gzip unzip \
                      erlang-nox erlang-dialyzer erlang-reltool erlang-test_server \
                      erlang-xmerl erlang-edoc erlang-snmp erlang-eunit git net-tools htop\
                      make expat-devel ansible erlang-erl_interface hostname gcc sshpass vim\
    && echo 'root:root' | chpasswd && sshd-keygen \
    && echo -e "\n\n\n" | ssh-keygen -N "" -t rsa

RUN git clone https://github.com/esl/amoc.git -b euc2015 && cd amoc && ./rebar get-deps

COPY supervisor.conf /etc/supervisor/supervisord.conf
COPY run.sh /opt/run.sh

EXPOSE 22


CMD ["/opt/run.sh"]
