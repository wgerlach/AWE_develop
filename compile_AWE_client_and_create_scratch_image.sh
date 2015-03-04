#!/bin/sh

# This script compiles AWE (statically) and creates a docker scratch image
#
# Execution environment for this script is a default AWE worker (client) container, e.g.:
# > docker build -t skyport/awe-factory:latest https://raw.githubusercontent.com/MG-RAST/Skyport/master/dockerfiles/awe-client/Dockerfile
#
# This container needs to be started with
# "-v /usr/bin/docker:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock"
# to allow this script to build a scratch AWE worker docker image:
# docker run -t -i --name awe-factory skyport/awe-factory:latest ...
#
# wget is required for scratch Dockerfile and nano may be need to change git repo url in here. 
# apt-get install -y wget nano

set -x
set -e


REPODIR=/gopath/src/github.com/MG-RAST/
cd ${REPODIR}

#rm -rf AWE golib go-dockerclient
#git clone https://github.com/MG-RAST/AWE.git -b master
#git clone https://github.com/MG-RAST/golib.git
#git clone https://github.com/MG-RAST/go-dockerclient.git




export GITHASH=$(git -C AWE rev-parse HEAD)
echo GITHASH=${GITHASH}

#staticallly linked, # this would remove debug symbols : -ldflags '-s'
CGO_ENABLED=0 go install -a -v -ldflags "-X github.com/MG-RAST/AWE/lib/conf.GIT_COMMIT_HASH ${GITHASH}" github.com/MG-RAST/AWE/...

# nomal version: go install -v github.com/MG-RAST/AWE/...



# this creates the scratch Dockerfiles

# awe-client
mkdir -p /scratch/awe-client/ 
if [ ! -f /scratch/awe-client/Dockerfile ]; then
cat << 'EOF' > /scratch/awe-client/Dockerfile 
# scratch awe client
FROM scratch
ADD ./awe-client /usr/local/bin/awe-client
CMD ["/usr/local/bin/awe-client"]
EOF
fi

# awe-server
mkdir -p /scratch/awe-server/ 
if [ ! -f /scratch/awe-server/Dockerfile ]; then
cat << 'EOF' > /scratch/awe-server/Dockerfile 
# scratch awe server (mongodb is seperate)
FROM scratch
ADD ./awe-server /usr/local/bin/awe-server
ADD ./site.tar /src/github.com/MG-RAST/AWE/site/
CMD ["/usr/local/bin/awe-server"]
EOF
fi


# copy binary into scratch build context
rm -f /scratch/awe-client/awe-client /scratch/awe-server/awe-server /scratch/awe-server/site.tar
cp /gopath/bin/awe-client /scratch/awe-client/
cp /gopath/bin/awe-server /scratch/awe-server/
tar -cf /scratch/awe-server/site.tar -C ${REPODIR}/AWE/site/ .



DATE=`date +"%Y%m%d.%H%M"`

docker rmi skyport/awe-client:latest skyport/awe-server:latest || true

docker build -t skyport/awe-client-minimal:${DATE} /scratch/awe-client/
docker build -t skyport/awe-server-minimal:${DATE} /scratch/awe-server/



cd ${REPODIR}