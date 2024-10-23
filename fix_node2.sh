#!/bin/bash

echo "Fixing issues on Node 2 (bordergateway)..."

# 1. Ensure the PPPoE address pool file exists
if [ ! -f /etc/ppp/ipaddress_pool ]; then
    echo "Creating the PPPoE address pool file..."
    echo "10.0.0.30-10.0.0.253" > /etc/ppp/ipaddress_pool
fi

# 2. Start the PPPoE server on the correct interface
interface=$(ip link | grep -m1 'ppp' | awk -F: '{print $2}' | tr -d ' ')
if [ -z "$interface" ]; then
    echo "No PPPoE interface found. Skipping PPPoE setup."
else
    echo "Starting PPPoE server on $interface..."
    pppoe-server -C addname -S isp -L 10.0.0.1 -p /etc/ppp/ipaddress_pool -I "$interface" -m 1412
fi

# 3. Assign IP addresses using the ip command
echo "Assigning IP address to ppp0..."
ip addr add 10.0.0.50/24 dev ppp0

# 4. Set iptables INPUT policy to DROP
echo "Setting iptables INPUT policy to DROP for security..."
iptables -P INPUT DROP
ip6tables -P INPUT DROP

# 5. Manage dnsmasq without systemd
echo "Managing dnsmasq service..."
if [ -f /etc/init.d/dnsmasq ]; then
    /etc/init.d/dnsmasq start
else
    echo "dnsmasq service not found."
fi

echo "Node 2 issues fixed."

