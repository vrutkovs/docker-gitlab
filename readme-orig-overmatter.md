# Table of Contents
- [Introduction](#introduction)
    - [Version](#version)
    - [Changelog](Changelog.md)
- [Hardware Requirements](#hardware-requirements)
    - [CPU](#cpu)
    - [Memory](#memory)
    - [Storage](#storage)
- [Supported Web Browsers](#supported-web-browsers)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Data Store](#data-store)
    - [Database](#database)
        - [MySQL](#mysql)
            - [Internal MySQL Server](#internal-mysql-server)
            - [External MySQL Server](#external-mysql-server)
            - [Linking to MySQL Container](#linking-to-mysql-container)
        - [PostgreSQL (Recommended)](#postgresql)
            - [External PostgreSQL Server](#external-postgresql-server)
            - [Linking to PostgreSQL Container](#linking-to-postgresql-container)
    - [Redis](#redis)
      - [Internal Redis Server](#internal-redis-server)
      - [External Redis Server](#external-redis-server)
      - [Linking to Redis Container](#linking-to-redis-container)
    - [Mail](#mail)
    - [SSL](#ssl)
      - [Generation of Self Signed Certificates](#generation-of-self-signed-certificates)
      - [Strengthening the server security](#strengthening-the-server-security)
      - [Installation of the Certificates](#installation-of-the-certificates)
      - [Enabling HTTPS support](#enabling-https-support)
      - [Using HTTPS with a load balancer](#using-https-with-a-load-balancer)
      - [Establishing trust with your server](#establishing-trust-with-your-server)
      - [Installing Trusted SSL Server Certificates](#installing-trusted-ssl-server-certificates)
    - [Putting it all together](#putting-it-all-together)
    - [Run under sub URI](#run-under-sub-uri)
    - [Available Configuration Parameters](#available-configuration-parameters)
- [Maintenance](#maintenance)
    - [Creating Backups](#creating-backups)
    - [Restoring Backups](#restoring-backups)
    - [Automated Backups](#automated-backups)
- [Upgrading](#upgrading)
- [Rake Tasks](#rake-tasks)
- Links
  - [Announcements](https://github.com/sameersbn/docker-gitlab/issues/39)
  - [Issues](https://github.com/sameersbn/docker-gitlab/issues)
- [References](#references)

# Introduction
Dockerfile to build a GitLab container image.

## Version
Current Version: 7.1.0


***



**much to edit below**

# Configuration

## Data Store
GitLab is a code hosting software and as such you don't want to lose your code when the docker container is stopped/deleted. To avoid losing any data, you should mount a volume at,

* /home/git/data

Volumes can be mounted in docker by specifying the **'-v'** option in the docker run command.

```bash
mkdir /opt/gitlab/data
docker run --name=gitlab -d \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0
```

## Database
GitLab uses a database backend to store its data.

### MySQL

> **Note**
>
> Gitlab requires a database (postgres or mysql) and a redis server. Neither of these are provided with the gitlab image, so you'll need to run a database and redis in linked containers or through some other external means.

> Use a linked [mysql](#linking-to-mysql-container) or
> [postgresql](#linking-to-postgresql-container) container.
> Or else connect with an external [mysql](#external-mysql-server) or
> [postgresql](#external-postgresql-server) server.


#### External MySQL Server
The image can be configured to use an external MySQL database instead of starting a MySQL server internally. The database configuration should be specified using environment variables while starting the GitLab image.

Before you start the GitLab image create user and database for gitlab.

```sql
CREATE USER 'gitlab'@'%.%.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'%.%.%.%';
```

To make sure the database is initialized start the container with **app:rake gitlab:setup** option.

*Assuming that the mysql server host is 192.168.1.100*

```bash
docker run --name=gitlab -it --rm \
  -e 'DB_HOST=192.168.1.100' -e 'DB_NAME=gitlabhq_production' -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0 app:rake gitlab:setup
```

Append `force=yes` to the above command to skip the confirmation prompt.

**NOTE: The above setup is performed only for the first run**.

This will initialize the gitlab database. Now that the database is initialized, start the container normally.

```bash
docker run --name=gitlab -d \
  -e 'DB_HOST=192.168.1.100' -e 'DB_NAME=gitlabhq_production' -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0
```

#### Linking to MySQL Container
You can link this image with a mysql container for the database requirements. The alias of the mysql server container should be set to **mysql** while linking with the gitlab image.

If a mysql container is linked, only the DB_HOST and DB_PORT settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the DB_NAME, DB_USER, DB_PASS and so on.

To illustrate linking with a mysql container, we will use the [sameersbn/mysql](https://github.com/sameersbn/docker-mysql) image. When using docker-mysql in production you should mount a volume for the mysql data store. Please refer the [README](https://github.com/sameersbn/docker-mysql/blob/master/README.md) of docker-mysql for details.

First, lets pull the mysql image from the docker index.

```bash
docker pull sameersbn/mysql:latest
```

For data persistence lets create a store for the mysql and start the container.

```bash
mkdir -p /opt/mysql/data
docker run --name=mysql -d \
	-v /opt/mysql/data:/var/lib/mysql \
	sameersbn/mysql:latest
```

You should now have the mysql server running. By default the sameersbn/mysql image does not assign a password for the root user and allows remote connections for the root user from the 172.17.%.% address space. This means you can login to the mysql server from the host as the root user.

Now, lets login to the mysql server and create a user and database for the GitLab application.

```bash
mysql -uroot -h $(docker inspect mysql | grep IPAddres | awk -F'"' '{print $4}')
```

```sql
CREATE USER 'gitlab'@'172.17.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'172.17.%.%';
FLUSH PRIVILEGES;
```

Now that we have the database created for gitlab, lets install the database schema. This is done by starting the gitlab container with the **app:rake gitlab:setup** command.

```bash
docker run --name=gitlab -it --rm --link mysql:mysql \
  -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -e 'DB_NAME=gitlabhq_production' \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0 app:rake gitlab:setup
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the GitLab application.

```bash
docker run --name=gitlab -d --link mysql:mysql \
  -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -e 'DB_NAME=gitlabhq_production' \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0
```

### PostgreSQL

#### External PostgreSQL Server
The image also supports using an external PostgreSQL Server. This is also controlled via environment variables.

```sql
CREATE ROLE gitlab with LOGIN CREATEDB PASSWORD 'password';
CREATE DATABASE gitlabhq_production;
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production to gitlab;
```

To make sure the database is initialized start the container with **app:rake gitlab:setup** option.

*Assuming that the PostgreSQL server host is 192.168.1.100*

```bash
docker run --name=gitlab -it --rm \
  -e 'DB_TYPE=postgres' -e 'DB_HOST=192.168.1.100' -e 'DB_NAME=gitlabhq_production' -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0 app:rake gitlab:setup
```

**NOTE: The above setup is performed only for the first run**.

This will initialize the gitlab database. Now that the database is initialized, start the container normally.

```bash
docker run --name=gitlab -d \
  -e 'DB_TYPE=postgres' -e 'DB_HOST=192.168.1.100' -e 'DB_NAME=gitlabhq_production' -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0
```

#### Linking to PostgreSQL Container
You can link this image with a postgresql container for the database requirements. The alias of the postgresql server container should be set to **postgresql** while linking with the gitlab image.

If a postgresql container is linked, only the DB_HOST and DB_PORT settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the DB_NAME, DB_USER, DB_PASS and so on.

To illustrate linking with a postgresql container, we will use the [sameersbn/postgresql](https://github.com/sameersbn/docker-postgresql) image. When using postgresql image in production you should mount a volume for the postgresql data store. Please refer the [README](https://github.com/sameersbn/docker-postgresql/blob/master/README.md) of docker-postgresql for details.

First, lets pull the postgresql image from the docker index.

```bash
docker pull sameersbn/postgresql:latest
```

For data persistence lets create a store for the postgresql and start the container.


We are now ready to start the GitLab application.

```bash
docker run --name=gitlab -d --link postgresql:postgresql \
  -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -e 'DB_NAME=gitlabhq_production' \
  -v /opt/gitlab/data:/home/git/data \
  sameersbn/gitlab:7.1.0
```

## Redis


GitLab uses the redis server for its key-value data store. The redis server connection details can be specified using environment variables. If not specified, the  starts a redis server internally, no additional configuration is required.

### External Redis Server
The image can be configured to use an external redis server instead of starting a redis server internally. The configuration should be specified using environment variables while starting the GitLab image.

*Assuming that the redis server host is 192.168.1.100*

```bash
docker run --name=gitlab -it --rm \
  -e 'REDIS_HOST=192.168.1.100' -e 'REDIS_PORT=6379' \
  sameersbn/gitlab:7.1.0
```
### Linking to Redis Container
You can link this image with a redis container to satisfy gitlab's redis requirement. The alias of the redis server container should be set to **redisio** while linking with the gitlab image.

To illustrate linking with a redis container, we will use the [sameersbn/redis](https://github.com/sameersbn/docker-redis) image. Please refer the [README](https://github.com/sameersbn/docker-redis/blob/master/README.md) of docker-redis for details.

First, lets pull the redis image from the docker index.

```bash
docker pull sameersbn/redis:latest
```

Lets start the redis container

```bash
docker run --name=redis -d sameersbn/redis:latest
```

We are now ready to start the GitLab application.

```bash
docker run --name=gitlab -d --link redis:redisio \
  sameersbn/gitlab:7.1.0
```


### Putting it all together

```bash
docker run --name=gitlab -d -h git.local.host \
  -v /opt/gitlab/data:/home/git/data \
  -v /opt/gitlab/mysql:/var/lib/mysql \
  -e 'GITLAB_HOST=git.local.host' -e 'GITLAB_EMAIL=gitlab@local.host' \
  -e 'SMTP_USER=USER@gmail.com' -e 'SMTP_PASS=PASSWORD' \
  sameersbn/gitlab:7.1.0
```

If you are using an external mysql database

```bash
docker run --name=gitlab -d -h git.local.host \
  -v /opt/gitlab/data:/home/git/data \
  -e 'DB_HOST=192.168.1.100' -e 'DB_NAME=gitlabhq_production' -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -e 'GITLAB_HOST=git.local.host' -e 'GITLAB_EMAIL=gitlab@local.host' \
  -e 'SMTP_USER=USER@gmail.com' -e 'SMTP_PASS=PASSWORD' \
  sameersbn/gitlab:7.1.0
```


