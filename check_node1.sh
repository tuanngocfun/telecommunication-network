#!/bin/bash

echo "Checking system configuration for home gateway (Node 1)..."

# 1. Check if IP forwarding is enabled
echo "Checking IP forwarding..."
if sysctl net.ipv4.ip_forward | grep -q "1"; then
    echo "IPv4 forwarding is enabled."
else
    echo "IPv4 forwarding is NOT enabled."
fi

if sysctl net.ipv6.conf.all.forwarding | grep -q "1"; then
    echo "IPv6 forwarding is enabled."
else
    echo "IPv6 forwarding is NOT enabled."
fi

# 2. Check if the home gateway has only one IPv4 address assigned
echo "Checking IPv4 address assignment..."
if ip -4 addr show ppp0 | grep -q "inet"; then
    echo "IPv4 address is assigned."
else
    echo "No IPv4 address assigned."
fi

# 3. Check if a /56 IPv6 prefix is assigned
echo "Checking IPv6 address assignment..."
if ip -6 addr show ppp0 | grep -q "inet6"; then
    echo "/56 IPv6 prefix is assigned."
else
    echo "No IPv6 prefix assigned."
fi

echo "Node 1 checks completed."

