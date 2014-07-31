# Quick Start


## Installation

Build the gitlab image.

```bash
git clone https://github.com/jasonbrooks/docker-gitlab.git
cd docker-gitlab
docker build --tag="$USER/gitlab" .
cd ..
```

Build a postgresql image.

```bash
git clone https://github.com/fedora-cloud/Fedora-Dockerfiles.git
cd Fedora-Dockerfiles/postgres
docker build --tag="$USER/postgres" .
cd ../..
```

Build a redis image.

```bash
cd Fedora-Dockerfiles/redis
docker build --tag="$USER/redis" .
cd ../..
```

## Startup

Start the redis container

```bash
docker run --name=redis -d $USER/redis
```

Configure and start postgres.

```bash
mkdir -p /opt/postgresql/data
docker run --name=postgresql -d \
  -v /opt/postgresql/data:/var/lib/postgresql \
  $USER/postgres
```

You should now have the postgresql server running. The password for the postgres user can be found in the "postgres_user.sh" script that accompanies the postgres Dockerfile.

Now, let's log in to the postgresql server and create a user and database for the GitLab application.

```bash
POSTGRESQL_IP=$(docker inspect postgresql | grep IPAddres | awk -F'"' '{print $4}')
psql dockerdb -U dockeruser -h ${POSTGRESQL_IP}
```

```sql
CREATE ROLE gitlab with LOGIN CREATEDB PASSWORD 'password';
CREATE DATABASE gitlabhq_production;
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production to gitlab;
```

Now that we have the database created for gitlab, let's install the database schema. This is done by starting the gitlab container with the **app:rake gitlab:setup** command.

```bash
docker run --name=gitlab -it --rm \
  --link postgresql:postgresql \
  --link redis:redisio
  -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -e 'DB_NAME=gitlabhq_production' \
  -v /opt/gitlab/data:/home/git/data \
  $USER/gitlab app:rake gitlab:setup
```

**NOTE: The above database setup is performed only for the first run**.

Run the gitlab image

```bash
mkdir /opt/gitlab/data
docker run --name=gitlab -it --rm \
  --link redis:redisio --link postgresql:postgresql \
  -p 10022:22 -p 10080:80 \
  -e 'GITLAB_PORT=10080' -e 'GITLAB_SSH_PORT=10022' \
  -e 'DB_USER=gitlab' -e 'DB_PASS=password' \
  -e 'DB_NAME=gitlabhq_production' \
  -v /opt/gitlab/data:/home/git/data \
  $USER/gitlab
```

__NOTE__: Please allow a couple of minutes for the GitLab application to start.

Point your browser to `http://localhost:10080` and login using the default username and password:

* username: root
* password: 5iveL!fe

You should now have the GitLab application up and ready for testing. If you want to use this image in production the please read on.

