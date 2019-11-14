#!/bin/bash

IPV4S=`cat /etc/openvpn/scripts/vpns0`
RPORT="1194"
for IPV4 in $IPV4S
do
   echo "remote "$IPV4 >> /tmp/vpn0
   echo "rport $RPORT" >> /tmp/vpn0
   cat /etc/openvpn/vpn0/base.conf >> /tmp/vpn0
   echo "auth-user-pass /etc/openvpn/vpn0/up" >> /tmp/vpn0
   echo "ca /etc/openvpn/vpn0/ca.crt" >> /tmp/vpn0
   echo "cert /etc/openvpn/vpn0/client.crt" >> /tmp/vpn0
   echo "key /etc/openvpn/vpn0/client.key" >> /tmp/vpn0
   echo "tls-auth /etc/openvpn/vpn0/ta.key" >> /tmp/vpn0
   cat /tmp/vpn0 > /etc/openvpn/vpn0/$IPV4.conf
done
