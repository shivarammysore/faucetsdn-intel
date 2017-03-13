#!/bin/sh

## https://kindlund.wordpress.com/2007/11/19/configuring-multiple-default-routes-in-linux/

echo "1 admin" >> /etc/iproute2/rt_tables

ip route add 172.17.0.0/16 dev docker0 src 172.17.0.1 table admin
ip route add default via 172.17.1.254 dev docker0 table admin

ip rule show

ip rule add from 172.17.0.1/32 table main
ip rule add to 172.17.0.1/32 table main

ip rule show
