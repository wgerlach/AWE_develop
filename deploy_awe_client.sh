#!/bin/bash




export SERVERURL=http://10.1.12.14:8001

export DOCKERBIN=docker
#export DOCKERBIN=docker.io



set -x



if [ $1a == "nodockera" ]
then
	echo no docker
	killall -s TERM awe-client

else

	sudo start $DOCKERBIN ; echo starting $DOCKERBIN

	sleep 5

	if ! [ -f awe.tgz ]; then
	  curl http://shock.metagenomics.anl.gov/node/a8560eb3-d1e7-4fc7-b01e-c7c8a2a544e0?download > awe.tgz
	fi
	sudo docker load -i awe.tgz

	sudo docker rm -f awe-worker ; echo removing old container

fi

set -e

sudo rm -rf /mnt/data/awe/logs
sudo rm -rf /mnt/data/awe/work/*
mkdir -p /mnt/data/awe/logs
mkdir -p /home/ubuntu/awe-config


cd /home/ubuntu/awe-config
rm -f awe-client.cfg ; wget https://raw.githubusercontent.com/wgerlach/AWE_develop/master/awe-client.cfg

if [ $1a == "nodockera" ]
then

	nohup /home/gopath/bin/awe-client -debug 2 \
		-server_url=${SERVERURL} \
		-client_group=nodocker \
		-conf /awe-config/awe-client.cfg \
		-cgroup_memory_docker_dir=/cgroup_memory_docker/ \
		2> /mnt/data/awe/logs/stderr.log 1> /mnt/data/awe/logs/stdout.log &

else

	sudo $DOCKERBIN run -d -t -i --name awe-worker \
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
		rm -rf AWE golib go-dockerclient && \
		git clone https://github.com/wgerlach/AWE.git && \
		git clone https://github.com/MG-RAST/golib.git && \
		git clone https://github.com/MG-RAST/go-dockerclient.git && \
		cd && \
		go install -v github.com/MG-RAST/AWE/... && \
		/home/gopath/bin/awe-client -debug 2 \
			 -server_url=${SERVERURL} \
			 -client_group=docker \
			 -conf /awe-config/awe-client.cfg \
			 -cgroup_memory_docker_dir=/cgroup_memory_docker/ \
			 2> /mnt/data/awe/logs/stderr.log 1> /mnt/data/awe/logs/stdout.log"

fi
