#!/bin/bash
## @author: Shivaram.Mysore@gmail.com

## This script sets up OVS 2.8.1 (tested) on a brand new installation of
## Ubuntu 17.04 with OVS 2.8.1 packages already installed on Intel Hardware
## Note: This script does not take into account exceptions raised during its run
##       Users must watch the output and apply necessary fixes.

### OVS script Configuration Settings ###

IPV6=false

## The port that is connected to the Management network
## This enables you to ssh to the box.
MGMT_IFACE=eno1

## The port that is connected to the Openflow Control Plane.
CNTRL_IFACE_1=

## IP address and port number of Openflow Controller - Faucet
CNTRL_IPv4_1=10.10.11.10
#CNTRL_IPv6_1=fe80::20e:c4ff:fece:6d6c
CNTRL_PORT_1=6653

## IP address and port number of Openflow Controller - Gauge
#CNTRL_IPv4_2=10.10.11.20
#CNTRL_IPv6_2=fe80::20e:c4ff:fece:6d6d
#CNTRL_PORT_2=6654

## Note: one of the host ports connected to the Bridge works as Uplink port
##  - possibly connected to the same switch as your DHCP server or has
##    visibility to the same via DHCP Relay or helper
BRIDGE_NAME=ovs-br0
BRIDGE_IPv4=10.10.5.8/16
#BRIDGE_IPv6=fe80::20e:c4ff:fece:6d6a/64
#BRIDGE_IPv6=cafe:babe:bead:0000:deaf::0002/64

## to add more ports, increment the number for HOST_IFACE_
## Wireless host port
#WIRELESS_HOST_IFACE_1=wlp4s0

### OF Trunk port
HOST_IFACE_1=eno2
HOST_IFACE_PCI_1=0000:03:00.1
### OF Ports
HOST_IFACE_2=ens786f0
HOST_IFACE_PCI_2=0000:05:00.0
HOST_IFACE_3=ens786f1
HOST_IFACE_PCI_3=0000:05:00.1
HOST_IFACE_4=ens786f2
HOST_IFACE_PCI_4=0000:05:00.2
HOST_IFACE_5=ens786f3
HOST_IFACE_PCI_5=0000:05:00.3
HOST_IFACE_6=ens787f0
HOST_IFACE_PCI_6=0000:81:00.0
HOST_IFACE_7=ens787f1
HOST_IFACE_PCI_7=0000:81:00.1
HOST_IFACE_8=ens787f2
HOST_IFACE_PCI_8=0000:81:00.2
### Wireless AP connected to ...
HOST_IFACE_9=ens787f3
HOST_IFACE_PCI_9=0000:81:00.3

## Datapath Id - by fixing this id, it is easy to control datapath id configuration
## Datapath id as defined as a 64-bit id
## Recommended for Datapath id value is MAC(lower 48 bits) + VLAN(top 16 bits)
## to make it easy for identification and also not clash with other Datapath ids
## dp_id == face-deaf-cafe-ccff
DATAPATH_ID=fa:ce:de:af:ca:fe:cc:ff

############# END OVS CONFIG SETTINGS ##################
### ++++++++++++++++++++++++++++++++++++++++++ ###


## Check if user is root
ROOTUID="0"
if [ "$(id -u)" -ne "$ROOTUID" ]; then
   echo "Run $0 script as root after a fresh install of Ubuntu 17.04 with OVS 2.8.1 packages installed"
   exit 1
fi

## Check the applicable network drivers for the device on the system
dpdk-devbind --status-dev net |  egrep -i --color drv=
## In this case, igb and igb_uio are the drivers.  Hence, check if those modules are loaded
modprobe igb_uio
lsmod | grep igb

echo "This script sets up OVS Switch *with* DPDK support on this Linux box"

# Keep only those iterfaces that have been configured for use.
/sbin/dpdk-devbind --bind=igb_uio $HOST_IFACE_2 $HOST_IFACE_3 $HOST_IFACE_4 $HOST_IFACE_5 $HOST_IFACE_6 $HOST_IFACE_7 $HOST_IFACE_8 $HOST_IFACE_9
/sbin/dpdk-devbind --bind=igb_uio $HOST_IFACE_1
/sbin/dpdk-devbind --status
## On this system, there are 2 CPUs.  Hence, allocating memory on both.
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,1024"
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true

ovs-vsctl del-br $BRIDGE_NAME
ovs-vsctl add-br $BRIDGE_NAME -- set bridge $BRIDGE_NAME datapath_type=netdev protocols=OpenFlow13 other_config:datapath-id=$DATAPATH_ID
ip addr add $BRIDGE_IPv4 dev $BRIDGE_NAME
ovs-vsctl list-br

# Comment out the ports that are not configured
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_1 -- set Interface $HOST_IFACE_1 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_1 ofport_request=1
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_2 -- set Interface $HOST_IFACE_2 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_2 ofport_request=2
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_3 -- set Interface $HOST_IFACE_3 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_3 ofport_request=3
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_4 -- set Interface $HOST_IFACE_4 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_4 ofport_request=4
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_5 -- set Interface $HOST_IFACE_5 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_5 ofport_request=5
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_6 -- set Interface $HOST_IFACE_6 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_6 ofport_request=6
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_7 -- set Interface $HOST_IFACE_7 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_7 ofport_request=7
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_8 -- set Interface $HOST_IFACE_8 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_8 ofport_request=8
ovs-vsctl add-port $BRIDGE_NAME $HOST_IFACE_9 -- set Interface $HOST_IFACE_9 type=dpdk options:dpdk-devargs=$HOST_IFACE_PCI_9 ofport_request=9

ovs-vsctl show
echo "Mapping of OpenFlow port number for a given port ..."
ovs-vsctl -- --columns=name,ofport list Interface
echo "Get Datapath ID of the bridge ..."
ovs-vsctl get bridge $BRIDGE_NAME datapath_id
echo "... Information on how bridge is configured ..."
ovs-ofctl -O OpenFlow13 show $BRIDGE_NAME | head -3
echo "--------"

## Setup Certs for SSL Connectivity
# mkdir -p /usr/local/switch/pki
# Copy all the certs and keys to the above directory
# chmod 0400 on Switch private key file.
# ovs-vsctl set-ssl /usr/local/switch/pki/switch-private-key.pem /usr/local/switch/pki/switch-public-certificate.pem /usr/local/switch/pki/switch-and-controller-ca-certificate-chain.pem
ovs-vsctl get-ssl

# Append more controllers if they are configured.
ovs-vsctl set-controller $BRIDGE_NAME tcp:$CNTRL_IPv4_1:$CNTRL_PORT_1
# If SSL is enabled, then use ssl instead of tcp in the above command.

echo "Commands for Open vSwitch Service control ... "
echo "systemctl [status | start | stop | restart] openvswitch-switch.service"
