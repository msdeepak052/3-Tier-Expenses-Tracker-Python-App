#!/bin/bash

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y curl unzip jq

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl (official method)
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Cleanup
rm -rf aws awscliv2.zip kubectl

# Configure AWS CLI for root user (automated)
mkdir -p /root/.aws

cat <<EOF > /root/.aws/config
[default]
region = ${aws_region}
output = json
EOF

# Configure AWS CLI
aws configure set region ${aws_region}

# Wait for cluster to be active
for i in {1..30}; do
  if aws eks describe-cluster --name ${eks_cluster_name} --query "cluster.status" | grep -q "ACTIVE"; then
    break
  fi
  sleep 10
done



# Update kubeconfig
aws eks update-kubeconfig --region ${aws_region} --name ${eks_cluster_name}

# Copy kubeconfig to ubuntu user's home

sudo mkdir -p /home/ubuntu/.kube
sudo cp -i /root/.kube/config /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Create .kube directory for jenkins user
sudo mkdir -p /var/lib/jenkins/.kube

# Copy kubeconfig from root to jenkins home
sudo cp -i /root/.kube/config /var/lib/jenkins/.kube/config

# Set ownership to jenkins user
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config

# (Optional) Test as jenkins user
sudo -u jenkins kubectl get nodes

# Optional: verify
sudo -u ubuntu kubectl get nodes
