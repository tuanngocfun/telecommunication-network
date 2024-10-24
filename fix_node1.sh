#!/bin/bash

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    sleep 1 # Simulate processing time
}

log "Fixing issues on Node 1 (homegateway)..."

# 1. Enable IPv6 forwarding
log "Enabling IPv6 forwarding..."
sysctl -w net.ipv6.conf.all.forwarding=1
log "IPv6 forwarding enabled."

# 2. Detect available network interface (Refining to prevent the split issue)
log "Finding available network interfaces..."
interface=$(ip link | grep -E 'enp|eth|ens' | awk -F: '{print $2}' | tr -d ' ' | head -n 1)
if [ -z "$interface" ]; then
    log "No network interface found for PPPoE. Exiting."
    exit 1
else
    log "Found interface: $interface. Attempting to start PPPoE session."
    
    # 3. Start a PPPoE session using pppd (on the detected interface)
    log "Starting PPPoE session on $interface..."
    pppd pty "/usr/sbin/pppoe -I $interface" noauth debug nodetach \
          mtu 1492 mru 1492 lcp-echo-interval 10 lcp-echo-failure 2 \
          defaultroute holdoff 5 maxfail 1 ipparam homegateway
    if [ $? -eq 0 ]; then
        log "PPPoE session started successfully on $interface."
    else
        log "Failed to start PPPoE session on $interface."
    fi
fi

# 4. Set iptables rules
log "Allowing SSH traffic before applying security rules..."
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT

log "Setting iptables INPUT policy to DROP for security..."
iptables -P INPUT DROP
ip6tables -P INPUT DROP
log "Security rules applied."

log "Node 1 issues fixed."

