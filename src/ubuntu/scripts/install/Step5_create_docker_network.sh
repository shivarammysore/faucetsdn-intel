#!/bin/sh
## @author: Shivaram.Mysore@gmail.com

## Check if user is root
if [ "$EUID" -ne 0 ]
      then echo "Run $0 script as root after a fresh install of Ubuntu 16.10"
      exit
fi
## Docker Requirements
## Docker v1.12+
## Linux Kernel version 3.9+ (Ubuntu 16.10 comes with Kernel v4.8

#######################
## Generic MACVLAN understanding
## http://hicu.be/bridge-vs-macvlan - Need functionality like MACVLAN VEPA Mode here.  But, 
## Docker macvlan driver only supports macvlan bridge mode!
## http://hicu.be/docker-networking-macvlan-bridge-mode-configuration
## http://www.pocketnix.org/posts/Linux%20Networking:%20MAC%20VLANs%20and%20Virtual%20Ethernets 
## 
#######################

# https://docs.docker.com/engine/userguide/networking/get-started-macvlan/

docker network ls
# Dual Stack IPv4 IPv6 Macvlan Bridge Mode
# Macvlan Bridge mode, 802.1q trunk, VLAN ID: 218, Multi-Subnet, Dual Stack
# Create bridge subnet with a gateway of x.x.x.1:
docker network  create  -d macvlan --subnet=192.168.218.0/24 --gateway=192.168.218.1 --subnet=2001:db8:babe:cafe::/64 --gateway=2001:db8:babe:cafe::1 -o parent=enp1s0f1.218 --ipv6 -o macvlan_mode=bridge macvlan218

echo "Verify that the macvlan218 network was created ...."
docker network ls

echo "macvlan218 network details ..."
docker network inspect macvlan218

echo "spin up the faucet container ..."
docker run --name='container0' --hostname='faucet0' --net=macvlan218 --detach=true -v /etc/ryu/faucet:/etc/ryu/faucet/ -v /var/log/ryu/faucet/:/var/log/ryu/faucet/ -p 6653:6653  faucet/faucet:latest

echo "DEBUG NOTE:: docker [logs | attach] faucet0"
echo "DEBUG NOTE:: docker inspect faucet0"
echo "Listing all containers ..."
docker ps -a
docker ps -l

echo "Listing all docker images ..."
docker images
## to remove a docker image: docker rm <image_id>

echo "macvlan218 network details ..."
docker network inspect macvlan218

echo "Verify that the IP address is really configured in the container ..."
docker exec -ti faucet0 ip a | grep 'mtu|inet'

echo "verify IP route in the container ..."
docker exec -ti faucet0 ip route

echo "verify IPv6 route ..."
docker exec -ti faucet0 ip -6 route

