

### Statically compile AWE (and optionally create minimal docker images of AWE worker and server)

These instructions show how to use a normal AWE Docker image as factory environment to statically compile the AWE binaries and 

Execution environment for this script is a default AWE worker (client) container, e.g.:
```bash
docker build -t skyport/awe-factory:latest https://raw.githubusercontent.com/MG-RAST/AWE/develop/dockerfiles/awe/Dockerfile
```

This container needs to be started with socker socket mounted to allow this script to build a scratch AWE worker docker image:
```bash
docker run -t -i -v /usr/bin/docker:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock --name awe-factory skyport/awe-factory:latest
```
Alternatively, if you only want the binaries and need no docker image, mount the /gopath/bin/ directory:
```bash
docker run -t -i -v ~/awe_binaries/:/gopath/bin/ --name awe-factory skyport/awe-factory:latest
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

The first time you compile, you may need to get the dependencies first:
```bash
go get github.com/MG-RAST/AWE/...
```

Then run this script to statically compile AWE and create AWE worker and AWE server minimal images:
```bash
cd /
./compile_AWE_client_and_create_scratch_image.sh
```

If you mounted the docker binary into your factory container, you should get nice small images:
```text
REPOSITORY                   TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
skyport/awe-server-minimal   20150420.1601       7be1891365c8        7 seconds ago       13.03 MB
skyport/awe-client-minimal   20150420.1601       d72df1158340        14 seconds ago      10.31 MB
```
