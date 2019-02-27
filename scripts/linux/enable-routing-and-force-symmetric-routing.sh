#!/bin/bash
bash -c "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

DMZ_NIC_IP_ADDRESS=$1
DMZ_SUBNET_ADDRESS_PREFIX=$2
DMZ_DEFAULT_GATEWAY=$3
DMZ_NIC_DEVICE=$4

# Update filter parameters along with route-based policy to fix asymmetric routing
sysctl net.ipv4.conf.all.rp_filter=0
sysctl net.ipv4.conf.default.rp_filter=0
sysctl net.ipv4.conf.eth0.rp_filter=0
sysctl net.ipv4.conf.eth1.rp_filter=0
sysctl net.ipv4.conf.lo.rp_filter=0

# Fixes asymmetric routing. Prevents a request coming from one nic to go out from a different nic
# To prevent a request generated from a jumpbox to go out from eth1 (shared-services)
ip route add $DMZ_SUBNET_ADDRESS_PREFIX dev $DMZ_NIC_DEVICE table 128
ip route add default via $DMZ_DEFAULT_GATEWAY dev $DMZ_NIC_DEVICE table 128
ip rule add from "${DMZ_NIC_IP_ADDRESS}/32" table 128 priority 100

# Enables SNAT to allow packets that goes out (from the nic associated to a pip) to come back to the NVA
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -A POSTROUTING -j SNAT --to-source $DMZ_NIC_IP_ADDRESS

