#!/bin/bash
set -euo pipefail

echo "Installing MetalLB..."

# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
echo "Waiting for MetalLB to be ready..."
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Apply IP pools based on environment
if kubectl get nodes | grep -q "prod-"; then
  echo "Applying PROD MetalLB configuration..."
  kubectl apply -f /vagrant/platform/metallb/prod-pool.yaml
fi

if kubectl get nodes | grep -q "stg-"; then
  echo "Applying STG MetalLB configuration..."
  kubectl apply -f /vagrant/platform/metallb/stg-pool.yaml
fi

echo "MetalLB installation completed!"