#!/bin/sh
## @author: Shivaram.Mysore@gmail.com

CONTAINER_NAME=foobar

# Add Docker official GPG Key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Verify Key fingerprint
apt-key fingerprint 0EBFCD88

## By default Docker uses Linux bridge for networking. But it has support for
## external drivers. To use Open vSwitch instead of the Linux bridge, you will
## need to start the Open vSwitch driver.  The Open vSwitch driver uses the
## Python’s flask module to listen to Docker’s networking api calls.
## Hence, install it:
pip install Flask


add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get --assume-yes install docker-ce
# Verify Docker install
docker run hello-world
# Configure Docker to start on boot
systemctl enable docker
echo "Installing ovs-docker utility towards using ovs-bridge for Docker networking ..."
wget -P /usr/bin/ https://raw.githubusercontent.com/openvswitch/ovs/master/utilities/ovs-docker
chmod a+rwx /usr/bin/ovs-docker
echo "Create and attach a logical port to a running container ..."
#docker network create -d openvswitch --subnet=192.168.2.0/24 tap1
# docker network connect tap1 $CONTAINER_NAME
## ovs-vsctl add-port ovs-br0 tap1 -- set Interface tap1 type=internal ofport_request=10
docker rmi -f hello-world
docker ps -a
echo "List docker networks ..."
docker network ls

echo "To connect a conatainer to tap1 port on OVS bridge, use:"
echo " (IP address should in the same subnet as OVS bridge IP)"
echo "ovs-docker add-port ovs-br0 tap1 container1 --ipaddress=10.10.5.80/24"
