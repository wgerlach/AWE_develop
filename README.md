

### Statically compile AWE and create minimal docker images of AWE worker and server

Execution environment for this script is a default AWE worker (client) container, e.g.:
```bash
docker build -t skyport/awe-factory:latest https://raw.githubusercontent.com/MG-RAST/Skyport/master/dockerfiles/awe-client/Dockerfile
```

This container needs to be started with socker socket mounted to allow this script to build a scratch AWE worker docker image:
```bash
docker run -t -i -v /usr/bin/docker:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock --name awe-factory skyport/awe-factory:latest
```

Download script to compile statically
```bash
cd /
wget https://raw.githubusercontent.com/wgerlach/AWE_develop/master/compile_AWE_client_and_create_scratch_image.sh
```

If you want to change source branch and/or location, e.g:
```bash
cd /gopath/src/github.com/MG-RAST/
rm -rf AWE golib go-dockerclient
git clone --recursive https://github.com/MG-RAST/AWE.git -b master
git clone https://github.com/MG-RAST/golib.git -b master
git clone https://github.com/MG-RAST/go-dockerclient.git -b master
```

The first time you compile, you may need to get the depndencies first:
```bash
go get github.com/MG-RAST/AWE/...
```

Then run this script to statically compile AWE and create AWE worker and AWE server minimal images:
```bash
cd /
./compile_AWE_client_and_create_scratch_image.sh
```
