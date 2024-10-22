#!/bin/bash

# Define the password
PASSWORD="acn2024"

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null
then
    echo "sshpass is not installed. Installing it now..."
    # Install sshpass based on the system package manager
    if [ -f /etc/debian_version ]; then
        # For Debian-based systems
        sudo apt-get update && sudo apt-get install -y sshpass
    elif [ -f /etc/redhat-release ]; then
        # For Red Hat-based systems
        sudo dnf install -y sshpass
    elif [ -f /etc/arch-release ]; then
        # For Arch-based systems
        sudo pacman -S --noconfirm sshpass
    else
        echo "Unsupported system. Please install sshpass manually."
        exit 1
    fi
fi

# Append the output of check_node2.sh
sshpass -p "$PASSWORD" ssh root@clab-twonodes-node2 'bash -s' < check_node2.sh >> status_check.txt

# Append two empty lines
echo -e "\n\n" >> status_check.txt

# Append the output of check_node1.sh
sshpass -p "$PASSWORD" ssh root@clab-twonodes-node1 'bash -s' < check_node1.sh >> status_check.txt

