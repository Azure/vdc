#!/bin/bash
bash -c "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

DMZ_NIC_IP_ADDRESS=$1
DMZ_SUBNET_ADDRESS_PREFIX=$2
DMZ_DEFAULT_GATEWAY=$3
DMZ_NIC_DEVICE=$4

# Fixes asymmetric routing. Prevents a request coming from one nic to go out from a different nic
ip route add $DMZ_SUBNET_ADDRESS_PREFIX dev $DMZ_NIC_DEVICE table 128
ip route add default via $DMZ_DEFAULT_GATEWAY dev $DMZ_NIC_DEVICE table 128
ip rule add from "{$DMZ_NIC_IP_ADDRESS}/32" table 128 priority 100
ip route flush cache