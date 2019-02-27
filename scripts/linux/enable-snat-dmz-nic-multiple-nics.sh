DMZ_NIC_IP_ADDRESS=$1

# Enables SNAT to allow packets that goes out (from the nic associated to a pip) to come back to the NVA
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -A POSTROUTING -j SNAT --to-source $DMZ_NIC_IP_ADDRESS
