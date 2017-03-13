#!/bin/sh
## @author: shivaram.mysore@gmail.com

echo "Run this $0 script as root" 

DOCKER_OPTS="--experimental=true"

echo "Customizing Docker Bridge"
echo -e "\nDOCKER_OPTS=\"--config-file=/etc/docker/daemon.json\"" >> /etc/default/docker
cp ../etc/docker/daemon.json /etc/docker/daemon.json

systemctl restart docker

echo "Checking Experimental flag on Docker ..."
docker version -f '{{.Server.Experimental}}'

