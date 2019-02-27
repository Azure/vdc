SQUID_SERVER_IP=$1
#Transparent proxy
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination "{$SQUID_SERVER_IP}:3128"