#!/bin/bash

# Generic IP addresses and hostnames
NODE_IPS=("192.168.1.101" "192.168.1.102" "192.168.1.103" "192.168.1.104")
NODE_HOSTNAMES=("k3s-master" "k3s-worker-1" "k3s-worker-2" "k3s-worker-3")
NODE_NETMASK="255.255.255.0"
NODE_GATEWAY="192.168.1.254"
NODE_DNS=("8.8.8.8" "8.8.4.4")

# Get the IP address of the DNS server
dns_ip=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

# Query the DNS server for the domain name
DOMAIN=$(dig +short -x $dns_ip | sed 's/\.$//')

# Set hostname, domain, and static IP on each node
for i in "${!NODE_IPS[@]}"; do
  NODE_IP=${NODE_IPS[$i]}
  NODE_HOSTNAME=${NODE_HOSTNAMES[$i]}
  NODE_DNS="${NODE_DNS[@]}"
  
  ssh root@$NODE_IP "echo '127.0.0.1 localhost' > /etc/hosts &&
                      echo '$NODE_IP $NODE_HOSTNAME.$DOMAIN $NODE_HOSTNAME' | tee -a /etc/hosts &&
                      echo $NODE_HOSTNAME > /etc/hostname &&
                      echo $DOMAIN > /etc/domainname &&
                      cat <<EOT >> /etc/network/interfaces
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
for NODE_IP in "${NODE_IPS[@]}"; do
  ssh root@$NODE_IP "useradd -m -s /bin/bash $K3S_USER && echo '$K3S_USER ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/$K3S_USER"
done

# Copy public key to each node
for NODE_DNS in "${NODE_HOSTNAMES[@]/%/$DOMAIN}"; do
  ssh-copy-id -i $HOME/.ssh/id_rsa.pub $K3S_USER@$NODE_DNS
done

# Install k3s on each node
ssh $K3S_USER@${NODE_HOSTNAMES[0]}.$DOMAIN "curl -sfL https://get.k3s.io | sh -s - server"
TOKEN=$(ssh $K3S_USER@${NODE_HOSTNAMES[0]}.$DOMAIN "cat /var/lib/rancher/k3s/server/node-token")
for NODE_DNS in "${NODE_HOSTNAMES[@]:1}"; do
  ssh $K3S_USER@$NODE_DNS.$DOMAIN "curl -sfL https://get.k3s.io | K3S_URL=https://${NODE_HOSTNAMES[0]}.$DOMAIN:6443 K3S_TOKEN=$TOKEN sh -s - agent"
done