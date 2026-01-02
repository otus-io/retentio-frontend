#!/bin/bash
# Squid Proxy Whitelist Firewall Script

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Define your allowed networks (customize these)
ALLOWED_NETWORKS=(
    "192.168.0.0/16"     # Private networks
    "10.0.0.0/8"         # Private networks  
    "172.16.0.0/12"      # Private networks
    "126.156.205.62/24"   # Manami's phone networks
    "112.117.205.0/24"   # Joe's home network
    "210.157.218.0/24"   # Joe's home network
    "218.62.247.111/24"   # Joe's home network
)

# Allow traffic from whitelisted networks
for network in "${ALLOWED_NETWORKS[@]}"; do
    iptables -A INPUT -s $network -j ACCEPT
    echo "Allowed: $network"
done

# Allow specific services from anywhere (if needed)
# iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # HTTP
# iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS

# Log dropped packets (optional - for monitoring)
iptables -A INPUT -j LOG --log-prefix "DROPPED: " --log-level 4

echo "Firewall rules applied. Everything blocked except whitelisted networks."
echo "Current rules:"
iptables -L -n
