#!/bin/bash

# Node IP addresses and password
NODE1="172.20.20.2"
NODE2="172.20.20.3"
USER="root"
PASSWORD="acn2024"

# Function to run commands on a specified node using sshpass for password-based authentication
function run_on_node() {
  NODE_IP=$1
  COMMAND=$2
  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$NODE_IP "$COMMAND"
}

echo "Starting PPPoE tests on Node 1 ($NODE1) and Node 2 ($NODE2)..."

# Test for Node 1 (homegateway)
echo "Running tests on Node 1 (homegateway)..."

# 1. Verify IP Forwarding
run_on_node $NODE1 "sysctl net.ipv4.ip_forward && sysctl net.ipv6.conf.all.forwarding"

# 2. Verify PPPoE Server Configuration
run_on_node $NODE1 "cat /etc/ppp/pppoe-server-options && cat /etc/ppp/chap-secrets && cat /etc/ppp/ipaddress_pool"

# 3. Check if PPPoE Server is Running
run_on_node $NODE1 "pgrep pppoe-server && echo 'PPPoE server is running' || echo 'PPPoE server is NOT running'"

# 4. Verify Network Interface Configuration (e1-1)
run_on_node $NODE1 "ip link show e1-1 && ip addr show e1-1"

# Test for Node 2 (bordergateway)
echo "Running tests on Node 2 (bordergateway)..."

# 1. Verify IP Forwarding
run_on_node $NODE2 "sysctl net.ipv4.ip_forward && sysctl net.ipv6.conf.all.forwarding"

# 2. Verify DNS Configuration for Local Name Resolution
run_on_node $NODE2 "grep 'address=' /etc/dnsmasq.conf"

# 3. Verify Traffic Accounting (vnstat)
#run_on_node $NODE2 "systemctl is-active vnstat && echo 'vnstat is active' || echo 'vnstat is NOT active'"

# 4. Verify Network Interface Configuration (e1-1)
run_on_node $NODE2 "ip link show e1-1 && ip addr show e1-1"

# Alternative vnstat initialization and statistics
echo "Initializing and verifying vnstat for interface e1-1 on Node 2..."
run_on_node $NODE2 "vnstat -i e1-1 && ip -s link show e1-1"

echo "PPPoE test completed for both nodes."

