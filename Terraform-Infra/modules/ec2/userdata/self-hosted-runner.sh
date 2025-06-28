#!/bin/bash

# Exit immediately if any command fails
set -e

export DEBIAN_FRONTEND=noninteractive

sudo apt update -y
sudo apt install wget -y
# Install Java 
sudo apt install openjdk-17-jdk -y

# ---------------------------------------------------------------------------------
# Install Docker

sudo apt install docker.io -y
# sudo chmod 777 /var/run/docker.sock

# Create dedicated docker user (optional)
if ! id "dockeruser" &>/dev/null; then
  sudo useradd -m -s /bin/bash dockeruser
  echo "Created 'dockeruser' account"
fi

# Add users to docker group
sudo groupadd docker 2>/dev/null || true  # Ignore if group exists
for user in "$USER" dockeruser; do
  if id "$user" &>/dev/null; then
    sudo usermod -aG docker "$user"
    echo "Added $user to docker group"
  fi
done

sudo usermod -aG docker ubuntu
# Restart Docker service
sudo systemctl restart docker
# ---------------------------------------------------------------------------------


# Git and maven install

sudo apt install git maven -y

# Install required packages
sudo apt-get install -y curl unzip jq

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

echo "AWS CLI installed successfully"

echo "Installing kubectl..."

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

# Verify AWS CLI installation
aws --version || { echo "AWS CLI installation failed"; exit 1; }  

# Configure AWS CLI
aws configure set region ${aws_region}

# Trivy installation

echo "Installing Trivy..."

sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y

# Argocd CLI installation
echo "Installing ArgoCD CLI..."
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

echo "Waiting for Argocd to warmup..."
sleep 30  # Adjust as necessary for your environment

# ---------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------
# Wait for EKS cluster to be active
for i in {1..30}; do
  if aws eks describe-cluster --name ${eks_cluster_name} --query "cluster.status" | grep -q "ACTIVE"; then
    echo "EKS cluster is active"
    break
  fi
  echo "Waiting for EKS cluster to become active..."
  sleep 10
done
# Verify Docker installation
docker_status=$(systemctl is-active docker)
if [ "$docker_status" = "active" ]; then
  echo "Docker is running"
else
  echo "Docker is not running. Status: $docker_status"
  exit 1
fi

# Verify AWS CLI installation
aws_status=$(aws sts get-caller-identity 2>&1)
if [[ $aws_status == *"AccessDenied"* ]]; then
  echo "AWS CLI is not configured correctly. Status: $aws_status"
  exit 1
else
  echo "AWS CLI is configured correctly"
fi

# Verify kubectl installation
kubectl_status=$(kubectl version --client 2>&1)
if [[ $kubectl_status == *"Client Version"* ]]; then
  echo "kubectl is installed correctly"
else
  echo "kubectl installation failed. Status: $kubectl_status"
  exit 1
fi

# Verify Trivy installation
trivy_status=$(trivy --version 2>&1)
if [[ $trivy_status == *"Version"* ]]; then
  echo "Trivy is installed correctly"
else
  echo "Trivy installation failed. Status: $trivy_status"
  exit 1
fi
# ---------------------------------------------------------------------------------

# Update kubeconfig
aws eks update-kubeconfig --region ${aws_region} --name ${eks_cluster_name}

# Copy kubeconfig to ubuntu user's home

sudo mkdir -p /home/ubuntu/.kube
sudo cp -i /root/.kube/config /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Optional: verify
sudo -u ubuntu kubectl get nodes

# ---------------------------------------------------------------------------------

# Verify installations

echo "=== 🚀 INSTALLATION VERIFICATION ==="

echo "🐳 Docker Version:"
docker --version || echo "❌ Docker not found"

echo "☕ Java Version:"
java --version || echo "❌ Java not found"

echo "📦 Maven Version:"
mvn --version || echo "❌ Maven not found"

echo "🌿 Git Version:"
git --version || echo "❌ Git not found"

echo "🛠️ AWS CLI Version:"
aws --version || echo "❌ AWS CLI not found"

echo "☸️ kubectl Version:"
kubectl version --client || echo "❌ kubectl not found"

echo "🔍 Trivy Version:"
trivy --version || echo "❌ Trivy not found"

echo "🔍 Argocd Version"
argocd version --client || echo "❌ argocd not found"


# ---------------------------------------------------------------------------------

echo "All packages installed successfully!"