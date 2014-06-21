#!/bin/sh


SERVER-LOG=~/awe-server.log
CLIENT-LOG=~/awe-client.log

GOPATH=~/gopath

sudo killall awe-client
sudo killall awe-server

rm -rf $GOPATH/bin/awe-server $GOPATH/bin/awe-client
rm -f ~/data/data/awe/logs/client-default_client/*
rm -f ~/data/awe/logs/server/*

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


$GOPATH/bin/awe-server -debug 1 -conf ./awe-server.cfg 2>&1 > ${SERVER-LOG} &
sleep 3
$GOPATH/bin/awe-client -debug 1 -conf ./awe-client.cfg 2>&1 > ${CLIENT-LOG} &
sleep 2
curl -X POST -H "Datatoken: $GLOBUSONLINE"  -F upload=@/home/ubuntu/testjob.json http://localhost:8001/job | json_xs

multitail ~/data/data/awe/logs/client-default_client/*

echo ${SERVER-LOG} ${CLIENT-LOG}
