#!/bin/bash

# sort of a temp hack to make this work on docker pkg in centos7
# due to https://github.com/docker/docker/issues/6137

chmod 0700 /var/lib/pgsql/data

__run_supervisor() {
supervisord -n
}

# Call all functions
__run_supervisor

