FROM fedora:20
MAINTAINER jbrooks@redhat.com

RUN yum update -y; yum clean all
RUN yum install -y gcc-c++ glibc-headers openssl-devel readline libyaml-devel \
    zlib-devel gdbm-devel readline-devel ncurses-devel libffi-devel curl git \
    openssh-server redis libxml2-devel libxslt-devel libcurl-devel libicu-devel \
    python postgresql nginx mariadb-server python python-docutils \
    mariadb-devel postgresql-devel ruby ruby-devel && \
    gem install --no-ri --no-rdoc bundler && \
    yum clean all

ADD assets/setup/ /app/setup/
RUN chmod 755 /app/setup/install
RUN /app/setup/install

ADD assets/config/ /app/setup/config/
ADD assets/init /app/init
RUN chmod 755 /app/init

EXPOSE 22
EXPOSE 80
EXPOSE 443

VOLUME ["/home/git/data"]

ENTRYPOINT ["/app/init"]
CMD ["app:start"]
