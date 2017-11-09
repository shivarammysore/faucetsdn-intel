#!/bin/sh
## @author: Shivaram.Mysore@gmail.com

## This script installs OVS 2.8.1 (tested) on a brand new installation of
## Ubuntu 17.04 on Intel Hardware
## Note: This script does not take into account exceptions raised during its run
##       Users must watch the output and apply necessary fixes.

## Check if user is root
if [ "$EUID" -ne 0 ]
    then echo "Run $0 script as root after a fresh install of Ubuntu 17.04"
    exit
fi

apt-get --assume-yes install python3 python3-pip apt-transport-https

# enable IPv6
sysctl net.ipv6.conf.all.disable_ipv6=0

# Add WAND Repo to get latest Open vSwitch
echo "deb https://packages.wand.net.nz $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/wand.list
curl https://packages.wand.net.nz/keyring.gpg -o /etc/apt/trusted.gpg.d/wand.gpg
apt-get update

# Install utilities and packages needed
apt-get --assume-yes install software-properties-common git wget curl unzip bzip2 screen minicom make gcc dpdk dpdk-dev dpdk-doc dpdk-igb-uio-dkms openvswitch-common openvswitch-switch python-openvswitch openvswitch-pki openvswitch-testcontroller openvswitch-switch-dpdk linux-image-extra-$(uname -r) linux-image-extra-virtual apt-transport-https ca-certificates vlan libnss3-tools

# Make sure to set Python3 as the version of python to use
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 2
update-alternatives --install /usr/bin/python python /usr/bin/python3.5 3
update-alternatives --config python
update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 3

# Show the versions of installed Open vSwitch packages
dpkg -l openvswitch-common openvswitch-pki openvswitch-switch openvswitch-testcontroller python-openvswitch openvswitch-switch-dpdk dpdk dpdk-dev dpdk-doc dpdk-igb-uio-dkms

# Module settings may have to be tuned based on drivers required for Network interfaces used
echo "igb_uio" >> /etc/modules
echo "vfio-pci" >> /etc/modules
echo "uio_pci_generic" >> /etc/modules

# Enable DPDK interfaces
echo "pci     0000:04:00.0    vfio-pci" >> /etc/dpdk/interfaces
echo "pci	    0000:04:00.1    uio_pci_generic" >> /etc/dpdk/interfaces
echo "## Interfaces on this machine that needs to be loaded on (re)boot" >> /etc/dpdk/interfaces
echo "pci     0000:03:00.1    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:05:00.0    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:05:00.1    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:05:00.2    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:05:00.3    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:81:00.0    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:81:00.1    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:81:00.2    igb_uio" >> /etc/dpdk/interfaces
echo "pci     0000:81:00.3    igb_uio" >> /etc/dpdk/interfaces


echo "Setting environment variable DB_SOCK in /etc/environment file ..."
/bin/echo -en "DB_SOCK=/var/run/openvswitch/db.sock" >> /etc/environment

ovs-vswitchd --version

echo "List all network cards on the system ...and corresponding PCI-MAC mapping"
#lspci | egrep -i --color 'network|ethernet'
lshw -c network -businfo

# Note: If the next command fails, run the same after reboot of the machine at the end of this script.
update-alternatives --set ovs-vswitchd /usr/lib/openvswitch-switch-dpdk/ovs-vswitchd-dpdk


echo ""
echo "Modify /etc/default/grub to include hugepages settings."
echo "Reserve 1G huge pages via grub configurations. For example:"
echo " to reserve 4 huge pages of 1G size - add parameters: default_hugepagesz=1G hugepagesz=1G hugepages=4"
echo " For 2 CPU cores, Isolate CPU cores which will be used for DPDK - add parameters: isolcpus=2"
echo " To use VFIO - add parameters: iommu=pt intel_iommu=on"
echo "Note: If you are not sure about something, leave it asis!!"
echo -e "\033[47m  \033[1;91m GRUB_CMDLINE_LINUX_DEFAULT=\"quiet intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=4\" \033[0m"
echo -e "After changing /etc/default/grub, run command: \033[47m  \033[1;91m update-grub \033[0m"
echo -e "\033[47m  \033[1;91m reboot \033[0m system for changes to take effect."
