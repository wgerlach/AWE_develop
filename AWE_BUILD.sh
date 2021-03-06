#!/bin/sh

set -x

#deploy AWE:
# sudo ./deploy_software.pl --root --new --target /home/ubuntu/ golang
# ./deploy_software.pl --new --target /home/ubuntu/ AWE
#rm -rf ~/gopath/src/github.com/MG-RAST/AWE/ ; cd ~/gopath/src/github.com/MG-RAST ; git clone https://github.com/wgerlach/AWE.git -b dev-bash

#sudo apt-get install multitail

# AWE-client needs to talk to docker socket
#sudo groupadd docker
#sudo gpasswd -a ${USER} docker
#sudo restart docker.io


# test 16S data set (illumina public) http://metagenomics.anl.gov/metagenomics.cgi?page=DownloadMetagenome&metagenome=4457770.3
# find data set ./shockclient.pl --debug --query id=mgm4457770.3,stage_name=preprocess,data_type=passed
# http://shock.metagenomics.anl.gov:80 deae84ae-d91d-46ce-a3f1-cc37d07e942f

CURRENT=`pwd`


#AWEDIR="/home/ubuntu/data/data/awe"
AWEDIR="/mnt/data/awe"

export SERVERLOG=${CURRENT}/awe-server.log
export CLIENTLOG=${CURRENT}/awe-client.log

GOPATH=~/gopath

killall -s 9 awe-client
killall -s 9 awe-server



# clean database
mongo AWEDB --eval "db.dropDatabase()"

set -e

rm -f $GOPATH/bin/awe-server $GOPATH/bin/awe-client
rm -f ${SERVERLOG} ${CLIENTLOG}
rm -f ${AWEDIR}/logs/client/*
rm -f ${AWEDIR}/logs/server/*

mkdir -p ${AWEDIR}/logs/server ${AWEDIR}/logs/client

cd $GOPATH/src/github.com/MG-RAST/AWE/
git pull


cd $GOPATH

# change package url
#gofmt -w -r '"oldurl" -> "newurl"' .
# use -l to show only, -w to write 
# gofmt -l  -r '"github.com/fsouza/go-dockerclient" -> "github.com/wgerlach/go-dockerclient"' .
#find . -type f -iregex '.*\.go' -exec gofmt -l  -r '"github.com/fsouza/go-dockerclient" -> "github.com/wgerlach/go-dockerclient"' '{}' +
#find . -type f -iregex '.*\.go' -exec sed -i -e "s/github.com\/fsouza\/go-dockerclient/github.com\/wgerlach\/go-dockerclient/g" {} \;

#echo "####### go fmt AWE     #######"
#go fmt github.com/MG-RAST/AWE/...

echo "####### go fix AWE     #######"
go fix github.com/MG-RAST/AWE/...

echo "####### go install AWE #######"
go install -v github.com/MG-RAST/AWE/...


$GOPATH/bin/awe-server -debug 1 -conf ${CURRENT}/awe-server.cfg 2> ${AWEDIR}/logs/server/stderr.log 1> ${AWEDIR}/logs/server/stdout.log &
sleep 3
$GOPATH/bin/awe-client -debug 1 -conf ${CURRENT}/awe-client.cfg 2> ${AWEDIR}/logs/client/stderr.log 1> ${AWEDIR}/logs/client/stdout.log &
sleep 2
curl -X POST -H "Datatoken: $GLOBUSONLINE"  -F upload=@${CURRENT}/picrust.json http://localhost:8001/job | json_pp
sleep 2
multitail -rc 3 -l "curl -X GET -s http://localhost:8001/job | json_pp | grep \"state\|notes\"" ${AWEDIR}/logs/client-default_client/* ${AWEDIR}/logs/server/*.log


#curl -X GET http://localhost:8001/job | json_xs  | less



