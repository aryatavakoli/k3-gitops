#!/bin/bash

# Generic IP addresses and hostnames
NODE_IPS=("192.168.1.73" "192.168.1.74" "192.168.1.76" "192.168.1.77")
NODE_HOSTNAMES=("k3s-node0" "k3s-node1" "k3s-node2" "k3s-node3")
NODE_NETMASK="255.255.255.0"
NODE_GATEWAY="192.168.1.254"
NODE_DNS=("192.168.1.254" "8.8.8.8" "8.8.4.4")

# Get the IP address of the DNS server
# dns_ip=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
#dns_ip=${NODE_DNS[0]}

# Query the DNS server for the domain name
#DOMAIN=$(dig +short -x $dns_ip | sed 's/\.$//')

DOMAIN=""
LOGIN_USER="ubuntu"

# Set hostname, domain, and static IP on each node
for i in "${!NODE_IPS[@]}"; do
  NODE_IP=${NODE_IPS[$i]}
  NODE_HOSTNAME=${NODE_HOSTNAMES[$i]}
  NODE_DNS="${NODE_DNS[@]}"
  
  ssh $LOGIN_USER@$NODE_IP "sudo echo '127.0.0.1 localhost' > /etc/hosts &&
                      sudo echo '$NODE_IP $NODE_HOSTNAME.$DOMAIN $NODE_HOSTNAME' | sudo tee -a /etc/hosts &&
                      sudo echo $NODE_HOSTNAME > /etc/hostname &&
                      sudo echo $DOMAIN > /etc/domainname &&
                      sudo cat <<EOT >> /etc/network/interfaces
auto eth0
iface eth0 inet static
address $NODE_IP
netmask $NODE_NETMASK
gateway $NODE_GATEWAY
dns-nameservers $NODE_DNS
EOT"
done

# Create a new user on each node to run k3s
K3S_USER="k3s"
SSH_PATH="$HOME/.ssh/id_ed25519.pub"
for NODE_DNS in "${NODE_HOSTNAMES[@]/%/$DOMAIN}"; do
  ssh $LOGIN_USER@$NODE_IP "sudo useradd -m -s /bin/bash $K3S_USER && sudo echo '$K3S_USER ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/$K3S_USER"
  ssh-copy-id -i $SSH_PATH $K3S_USER@$NODE_DNS
done

# Install k3s on each node
ssh $K3S_USER@${NODE_IPS[0]} "curl -sfL https://get.k3s.io | sh -s - server --disable=traefik,servicelb --flannel-backend=none --disable-network-policy --cluster-init"
TOKEN=$(ssh $K3S_USER@${NODE_IPS[0]} "sudo cat /var/lib/rancher/k3s/server/node-token")
for NODE_IP in "${NODE_IPS[@]:1}"; do
  ssh $K3S_USER@$NODE_IP "echo $TOKEN && hostname && curl -sfL https://get.k3s.io | K3S_URL=https://${NODE_IPS[0]}:6443 K3S_TOKEN=$TOKEN sh -s - agent"
done
