#!/bin/bash
sudo docker exec clab-twonodes-node2 iptables -A FORWARD -i eth0 -o e1-1 -j ACCEPT
sudo docker exec clab-twonodes-node2 iptables -A FORWARD -i e1-1 -o eth0 -j ACCEPT

