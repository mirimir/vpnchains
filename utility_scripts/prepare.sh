#!/bin/bash

apt-get update
apt-get -y install openvpn isc-dhcp-server iptables-persistent w3m
sleep 5
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
cp /home/user/vpnchains/dhcp/dhcpd.conf /etc/dhcp/
echo 'INTERFACES="enp0s8"' > /etc/default/isc-dhcp-server
systemctl start isc-dhcp-server.service
