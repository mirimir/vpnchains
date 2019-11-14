#!/bin/bash

IPV4S=`cat /etc/openvpn/scripts/vpns1`
RPORT="1194"
for IPV4 in $IPV4S
do
   echo "remote "$IPV4 >> /tmp/vpn1
   echo "rport $RPORT" >> /tmp/vpn1
   cat /etc/openvpn/vpn1/base.conf >> /tmp/vpn1
   echo "auth-user-pass /etc/openvpn/vpn1/up" >> /tmp/vpn1
   echo "ca /etc/openvpn/vpn1/ca.crt" >> /tmp/vpn1
   echo "cert /etc/openvpn/vpn1/client.crt" >> /tmp/vpn1
   echo "key /etc/openvpn/vpn1/client.key" >> /tmp/vpn1
   echo "tls-auth /etc/openvpn/vpn1/ta.key" >> /tmp/vpn1
   cat /tmp/vpn1 > /etc/openvpn/vpn1/$IPV4.conf
done
