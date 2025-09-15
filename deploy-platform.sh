#!/bin/bash
set -euo pipefail

# XCloud Platform Deployment Script
# This script deploys all platform components in the correct order

CLUSTER_TYPE=${1:-prod}  # prod or stg

echo "🚀 Starting XCloud Platform deployment for ${CLUSTER_TYPE} environment..."

# Validate cluster is ready
echo "✅ Validating cluster readiness..."
kubectl cluster-info
kubectl get nodes

# Sprint 3: Verify kube-vip VIP is active
echo "🔍 Checking kube-vip VIP..."
if [ "$CLUSTER_TYPE" = "prod" ]; then
    VIP="192.168.56.200"
else
    VIP="192.168.56.210"
fi

if ping -c 1 "$VIP" >/dev/null 2>&1; then
    echo "✅ VIP $VIP is active"
else
    echo "⚠️  VIP $VIP is not responding, continuing anyway..."
fi

# Sprint 4: Network and Ingress
echo "🌐 Installing network components..."

echo "📦 Installing Cilium CNI..."
/vagrant/platform/cilium/install-cilium.sh

echo "🔧 Installing MetalLB..."
/vagrant/platform/metallb/install-metallb.sh

echo "🚪 Installing NGINX Ingress Controller..."
/vagrant/platform/ingress/install-nginx.sh

echo "🔐 Installing cert-manager..."
/vagrant/platform/cert-manager/install-cert-manager.sh

# Sprint 5: Storage
echo "💾 Installing storage components..."

echo "📀 Installing Longhorn..."
/vagrant/platform/longhorn/install-longhorn.sh

# Sprint 6: Observability
echo "📊 Installing observability stack..."

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "📦 Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "📈 Installing observability components..."
/vagrant/platform/observability/install-observability.sh

# Sprint 7: Security
echo "🔒 Installing security components..."
/vagrant/platform/security/install-security.sh

# Sprint 8: GitOps
echo "🔄 Installing GitOps..."
/vagrant/platform/gitops/install-gitops.sh argocd

# Test echo application
echo "🧪 Deploying test echo application..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-server
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echo-server
  template:
    metadata:
      labels:
        app: echo-server
    spec:
      containers:
      - name: echo-server
        image: ealen/echo-server:latest
        ports:
        - containerPort: 80
        env:
        - name: PORT
          value: "80"
---
apiVersion: v1
kind: Service
metadata:
  name: echo-server
  namespace: default
spec:
  selector:
    app: echo-server
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo-server
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: selfsigned-issuer
spec:
  tls:
  - hosts:
    - echo-${CLUSTER_TYPE}.local
    secretName: echo-server-tls
  rules:
  - host: echo-${CLUSTER_TYPE}.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: echo-server
            port:
              number: 80
EOF

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/echo-server

# Show deployment status
echo "📊 Deployment Summary:"
echo "===================="
kubectl get nodes -o wide
echo ""
kubectl get svc -A | grep -E "(LoadBalancer|ingress-nginx)"
echo ""
kubectl get ingress -A
echo ""
echo "✅ XCloud Platform deployment completed for ${CLUSTER_TYPE} environment!"
echo ""
echo "🌐 Access your services:"
echo "  - Echo server: https://echo-${CLUSTER_TYPE}.local (add to /etc/hosts pointing to LoadBalancer IP)"
echo "  - Longhorn UI: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
echo "  - Cilium Hubble UI: kubectl port-forward -n kube-system svc/hubble-ui 8081:80"
echo "  - Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80 (admin/admin123)"
echo "  - Argo CD: kubectl port-forward -n argocd svc/argocd-server 8082:443"
echo ""
echo "🔧 Next steps:"
echo "1. Configure your /etc/hosts file with the LoadBalancer IP"
echo "2. Set up GitOps applications in Argo CD"
echo "3. Configure monitoring alerts"
echo "4. Review security policies"