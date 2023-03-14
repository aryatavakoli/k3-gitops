#!/bin/bash

# Generic IP addresses and hostnames
NODE_IPS=("192.168.1.73" "192.168.1.74" "192.168.1.76" "192.168.1.77")
K3S_USER="ubuntu"

# Install k3s on each node
ssh $K3S_USER@${NODE_IPS[0]} "curl -sfL https://get.k3s.io | sh -s - server"
TOKEN=$(ssh $K3S_USER@${NODE_IPS[0]} "sudo cat /var/lib/rancher/k3s/server/node-token")
for NODE_IP in "${NODE_IPS[@]:1}"; do
  ssh $K3S_USER@$NODE_IP "echo $TOKEN && hostname && curl -sfL https://get.k3s.io | K3S_URL=https://${NODE_IPS[0]}:6443 K3S_TOKEN=$TOKEN sh -s - agent"
done