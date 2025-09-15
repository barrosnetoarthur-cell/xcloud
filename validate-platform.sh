#!/bin/bash
set -euo pipefail

# XCloud Platform Validation Script
CLUSTER_TYPE=${1:-prod}

echo "🔍 Validating XCloud Platform deployment for ${CLUSTER_TYPE} environment..."

# Function to check if a resource exists and is ready
check_resource() {
    local resource=$1
    local namespace=${2:-default}
    local timeout=${3:-60}
    
    echo "  Checking $resource in namespace $namespace..."
    if kubectl get $resource -n $namespace &>/dev/null; then
        if kubectl wait --for=condition=ready $resource -n $namespace --timeout=${timeout}s &>/dev/null; then
            echo "  ✅ $resource is ready"
            return 0
        else
            echo "  ⚠️  $resource exists but not ready"
            return 1
        fi
    else
        echo "  ❌ $resource not found"
        return 1
    fi
}

# Function to check service availability
check_service() {
    local service=$1
    local namespace=${2:-default}
    local port=${3:-80}
    
    echo "  Checking service $service in namespace $namespace..."
    if kubectl get svc $service -n $namespace &>/dev/null; then
        local service_ip=$(kubectl get svc $service -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$service_ip" ]; then
            echo "  ✅ Service $service has LoadBalancer IP: $service_ip"
            return 0
        else
            echo "  ⚠️  Service $service exists but no LoadBalancer IP assigned"
            return 1
        fi
    else
        echo "  ❌ Service $service not found"
        return 1
    fi
}

echo ""
echo "📋 Cluster Health Check"
echo "======================"

# Check cluster nodes
echo "🖥️  Cluster Nodes:"
kubectl get nodes -o wide
echo ""

# Check VIP connectivity
if [ "$CLUSTER_TYPE" = "prod" ]; then
    VIP="192.168.56.200"
else
    VIP="192.168.56.210"
fi

echo "🌐 Testing VIP connectivity..."
if ping -c 1 -W 3 "$VIP" >/dev/null 2>&1; then
    echo "  ✅ VIP $VIP is responding"
else
    echo "  ⚠️  VIP $VIP is not responding"
fi
echo ""

echo "🔧 Core Components"
echo "=================="

# Check kube-vip
check_resource "pod/kube-vip" "kube-system"

# Check CNI (Cilium)
echo "🕸️  Cilium CNI:"
if kubectl get pods -n kube-system -l k8s-app=cilium &>/dev/null; then
    echo "  ✅ Cilium pods found"
    kubectl get pods -n kube-system -l k8s-app=cilium --no-headers | wc -l | xargs echo "  📊 Number of Cilium pods:"
else
    echo "  ❌ Cilium pods not found"
fi
echo ""

# Check MetalLB
echo "⚖️  MetalLB Load Balancer:"
check_resource "pod" "metallb-system" 60
echo ""

# Check NGINX Ingress
echo "🚪 NGINX Ingress Controller:"
check_resource "pod" "ingress-nginx" 60
check_service "ingress-nginx-controller" "ingress-nginx"
echo ""

# Check cert-manager
echo "🔐 cert-manager:"
check_resource "pod" "cert-manager" 60
echo ""

# Check Longhorn
echo "💾 Longhorn Storage:"
if kubectl get ns longhorn-system &>/dev/null; then
    check_resource "pod" "longhorn-system" 120
    echo "  📊 Longhorn nodes:"
    kubectl get nodes.longhorn.io -n longhorn-system --no-headers 2>/dev/null | wc -l | xargs echo "    Nodes:"
else
    echo "  ❌ Longhorn namespace not found"
fi
echo ""

# Check Observability
echo "📊 Observability Stack:"
if kubectl get ns monitoring &>/dev/null; then
    echo "  🔍 Prometheus:"
    check_resource "pod" "monitoring" 120
    echo "  📈 Grafana:"
    kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | wc -l | xargs echo "    Pods:"
else
    echo "  ❌ Monitoring namespace not found"
fi
echo ""

# Check Security
echo "🔒 Security Components:"
if kubectl get ns external-secrets-system &>/dev/null; then
    echo "  🔑 External Secrets Operator:"
    check_resource "pod" "external-secrets-system" 60
else
    echo "  ❌ External Secrets Operator not found"
fi

if kubectl get ns kyverno &>/dev/null; then
    echo "  📋 Kyverno:"
    check_resource "pod" "kyverno" 60
else
    echo "  ❌ Kyverno not found"
fi
echo ""

# Check GitOps
echo "🔄 GitOps:"
if kubectl get ns argocd &>/dev/null; then
    echo "  🚀 Argo CD:"
    check_resource "pod" "argocd" 120
else
    echo "  ❌ Argo CD not found"
fi
echo ""

# Check Test Application
echo "🧪 Test Applications"
echo "==================="
echo "📱 Echo Server:"
if kubectl get deployment echo-server &>/dev/null; then
    check_resource "deployment/echo-server" "default" 60
    if kubectl get ingress echo-server &>/dev/null; then
        echo "  🌐 Ingress configured"
        local ingress_host=$(kubectl get ingress echo-server -o jsonpath='{.spec.rules[0].host}')
        echo "    Host: $ingress_host"
    else
        echo "  ⚠️  Ingress not found"
    fi
else
    echo "  ❌ Echo server deployment not found"
fi
echo ""

# Storage Class Check
echo "💽 Storage Classes:"
kubectl get storageclass
echo ""

# PVC Check
echo "📁 Persistent Volume Claims:"
kubectl get pvc -A
echo ""

# LoadBalancer Services Summary
echo "⚖️  LoadBalancer Services:"
kubectl get svc -A --field-selector spec.type=LoadBalancer
echo ""

# Network Policies
echo "🛡️  Network Policies:"
kubectl get networkpolicy -A
echo ""

# Final Summary
echo "📊 VALIDATION SUMMARY"
echo "===================="

# Count running pods by namespace
echo "Pod Status by Namespace:"
kubectl get pods -A --no-headers | awk '{print $1}' | sort | uniq -c | while read count namespace; do
    echo "  $namespace: $count pods"
done
echo ""

# Check if all nodes are ready
ready_nodes=$(kubectl get nodes --no-headers | grep -c Ready)
total_nodes=$(kubectl get nodes --no-headers | wc -l)
echo "Nodes Ready: $ready_nodes/$total_nodes"

# Check critical services
critical_services=(
    "kube-system:coredns"
    "kube-system:kube-vip"
    "metallb-system:controller"
    "ingress-nginx:controller"
    "cert-manager:cert-manager"
)

echo ""
echo "Critical Services Status:"
for service in "${critical_services[@]}"; do
    IFS=':' read -r namespace name <<< "$service"
    if kubectl get pods -n "$namespace" -l "app=$name" &>/dev/null || kubectl get pods -n "$namespace" -l "app.kubernetes.io/name=$name" &>/dev/null; then
        echo "  ✅ $service"
    else
        echo "  ❌ $service"
    fi
done

echo ""
echo "🎉 Validation completed!"
echo ""
echo "💡 To access services locally:"
echo "   kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
echo "   kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80" 
echo "   kubectl port-forward -n argocd svc/argocd-server 8082:443"