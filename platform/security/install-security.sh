#!/bin/bash
set -euo pipefail

echo "Installing security components..."

# Install External Secrets Operator
echo "Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace

# Install Kyverno for policy enforcement
echo "Installing Kyverno..."
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set admissionController.replicas=3

# Apply basic security policies
echo "Applying security policies..."
kubectl apply -f /vagrant/platform/security/pod-security-policies.yaml
kubectl apply -f /vagrant/platform/networkpolicies/

# Wait for components to be ready
echo "Waiting for security components to be ready..."
kubectl wait --namespace external-secrets-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=external-secrets \
  --timeout=120s

kubectl wait --namespace kyverno \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=kyverno \
  --timeout=120s

echo "Security components installation completed!"