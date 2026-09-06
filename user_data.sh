#!/bin/bash
# 1. Update system and install prerequisites
apt-get update -y
apt-get install -y ca-certificates curl apt-transport-https

# 2. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
usermod -aG docker ssm-user

# 3. Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# 4. Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

# 5. Wait for Docker daemon to be fully ready
until docker info >/dev/null 2>&1; do sleep 2; done

# 6. Create the kind cluster
kind create cluster

# 7. Set up kubeconfig for the 'ubuntu' user so it works immediately upon login
mkdir -p /home/ubuntu/.kube
kind get kubeconfig > /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube