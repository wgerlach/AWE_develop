#!/bin/bash




export DEFAULT_SERVERURL=http://10.1.12.14:8001

export DOCKERBIN=docker
#export DOCKERBIN=docker.io
#export AWE_BINARY="awe-client-20140926-dd4147757b"
#export AWE_BINARY="awe-client-20141006-51dd4c1"
export AWE_BINARY="awe-client-20141114-87bf44f"


export AWE_COMMIT_NUMBER="87bf44f" # for docker

#export GIT_RESET="cd AWE; git reset --hard ${AWE_COMMIT_NUMBER} ; cd .. ;"
#export GIT_RESET=""

# usage: deploy_awe_client.sh command clientgroup
# usage: deploy_awe_client.sh run|stop clientgroup

export COMMAND=$1
export CLIENTGROUP=$2

if [ "$#" -ne 2 ]; then
echo "Illegal number of parameters"
fi


#if [ ${CLIENTGROUP}a == "a" ]
#then
#CLIENTGROUP="docker"
#fi



set -x

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
	echo "Not running as root"
	exit
fi

if [[ ${SERVERURL}x == "x" ]]
then
export SERVERURL=${DEFAULT_SERVERURL}
fi


if [[ ${AWEBRANCH}x == "x" ]]
then
export AWEBRANCH="develop"
fi

if [[ ${AWEREPO}x == "x" ]]
then
export AWEREPO="wgerlach"
fi


if [[ ${COMMAND} == "stop" ]]
then
	killall -s TERM awe-client
	killall -s TERM ${AWE_BINARY}
	docker rm -f awe-worker ; echo removing old container
	exit 0
fi

if [[ ${COMMAND} != "run" ]]
then
	echo command ${COMMAND} unknown
	exit 1
fi


if [[ ${CLIENTGROUP} == "nodocker" ]]
then
	echo no docker
	killall -s TERM awe-client
	killall -s TERM ${AWE_BINARY}

	if ! [ -f /home/ubuntu/${AWE_BINARY} ]; then
		cd /home/ubuntu/
		curl http://dunkirk.mcs.anl.gov/~wgerlach/${AWE_BINARY} > awe.tmp
		chmod +x awe.tmp
		mv awe.tmp ${AWE_BINARY}
	fi

else

	start $DOCKERBIN ; echo starting $DOCKERBIN

	sleep 5

	if ! [ -f awe.tgz ]; then
	  curl "http://shock.metagenomics.anl.gov/node/87f3ce92-4f4d-452b-ba57-9e9fc95eb002?download" > awe.tgz
	fi
	docker load -i awe.tgz
	docker tag d0187a49bc33 skyport/awe:20141020
	docker rm -f awe-worker ; echo removing old container

fi

set -e

rm -rf /mnt/data/awe/logs
rm -rf /mnt/data/awe/work/*
mkdir -p /mnt/data/awe/logs
#mkdir -p /home/ubuntu/awe-config


#cd /home/ubuntu/awe-config
#rm -f awe-client.cfg ; wget https://raw.githubusercontent.com/wgerlach/AWE_develop/master/awe-client.cfg

if [[ ${CLIENTGROUP} == "nodocker" ]]
then

export PATH=/root/bin:/root/pipeline/awecmd:/root/pipeline/bin:$PATH
export PERL5LIB=/root/pipeline/lib:/root/pipeline/conf:$PERL5LIB
export PATH=/root/FragGeneScan/bin:$PATH

nohup /home/ubuntu/${AWE_BINARY} \
 --debuglevel=2 \
 --serverurl=${SERVERURL} \
 --group=nodocker \
 --supported_apps=\* \
 --auto_clean_dir=false \
2> /mnt/data/awe/logs/stderr.log 1> /mnt/data/awe/logs/stdout.log &

else



$DOCKERBIN run -d -t -i --name awe-worker \
 -v /usr/bin/docker:/usr/bin/docker \
 -v /var/run/docker.sock:/var/run/docker.sock \
 -v /sys/fs/cgroup/memory/docker/:/cgroup_memory_docker/ \
 -v /mnt/data/awe/:/mnt/data/awe/ \
 --env="SERVERURL=$SERVERURL" \
 --env="CLIENTGROUP=$CLIENTGROUP" \
 --env="AWEBRANCH=$AWEBRANCH" \
 --env="AWEREPO=$AWEREPO" \
skyport/awe:20141020 \
bash -c "\
# cleanup
mkdir -p /awe/logs/ && \
rm -rf /mnt/data/awe/logs/* && \
rm -f /gopath/bin/awe-client && \
cd /gopath/src/github.com/MG-RAST/ && \
rm -rf AWE golib go-dockerclient && \
# get source code
git clone https://github.com/${AWEREPO}/AWE.git -b $AWEBRANCH && \
ls ; ${GIT_RESET} \ 
git clone https://github.com/MG-RAST/golib.git && \
git clone https://github.com/MG-RAST/go-dockerclient.git && \
cd && \
# compile
go install -v github.com/MG-RAST/AWE/... && \
# start AWE worker
/gopath/bin/awe-client \
 --debuglevel=2 \
 --serverurl=${SERVERURL} \
 --group=${CLIENTGROUP} \
 --supported_apps=\* \
 --auto_clean_dir=false \
 2> /mnt/data/awe/logs/stderr.log 1> /mnt/data/awe/logs/stdout.log"

fi
