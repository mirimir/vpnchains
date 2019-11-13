#!/bin/bash

ip route del 0.0.0.0/1 && ip route del 128.0.0.0/1
TUN0=`ip address show dev tun0 | grep -e "peer" | awk '{ print $4 }' | awk -F '/' '{ print $1 }'`
ip route add VPN1 via $TUN0 dev tun0
openvpn /etc/openvpn/vpn1/VPN1.conf &
