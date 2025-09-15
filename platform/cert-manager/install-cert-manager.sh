#!/bin/bash
set -euo pipefail

echo "Installing cert-manager..."

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=cert-manager \
  --timeout=120s

# Apply ClusterIssuers
echo "Applying ClusterIssuers..."
kubectl apply -f /vagrant/platform/cert-manager/cluster-issuers.yaml

echo "cert-manager installation completed!"