#!/bin/sh

sudo apt-get update
sudo apt-get install build-essential fakeroot gcc clang-3.9 make libcap-ng-dev libcap-ng-utils python python-six autoconf automake libtool perl python-pyftpdlib wget netcat curl python-tftpy graphviz iproute2 libcurl4-openssl-dev libssl-dev flake8 python-flake8 sphinx-common sphinx-rtd-theme-common linux-headers-$(uname -r) 

sudo apt-get install linux-image-extra-$(uname -r) dpdk-igb-uio-dkms

wget http://fast.dpdk.org/rel/dpdk-17.02.tar.xz 
tar xvfJ dpdk-17.02.tar.xz
cd dpdk-17.02
sudo usertools/cpu_layout.py 
sudo usertools/dpdk-devbind.py --status

echo "Select the following Options in DPDK Setup ..."
echo "Step1: [13] x86_64-native-linuxapp-gcc"
echo "Step4: [27] List hugepage info from /proc/meminfo"
echo "Step2: [16] Insert IGB UIO module"
echo "       [20] Setup hugepage mappings for NUMA systems"
echo "            Number of pages for node0: 64"
echo "            Number of pages for node1: 64"
echo "       [21] Display current Ethernet/Crypto device settings"
echo "       [22] Bind Ethernet/Crypto device to IGB UIO module"
echo "         Keep entering the PCI slot addresses for each port individually"
echo " Network devices using DPDK-compatible driver"
echo " ============================================"
echo " 0000:81:00.0 '82599ES 10-Gigabit SFI/SFP+ Network Connection' drv=igb_uio unused=ixgbe"
echo " 0000:81:00.1 '82599ES 10-Gigabit SFI/SFP+ Network Connection' drv=igb_uio unused=ixgbe"
echo " 0000:82:00.0 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo " 0000:82:00.1 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo " 0000:82:00.2 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo " 0000:82:00.3 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo " 0000:83:00.0 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo " 0000:83:00.1 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo " 0000:83:00.2 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo " 0000:83:00.3 'I350 Gigabit Network Connection' drv=igb_uio unused=igb"
echo ""
echo "Exit Setup - 33"

make config T=x86_64-native-linuxapp-gcc
sed -ri 's,(PMD_PCAP=).*,\1y,' build/.config


wget http://openvswitch.org/releases/openvswitch-2.7.0.tar.gz
tar -zxvf openvswitch-2.7.0.tar.gz
cd openvswitch-2.7.0

