#!/bin/bash
set -e
set -x

curl http://shock.metagenomics.anl.gov/node/a8560eb3-d1e7-4fc7-b01e-c7c8a2a544e0?download > awe.tgz
sudo docker load -i awe.tgz
mkdir -p /mnt/data/awe/logs
mkdir ~/awe-config
cd ~/awe-config
wget https://raw.githubusercontent.com/wgerlach/AWE_develop/master/awe-client.cfg

sudo docker.io run -t -i --name awe-client \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /home/ubuntu/awe-config/:/awe-config/ \
-v /sys/fs/cgroup/memory/docker/:/cgroup_memory_docker/ \
-v /mnt/data/awe/:/mnt/data/awe/ \
awe:20140615 \
bash -c "\
mkdir -p /awe/logs/ && \
rm -f /awe/logs/* && \
rm -f /home/gopath/bin/awe-client && \
cd /home/gopath/src/github.com/MG-RAST/ && \
rm -rf AWE golib && \
git clone https://github.com/wgerlach/AWE.git && \
git clone https://github.com/MG-RAST/golib.git && \
cd /home/gopath/src/github.com/wgerlach/go-dockerclient && \
git pull && \
cd && \
go install -v github.com/MG-RAST/AWE/... && \
/home/gopath/bin/awe-client -debug 2 \
 -server_url=http://10.1.12.14:8001 \
 -conf /awe-config/awe-client.cfg \
 -cgroup_memory_docker_dir=/cgroup_memory_docker/"

