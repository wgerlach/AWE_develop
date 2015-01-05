#!/bin/sh

set -x
set -e

cd /gopath/src/github.com/MG-RAST/
rm -rf AWE golib go-dockerclient

git clone https://github.com/MG-RAST/AWE.git -b master
#ls ; ${GIT_RESET}
git clone https://github.com/MG-RAST/golib.git
git clone https://github.com/MG-RAST/go-dockerclient.git


go install -v github.com/MG-RAST/AWE/...


