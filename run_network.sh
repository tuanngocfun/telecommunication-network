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

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
  openssh-server \
  iproute2 \
  ppp \
  pppoe \
  pppoeconf \
  sudo \
  kmod \
  iputils-ping

# Backup important configuration files before running pppoeconf
RUN mkdir -p ~/pppoe_backup && \
    cp /etc/ppp/peers/dsl-provider ~/pppoe_backup/dsl-provider.bak && \
    cp /etc/network/interfaces ~/pppoe_backup/interfaces.bak && \
    cp /etc/ppp/*-secrets ~/pppoe_backup/

# Configure SSH
RUN mkdir /var/run/sshd && echo 'root:acn2024' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Run SSHD and PPPoE configuration
CMD ["/bin/bash", "-c", "/usr/sbin/sshd -D & pppoeconf --noact"]
EOF

# Step 4: Create Dockerfile for bordergateway (node2)
echo "Creating Dockerfile for bordergateway..."
cat <<EOF > ~/telecom_network/bordergateway/Dockerfile
FROM ubuntu:latest

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
  openssh-server \
  iproute2 \
  dnsmasq \
  ppp \
  vnstat \
  tcpdump \
  sudo \
  dnsutils

# Configure SSH
RUN mkdir /var/run/sshd && echo 'root:acn2024' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Set up PPPoE and DNS
RUN echo 'require-chap\nnoauth\nmtu 1492\nmru 1492\n' > /etc/ppp/pppoe-server-options && \
    echo 'localip 192.168.1.1\nremoteip 192.168.1.2-192.168.1.254\nipv6 ::/56' >> /etc/ppp/pppoe-server-options && \
    echo 'lecturer * password *' > /etc/ppp/chap-secrets && \
    echo 'address=/mytelecom.local/192.168.1.1' >> /etc/dnsmasq.conf

# Enable and start vnstat service
RUN systemctl enable vnstat.service

# Start SSH, DNS, and vnStat
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

