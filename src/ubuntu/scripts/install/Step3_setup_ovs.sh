#!/bin/bash
## @author: Shivaram.Mysore@gmail.com

## Check if user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run this script $0 as root"
  exit
fi

ENV=${1:-ovswitch}

## Function to get the property value for the provided key
function prop {
  grep "^${1}" ${ENV}.properties|cut -d'=' -f2
}

## Function to count the number of keys given the start of a key
function countprop {
  grep "^${1}" ${ENV}.properties | wc -l
}

if [ $(prop 'DPDK') = "false" ] ; then
      echo "This script sets up OVS Switch *without* DPDK support on this Linux box"
      ovs-vsctl add-br $(prop 'BRIDGE_NAME')
      ovs-vsctl list-br

      for ((i=1;i<=$(countprop 'HOST_IFACE');i++));
      do
        IFACE=HOST_IFACE_$i
        ovs-vsctl add-port $(prop 'BRIDGE_NAME') "$(prop "${IFACE}")" -- set Interface "$(prop "${IFACE}")" type=system
        ## Zero out your host interfaces that are attached to the bridge
        ip addr add 0 dev "$(prop "${IFACE}")"
      done

      # to add a wireless interface uncomment the next line.
      #ovs-vsctl add-port $BRIDGE_NAME $WIRELESS_HOST_IFACE_1 -- set Interface $WIRELESS_HOST_IFACE_1 type=system

    else
      echo "This script sets up OVS Switch *with* DPDK support on this Linux box"
      modprobe uio
      modprobe igb_uio
      echo "Listing Network devices using DPDK-compatible driver"
      /usr/share/dpdk/tools/dpdk_nic_bind.py --status

      echo "Perform the dpdk_nic_bind with the PCI IDs to be unbounded from Linux kernel."
      /usr/share/dpdk/tools/dpdk-devbind.py --bind=igb_uio 0000:02:00.0 0000:03:00.0 0000:05:00.0

      update-alternatives --set ovs-vswitchd /usr/lib/openvswitch-switch-dpdk/ovs-vswitchd-dpdk

      if [ ! -f /etc/openvswitch/conf.db ] ; then
        ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema
      fi

      modprobe uio
      modprobe igb_uio
      echo "Listing Network devices using DPDK-compatible driver"
      /usr/share/dpdk/tools/dpdk_nic_bind.py --status

      echo "Perform the dpdk_nic_bind with the PCI IDs to be unbounded from Linux kernel."
      /usr/share/dpdk/tools/dpdk-devbind.py --bind=igb_uio 0000:02:00.0 0000:03:00.0 0000:05:00.0

      update-alternatives --set ovs-vswitchd /usr/lib/openvswitch-switch-dpdk/ovs-vswitchd-dpdk

      if [ ! -f /etc/openvswitch/conf.db ] ; then
        ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema
      fi

      if [ -z ${DB_SOCK+x} ]; then
          export DB_SOCK=/var/run/openvswitch/db.sock;
        else
          echo "env DB_SOCK is set to '$DB_SOCK'";
      fi
      ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
      /usr/sbin/ovs-vswitchd unix:$DB_SOCK --pidfile --detach

      ovs-vsctl add-br $(prop 'BRIDGE_NAME') -- set bridge $(prop 'BRIDGE_NAME') datapath_type=netdev
      ovs-vsctl list-br

      for ((j=0,i=1;i<=$(countprop 'HOST_IFACE');i++,j++));
      do
        IFACE=HOST_IFACE_$i
        ovs-vsctl add-port $(prop 'BRIDGE_NAME') dpdk$j -- set Interface dpdk$j type=dpdk
        ## Zero out your host interfaces that are attached to the bridge
        ip addr add 0 dev dpdk$j
      done

fi


## Set OVS Bridge properties
ovs-vsctl set bridge $(prop 'BRIDGE_NAME') protocols=OpenFlow13 other_config:datapath-id=$(prop 'DATAPATH_ID')

## Assign Openflow Controller IP and Port number to the OVS Bridge
if [ $(prop 'IPV6') = "true" ] ; then
  ovs-vsctl set-controller $(prop 'BRIDGE_NAME') tcp:$(prop 'CNTRL_IPv4_1'):$(prop 'CNTRL_PORT_1') tcp:$(prop 'CNTRL_IPv6_1'):$(prop 'CNTRL_PORT_1') tcp:$(prop 'CNTRL_IPv4_2'):$(prop 'CNTRL_PORT_2') tcp:$(prop 'CNTRL_IPv6_2'):$(prop 'CNTRL_PORT_2')
else
  ovs-vsctl set-controller $(prop 'BRIDGE_NAME') tcp:$(prop 'CNTRL_IPv4_1'):$(prop 'CNTRL_PORT_1') tcp:$(prop 'CNTRL_IPv4_2'):$(prop 'CNTRL_PORT_2')
fi

## Set IP address for the OVS Bridge
if [ $(prop 'IPV6') = "true" ] ; then
  ip addr add $(prop 'BRIDGE_IPv6') dev $(prop 'BRIDGE_NAME')
fi
## Always set IPv4 address.
ip addr add $(prop 'BRIDGE_IPv4') dev $(prop 'BRIDGE_NAME')

## Show OVS brige information
ovs-vsctl show

## Show network interface information
echo "Network interface info ..."
ip link

echo "To get a dump of flows on the switch run:"
echo "ovs-ofctl -O OpenFlow13 dump-flows $(prop 'BRIDGE_NAME')"
echo ""

echo "For Port information, run:"
echo "ovs-ofctl -O OpenFlow13 dump-ports-desc $(prop 'BRIDGE_NAME')"
