#!/bin/sh

# This script compiles AWE (statically) and creates a docker scratch image
#
# Execution environment for this script is a default AWE worker (client) container, e.g.:
# > docker build -t skyport/awe-client:latest https://raw.githubusercontent.com/MG-RAST/Skyport/master/dockerfiles/awe-client/Dockerfile
#
# This container needs to be started with
# "-v /usr/bin/docker:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock"
# to allow this script to build a scratch AWE worker docker image.
#
# wget is required for scratch Dockerfile and nano may be need to change git repo url in here. 
# apt-get install -y wget nano


set -x
set -e

REPODIR=/gopath/src/github.com/MG-RAST/

cd ${REPODIR}
rm -rf AWE golib go-dockerclient

git clone https://github.com/MG-RAST/AWE.git -b master
#ls ; ${GIT_RESET}
git clone https://github.com/MG-RAST/golib.git
git clone https://github.com/MG-RAST/go-dockerclient.git

#staticallly linked, # this would remove debug symbols : -ldflags '-s'
CGO_ENABLED=0 go install -a -v github.com/MG-RAST/AWE/...

# nomal version: go install -v github.com/MG-RAST/AWE/...


mkdir -p /scratch 
cd /scratch

if [ ! -f Dockerfile ]; then
    wget https://raw.githubusercontent.com/wgerlach/AWE_develop/master/scratch-awe-client/Dockerfile
fi

rm -f awe-client
cp /gopath/bin/awe-client .


docker rmi skyport/awe-client:latest || true

docker build -t skyport/awe-client:latest /scratch/

echo Image ID: $(sudo docker inspect -f '{{ .Id}}' skyport/awe-client)

cd ${REPODIR}