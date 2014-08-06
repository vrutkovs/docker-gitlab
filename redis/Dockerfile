FROM fedora:20
MAINTAINER Aditya Patawari <adimania@fedoraproject.org>

RUN yum -y update
RUN yum -y install redis iptables

EXPOSE 6379

CMD [ "redis-server" ]

