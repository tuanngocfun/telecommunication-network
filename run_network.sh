#!/bin/bash

# Step 1: Clean up old containers and images
echo "Cleaning up old containers and images..."
if [ "$(sudo docker ps -aq)" ]; then
  sudo docker container rm -f $(sudo docker ps -aq)
fi
if sudo docker image inspect homegateway >/dev/null 2>&1; then
  sudo docker image rm -f homegateway
fi
if sudo docker image inspect bordergateway >/dev/null 2>&1; then
  sudo docker image rm -f bordergateway
fi

# Step 2: Create necessary directories
echo "Creating directories..."
mkdir -p ~/telecom_network/homegateway
mkdir -p ~/telecom_network/bordergateway
mkdir -p ~/telecom_network/clab-2nodes

# Step 3: Create Dockerfile for homegateway (node1)
echo "Creating Dockerfile for homegateway..."
cat <<EOF > ~/telecom_network/homegateway/Dockerfile
FROM ubuntu:latest

# Update and install necessary packages for PPPoE server and iptables
RUN apt-get update && apt-get install -y \
  ppp \
  pppoe \
  openssh-server \
  iproute2 \
  iputils-ping \
  sudo \
  iptables

# Configure SSH
RUN mkdir /var/run/sshd && echo 'root:acn2024' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Configure PPPoE settings
RUN echo "require-chap" > /etc/ppp/pppoe-server-options && \
    echo "lcp-echo-interval 10" >> /etc/ppp/pppoe-server-options && \
    echo "lcp-echo-failure 2" >> /etc/ppp/pppoe-server-options && \
    echo "ms-dns 8.8.8.8" >> /etc/ppp/pppoe-server-options && \
    echo "netmask 255.255.255.0" >> /etc/ppp/pppoe-server-options && \
    echo "ktune" >> /etc/ppp/pppoe-server-options && \
    echo "proxyarp" >> /etc/ppp/pppoe-server-options && \
    echo "nobsdcomp" >> /etc/ppp/pppoe-server-options && \
    echo "noccp" >> /etc/ppp/pppoe-server-options && \
    echo "novj" >> /etc/ppp/pppoe-server-options && \
    echo "noipx" >> /etc/ppp/pppoe-server-options && \
    echo "ipv6 ::/56" >> /etc/ppp/pppoe-server-options && \
    echo "ipv6 ::/56" >> /etc/ppp/pppoe-server-options

# Configure chap-secrets for PPPoE users
RUN echo "username1 * 1234567890 10.0.0.50" >> /etc/ppp/chap-secrets && \
    echo "username2 * 1234567890 *" >> /etc/ppp/chap-secrets && \
    echo "username3 * 1234567890 10.0.0.200" >> /etc/ppp/chap-secrets

# Setup IP address pool for PPPoE Server
RUN echo "10.0.0.30-10.0.0.253" > /etc/ppp/ipaddress_pool

# Enable IP forwarding (IPv4 and IPv6)
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf && sysctl -p
    
# Create necessary directory for network scripts
RUN mkdir -p /etc/network/if-up.d

# Startup script to run PPPoE server on boot
RUN echo '#!/bin/sh' > /etc/network/if-up.d/my_route && \
    echo 'if [ "$IFACE" = "enp1s0" ]; then' >> /etc/network/if-up.d/my_route && \
    echo '  pppoe-server -C addname -S isp -L 10.0.0.1 -p /etc/ppp/ipaddress_pool -I enp1s0 -m 1412' >> /etc/network/if-up.d/my_route && \
    echo 'fi' >> /etc/network/if-up.d/my_route

RUN chmod +x /etc/network/if-up.d/my_route

# Start services
CMD ["/bin/bash", "-c", "/usr/sbin/sshd -D && tail -f /dev/null"]
EOF

# Step 4: Create Dockerfile for bordergateway (node2)
echo "Creating Dockerfile for bordergateway..."
cat <<EOF > ~/telecom_network/bordergateway/Dockerfile
FROM ubuntu:latest

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
  ppp \
  pppoe \
  openssh-server \
  dnsmasq \
  vnstat \
  sudo \
  iproute2 \
  tcpdump \
  dnsutils \
  iptables

# Configure SSH
RUN mkdir /var/run/sshd && echo 'root:acn2024' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Enable IP forwarding (IPv4 and IPv6)
RUN echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf && sysctl -p

# Configure DNS for local name resolution
RUN echo "address=/mytelecom.local/192.168.1.1" >> /etc/dnsmasq.conf

# Enable and start vnstat service for traffic accounting
RUN systemctl enable vnstat.service

# Start services
CMD ["/bin/bash", "-c", "service ssh start && service dnsmasq start && service vnstat start && tail -f /dev/null"]
EOF

# Step 5: Create the topology YAML file (clab-twonodes.yml)
echo "Creating topology YAML file..."
cat <<EOF > ~/telecom_network/clab-2nodes/clab-twonodes.yml
name: twonodes

topology:
  nodes:
    node1:
      kind: linux
      image: homegateway
    node2:
      kind: linux
      image: bordergateway
  links:
    - endpoints: ["node1:e1-1", "node2:e1-1"]

mgmt:
  ipv4-subnet: 172.20.20.0/24
  ipv6-subnet: 2001:172:20:20::/64
EOF

# Step 6: Build Docker images for homegateway and bordergateway
echo "Building Docker images..."
sudo docker build -t homegateway ~/telecom_network/homegateway
sudo docker build -t bordergateway ~/telecom_network/bordergateway

# Step 7: Deploy the network with Containerlab
echo "Deploying the network with Containerlab..."
sudo containerlab deploy -t ~/telecom_network/clab-2nodes/clab-twonodes.yml

echo "Network deployed. To check status, run:"
echo "  sudo containerlab inspect -t ~/telecom_network/clab-2nodes/clab-twonodes.yml"

echo "To stop and destroy the network, run:"
echo "  sudo containerlab destroy -t ~/telecom_network/clab-2nodes/clab-twonodes.yml"

# Step 8: Apply the saved iptables rules from host
# Ensure DOCKER-USER chain exists
if ! sudo iptables -L DOCKER-USER >/dev/null 2>&1; then
  echo "Creating DOCKER-USER chain..."
  sudo iptables -N DOCKER-USER
  sudo iptables -I DOCKER-USER -j RETURN
fi

# Check if /etc/iptables directory exists and create it if it doesn't
echo "Checking /etc/iptables directory..."
if [ ! -d "/etc/iptables" ]; then
  echo "/etc/iptables directory doesn't exist. Creating it..."
  sudo mkdir -p /etc/iptables
fi

# Copy the iptables rules files if they exist, otherwise print a warning
echo "Copying iptables rules files..."
if [ -f /home/ntn/telecom_network/iptables/ipv4 ]; then
  sudo cp /home/ntn/telecom_network/iptables/ipv4 /etc/iptables/rules.v4
  echo "IPv4 rules copied successfully."
else
  echo "Warning: IPv4 rules file not found. Skipping IPv4 rule application."
fi

if [ -f /home/ntn/telecom_network/iptables/ipv6 ]; then
  sudo cp /home/ntn/telecom_network/iptables/ipv6 /etc/iptables/rules.v6
  echo "IPv6 rules copied successfully."
else
  echo "Warning: IPv6 rules file not found. Skipping IPv6 rule application."
fi

# Apply the saved iptables rules
echo "Applying saved iptables rules..."

# Apply IPv4 rules if the file exists
if [ -f /etc/iptables/rules.v4 ]; then
  sudo iptables-restore < /etc/iptables/rules.v4
  echo "IPv4 rules applied successfully."
else
  echo "Warning: IPv4 rules file not found at /etc/iptables/rules.v4"
fi

# Apply IPv6 rules if the file exists
if [ -f /etc/iptables/rules.v6 ]; then
  sudo ip6tables-restore < /etc/iptables/rules.v6
  echo "IPv6 rules applied successfully."
else
  echo "Warning: IPv6 rules file not found at /etc/iptables/rules.v6"
fi

# Save the iptables rules to make them persistent
echo "Saving iptables rules..."
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6 > /dev/null
echo "Iptables rules saved."

# Ensure iptables INPUT policy is DROP (for IPv4)
sudo iptables -P INPUT DROP

# Ensure ip6tables INPUT policy is DROP (for IPv6)
sudo ip6tables -P INPUT DROP

echo "Script completed successfully."


