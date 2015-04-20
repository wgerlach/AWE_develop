#!/bin/sh

# This script compiles AWE (statically) and creates a docker scratch image
#


set -x
set -e


REPODIR=/gopath/src/github.com/MG-RAST/
cd ${REPODIR}

#rm -rf AWE golib go-dockerclient
#git clone --recursive https://github.com/MG-RAST/AWE.git -b master
###git submodule update --init --recursive
#git clone https://github.com/MG-RAST/golib.git
#git clone https://github.com/MG-RAST/go-dockerclient.git

if [ ! "$(ls -A ${REPODIR}/AWE/site/Retina)" ] ; then
	echo "Please check out Retina submodule"
	exit 1
fi


rm -f /gopath/bin/awe-client
rm -f /gopath/bin/awe-server


export GITHASH=$(git -C AWE rev-parse HEAD)
echo GITHASH=${GITHASH}

#staticallly linked, # this would remove debug symbols : -ldflags '-s'
CGO_ENABLED=0 go install -a -installsuffix cgo -v -ldflags "-X github.com/MG-RAST/AWE/lib/conf.GIT_COMMIT_HASH ${GITHASH}" github.com/MG-RAST/AWE/...

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