#!/bin/bash

set -x
set -e



rm -rf /mnt/data/awe/logs/*

sudo docker run -d -t -i --name awe-worker \
 -v /usr/bin/docker:/usr/bin/docker \
 -v /var/run/docker.sock:/var/run/docker.sock \
# -v /sys/fs/cgroup/memory/docker/:/cgroup_memory_docker/ \
 -v /mnt/data/awe/:/mnt/data/awe/ \
 --env="SERVERURL=$SERVERURL" \
 --env="CLIENTGROUP=$CLIENTGROUP" \
skyport/awe:latest \
/gopath/bin/awe-client \
 --debuglevel=2 \
 --serverurl=${SERVERURL} \
 --group=${CLIENTGROUP} \
 --supported_apps=\* \
 --auto_clean_dir=false



# 2> /mnt/data/awe/logs/stderr.log 1> /mnt/data/awe/logs/stdout.log"


