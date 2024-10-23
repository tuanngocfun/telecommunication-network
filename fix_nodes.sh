#!/bin/bash

# Define the password
PASSWORD="acn2024"

echo "Fixing issues on Node 1 (homegateway)..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@clab-twonodes-node1 'bash -s' < fix_node1.sh

echo "Fixing issues on Node 2 (bordergateway)..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@clab-twonodes-node2 'bash -s' < fix_node2.sh

echo "Verification and fixing script executed for both nodes."

