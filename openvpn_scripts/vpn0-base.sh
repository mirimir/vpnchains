#!/bin/bash

ip route del 0.0.0.0/1 && ip route del 128.0.0.0/1
ENP0S3=`ip r | grep -e "default" | sed 's/default//g'`
ip route add VPN0 $ENP0S3
openvpn /etc/openvpn/vpn0/VPN0.conf &
