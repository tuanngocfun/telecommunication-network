#!/bin/bash

echo "Fixing issues on Node 1 (homegateway)..."

# 1. Enable IPv6 forwarding
echo "Enabling IPv6 forwarding..."
sysctl -w net.ipv6.conf.all.forwarding=1

# 2. Check for the correct network interface
echo "Starting PPPoE server on correct interface..."
interface=$(ip link | grep -m1 'ppp' | awk -F: '{print $2}' | tr -d ' ')
if [ -z "$interface" ]; then
    echo "No PPPoE interface found. Skipping PPPoE setup."
else
    pppoe-server -C addname -S isp -L 10.0.0.1 -p /etc/ppp/ipaddress_pool -I "$interface" -m 1412
fi

# 3. Skip DNS configuration if dnsmasq is not needed
echo "Skipping DNS configuration."

# 4. Apply iptables rules
echo "Setting iptables INPUT policy to DROP for security..."
iptables -P INPUT DROP
ip6tables -P INPUT DROP

echo "Node 1 issues fixed."

