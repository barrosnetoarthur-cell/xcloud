#!/bin/bash
set -euo pipefail

echo "Installing NGINX Ingress Controller..."

# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml

# Wait for NGINX Ingress Controller to be ready
echo "Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Get LoadBalancer IP
echo "NGINX Ingress Controller installed successfully!"
echo "LoadBalancer service status:"
kubectl get svc -n ingress-nginx ingress-nginx-controller

echo "Installation completed!"