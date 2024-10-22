#!/bin/bash

echo "Checking system configuration for border gateway (Node 2)..."

# 1. Check for PPPoE server configuration
echo "Checking PPPoE server configuration..."
if pgrep pppoe-server > /dev/null; then
    echo "PPPoE server is running."
else
    echo "PPPoE server is NOT running."
fi

# 2. Check for registered users in chap-secrets
echo "Checking registered users in /etc/ppp/chap-secrets..."
if [ -s /etc/ppp/chap-secrets ]; then
    echo "Registered users found."
else
    echo "No registered users found."
fi

# 3. Check vnstat for traffic accounting
echo "Checking vnstat traffic accounting..."
if service vnstat status > /dev/null; then
    echo "vnStat is running."
else
    echo "vnStat is NOT running."
fi

# 4. Check if dnsmasq is running for DNS resolution
echo "Checking dnsmasq for DNS resolution..."
if service dnsmasq status > /dev/null; then
    echo "dnsmasq is running."
else
    echo "dnsmasq is NOT running."
fi

echo "Node 2 checks completed."

