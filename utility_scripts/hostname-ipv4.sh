#!/bin/bash

HOSTNAMES=`cat hostnames.txt`
for HOSTNAME in $HOSTNAMES
do
   host $HOSTNAME | sed 's/ has address /\t/g' >> hostname-ipv4.txt
done
