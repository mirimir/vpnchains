#!/bin/bash

while :
do
   VPNS=`ps -fC openvpn | grep -e "openvpn" | awk '{ print $2 }' | tr '\n' ' '`
   kill $VPNS
   sleep 2
   VPN0=`shuf -n 1 /etc/openvpn/scripts/vpns0`
   VPN1=`shuf -n 1 /etc/openvpn/scripts/vpns1`
   # for a third VPN, add this
   # VPN2=`shuf -n 1 /etc/openvpn/scripts/vpns2`
   cat /etc/iptables/vpn-rules-base.v4 | sed "s/VPN0/$VPN0/g" | sed "s/VPN1/$VPN1/g" > /tmp/rules
   # with a third VPN, add '| sed "s/VPN1/$VPN1/g"'
   cat /tmp/rules > /etc/iptables/vpn-rules.v4
   iptables-restore < /etc/iptables/vpn-rules.v4
   cat /etc/openvpn/scripts/vpn0-base.sh | sed "s/VPN0/$VPN0/g" > /tmp/vpns
   cat /tmp/vpns > /etc/openvpn/scripts/vpn0.sh
   chmod u+x /etc/openvpn/scripts/vpn0.sh
   cat /etc/openvpn/scripts/vpn1-base.sh | sed "s/VPN1/$VPN1/g" > /tmp/vpns
   cat /tmp/vpns > /etc/openvpn/scripts/vpn1.sh
   chmod u+x /etc/openvpn/scripts/vpn1.sh
   # with a third VPN, add this
   # cat /etc/openvpn/scripts/vpn2-base.sh | sed "s/VPN2/$VPN2/g" > /tmp/vpns
   # cat /tmp/vpns > /etc/openvpn/scripts/vpn2.sh
   # chmod u+x /etc/openvpn/scripts/vpn2.sh
   /etc/openvpn/scripts/vpn0.sh
   sleep 5
   /etc/openvpn/scripts/vpn1.sh
   # with a third VPN, add this
   # sleep 5
   # /etc/openvpn/scripts/vpn2.sh
   sleep 15
   MINRTT=`ping -fc 10 -I tun2 1.1.1.1 | grep -e "rtt" | awk -F '= ' '{ print $2 }' | awk -F '/' '{ print $1 }'`
   DATE=`date -u --rfc-3339=seconds`
   echo $DATE  $VPN0  $VPN1  $MINRTT >> /etc/openvpn/scripts/vpns.log
   # with a third VPN, add "$VPN2"
   if [ "$MINRTT" <> -n ]
      then sleep 577
   fi
done
