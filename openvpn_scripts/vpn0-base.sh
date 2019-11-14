#!/bin/bash

/sbin/ip route del 0.0.0.0/1 && ip route del 128.0.0.0/1
ENP0S3=`/sbin/ip r | grep -e "default" | sed 's/default//g'`
/sbin/ip route add VPN0 $ENP0S3
/sbin/openvpn /etc/openvpn/vpn0/VPN0.conf &
