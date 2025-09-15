#!/bin/bash
set -euo pipefail

GITOPS_TOOL=${1:-argocd}  # argocd or flux

echo "Installing GitOps tool: $GITOPS_TOOL"

if [ "$GITOPS_TOOL" = "argocd" ]; then
    echo "Installing Argo CD..."
    
    # Install Argo CD
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for Argo CD to be ready
    kubectl wait --namespace argocd \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/name=argocd-server \
      --timeout=300s
    
    # Get initial admin password
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo "Argo CD installation completed!"
    echo "Access Argo CD at: kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo "Username: admin"
    echo "Password: $ARGOCD_PASSWORD"
    
elif [ "$GITOPS_TOOL" = "flux" ]; then
    echo "Installing Flux..."
    
    # Install Flux CLI
    curl -s https://fluxcd.io/install.sh | sudo bash
    
    # Install Flux components
    flux install
    
    echo "Flux installation completed!"
    echo "Configure Flux with: flux bootstrap github --owner=<user> --repository=<repo>"
fi