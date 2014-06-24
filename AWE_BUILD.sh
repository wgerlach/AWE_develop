#!/bin/sh

set -x

#dockerized invocation?
#sudo docker.io run -t -i --name awe_develop -v /home/ubuntu/AWE_develop:/AWE_develop ubuntu:14.04 /bin/bash
# install go
# install AWE

CURRENT=`pwd`

export SERVERLOG=${CURRENT}/awe-server.log
export CLIENTLOG=${CURRENT}/awe-client.log

GOPATH=~/gopath

killall -s 9 awe-client
killall -s 9 awe-server



# clean database
mongo AWEDB --eval "db.dropDatabase()"

set -e

rm -rf $GOPATH/bin/awe-server $GOPATH/bin/awe-client
rm -f ${SERVERLOG} ${CLIENTLOG}
rm -f /mnt/data/awe/logs/client-default_client/*
rm -f /mnt/data/awe/logs/server/*

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


$GOPATH/bin/awe-server -debug 1 -conf ${CURRENT}/awe-server.cfg 2>&1 > ${SERVERLOG} &
sleep 3
$GOPATH/bin/awe-client -debug 1 -conf ${CURRENT}/awe-client.cfg 2>&1 > ${CLIENTLOG} &
sleep 2
curl -X POST -H "Datatoken: $GLOBUSONLINE"  -F upload=@${CURRENT}/testjob.json http://localhost:8001/job | json_xs
sleep 2
multitail -rc 3 -l "curl -X GET -s http://localhost:8001/job | json_xs | grep \"state\|notes\"" ~/data/data/awe/logs/client-default_client/* ${CLIENTLOG} ~/data/data/awe/logs/server/error.log


#curl -X GET http://localhost:8001/job | json_xs  | less



