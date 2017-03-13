#!/bin/sh
## @author: Shivaram.Mysore@gmail.com
## Check if user is root
if [ "$EUID" -ne 0 ]
      then echo "Run $0 script as root after a fresh install of Ubuntu 16.10"
      exit
fi

apt-get update

apt-get install software-properties-common git wget curl unzip bzip2 screen minicom make python2.7 libpython2.7 python-pip linux-image-extra-$(uname -r) apt-transport-https ca-certificates

# enable IPv6 
sysctl net.ipv6.conf.all.disable_ipv6=0
pip install --upgrade pip

pip install ryu ryu-faucet couchapp

echo "deb https://packagecloud.io/grafana/stable/debian/ jessie main" >> /etc/apt/sources.list
curl https://packagecloud.io/gpg.key | sudo apt-key add -
apt-get update

apt-get install influxdb couchdb grafana influxdb-client

# configure the Grafana server to start at boot time
update-rc.d grafana-server defaults

# start the grafana-server process as the grafana user. 
# The default HTTP port is 3000 and default user and group is admin
# /etc/grafana/grafana.ini - default config file
# service grafana-server start
systemctl daemon-reload
systemctl start grafana-server
systemctl status grafana-server

cp ../etc/systemd/system/* /etc/systemd/system/
cp ../usr/local/bin/start*sh /usr/local/bin/
chmod +x /usr/local/bin/start-faucet.sh
chmod +x /usr/local/bin/start-gauge.sh

cp ../etc/ryu/faucet/*.yaml /etc/ryu/faucet/

systemctl enable faucet
systemctl enable gauge

systemctl start faucet
systemctl start gauge

systemctl status faucet
systemctl status gauge

echo "Edit /etc/ryu/faucet/faucet.yaml and /etc/ryu/gauge.yaml accordingly"
echo "On changes to *yaml files, issue systemclt restart <faucet | gauge>"
