#!/bin/bash

URL=$1

bash -c "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

wget -O install-squid.sh $URL
bash install-squid.sh

