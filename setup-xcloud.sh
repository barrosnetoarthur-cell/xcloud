#!/bin/bash
set -euo pipefail

# XCloud Complete Environment Setup Script
# This script automates the entire platform deployment process

ENVIRONMENT=${1:-both}  # prod, stg, or both
DRY_RUN=${2:-false}     # true for dry run

echo "🚀 XCloud Complete Environment Setup"
echo "===================================="
echo "Environment: $ENVIRONMENT"
echo "Dry Run: $DRY_RUN"
echo ""

# Functions
log_step() {
    echo ""
    echo "📍 STEP: $1"
    echo "----------------------------------------"
}

execute_command() {
    local cmd="$1"
    local description="$2"
    
    echo "🔧 $description"
    if [ "$DRY_RUN" = "true" ]; then
        echo "   [DRY RUN] Would execute: $cmd"
    else
        echo "   Executing: $cmd"
        eval "$cmd"
    fi
}

check_prerequisites() {
    log_step "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command -v vagrant &> /dev/null; then
        missing_tools+=("vagrant")
    fi
    
    if ! command -v VBoxManage &> /dev/null; then
        missing_tools+=("virtualbox")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "❌ Missing required tools: ${missing_tools[*]}"
        echo "Please install missing tools and try again."
        exit 1
    fi
    
    echo "✅ All prerequisites met"
}

deploy_vms() {
    log_step "Deploying Virtual Machines"
    
    # Check current VM status
    execute_command "vagrant status" "Checking current VM status"
    
    # Deploy VMs
    if [ "$ENVIRONMENT" = "prod" ]; then
        execute_command "vagrant up prod-cp1 prod-w1" "Deploying PROD VMs"
    elif [ "$ENVIRONMENT" = "stg" ]; then
        execute_command "vagrant up stg-cp1 stg-w1" "Deploying STG VMs"
    else
        execute_command "vagrant up" "Deploying all VMs"
    fi
    
    # Verify VMs are running
    execute_command "vagrant status" "Verifying VM status"
}

deploy_platform() {
    local env=$1
    log_step "Deploying Platform Components for $env"
    
    local control_plane=""
    if [ "$env" = "prod" ]; then
        control_plane="prod-cp1"
    else
        control_plane="stg-cp1"
    fi
    
    execute_command "vagrant ssh $control_plane -c 'sudo /vagrant/deploy-platform.sh $env'" "Deploying $env platform"
}

validate_deployment() {
    local env=$1
    log_step "Validating $env Deployment"
    
    local control_plane=""
    if [ "$env" = "prod" ]; then
        control_plane="prod-cp1"
    else
        control_plane="stg-cp1"
    fi
    
    execute_command "vagrant ssh $control_plane -c 'sudo /vagrant/validate-platform.sh $env'" "Validating $env deployment"
}

configure_gitops() {
    log_step "Configuring GitOps Applications"
    
    if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "both" ]; then
        execute_command "vagrant ssh prod-cp1 -c 'kubectl apply -f /vagrant/platform/gitops/argocd-app-prod.yaml'" "Configuring PROD GitOps"
    fi
    
    if [ "$ENVIRONMENT" = "stg" ] || [ "$ENVIRONMENT" = "both" ]; then
        execute_command "vagrant ssh stg-cp1 -c 'kubectl apply -f /vagrant/platform/gitops/argocd-app-stg.yaml'" "Configuring STG GitOps"
    fi
}

generate_access_info() {
    log_step "Generating Access Information"
    
    echo "🌐 Service Access Information"
    echo "============================"
    
    if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "both" ]; then
        echo ""
        echo "🏭 PRODUCTION Environment:"
        if [ "$DRY_RUN" = "false" ]; then
            local prod_lb_ip=$(vagrant ssh prod-cp1 -c "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || echo "pending")
            echo "  LoadBalancer IP: $prod_lb_ip"
            echo "  Add to /etc/hosts: $prod_lb_ip echo-prod.local"
        fi
        echo "  Echo App: https://echo-prod.local"
        echo "  VIP: 192.168.56.200"
    fi
    
    if [ "$ENVIRONMENT" = "stg" ] || [ "$ENVIRONMENT" = "both" ]; then
        echo ""
        echo "🧪 STAGING Environment:"
        if [ "$DRY_RUN" = "false" ]; then
            local stg_lb_ip=$(vagrant ssh stg-cp1 -c "kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" 2>/dev/null || echo "pending")
            echo "  LoadBalancer IP: $stg_lb_ip"
            echo "  Add to /etc/hosts: $stg_lb_ip echo-stg.local"
        fi
        echo "  Echo App: https://echo-stg.local"
        echo "  VIP: 192.168.56.210"
    fi
    
    echo ""
    echo "🔧 Management Dashboards (Port Forward Commands):"
    echo "  Grafana:    kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
    echo "  Longhorn:   kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
    echo "  Argo CD:    kubectl port-forward -n argocd svc/argocd-server 8082:443"
    echo "  Hubble UI:  kubectl port-forward -n kube-system svc/hubble-ui 8081:80"
    echo ""
    echo "📋 Default Credentials:"
    echo "  Grafana: admin / admin123"
    if [ "$DRY_RUN" = "false" ]; then
        if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "both" ]; then
            local argocd_password=$(vagrant ssh prod-cp1 -c "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" 2>/dev/null || echo "check cluster")
            echo "  Argo CD: admin / $argocd_password"
        fi
    fi
}

# Main execution flow
main() {
    echo "🚀 Starting XCloud complete deployment..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Deploy VMs
    deploy_vms
    
    # Deploy platform components
    if [ "$ENVIRONMENT" = "prod" ] || [ "$ENVIRONMENT" = "both" ]; then
        deploy_platform "prod"
        validate_deployment "prod"
    fi
    
    if [ "$ENVIRONMENT" = "stg" ] || [ "$ENVIRONMENT" = "both" ]; then
        deploy_platform "stg"
        validate_deployment "stg"
    fi
    
    # Configure GitOps
    configure_gitops
    
    # Generate access information
    generate_access_info
    
    log_step "Deployment Complete!"
    echo "✅ XCloud platform deployment completed successfully!"
    echo ""
    echo "📚 Next Steps:"
    echo "1. Review the validation output above"
    echo "2. Configure your /etc/hosts file with the LoadBalancer IPs"
    echo "3. Access the applications and dashboards"
    echo "4. Set up monitoring alerts in Grafana"
    echo "5. Configure GitOps applications in Argo CD"
    echo ""
    echo "📖 Documentation: See DEPLOYMENT.md for detailed instructions"
    echo "🐛 Troubleshooting: Run ./validate-platform.sh <env> for diagnostics"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [ENVIRONMENT] [DRY_RUN]"
        echo ""
        echo "ENVIRONMENT:"
        echo "  prod    Deploy only production environment"
        echo "  stg     Deploy only staging environment"
        echo "  both    Deploy both environments (default)"
        echo ""
        echo "DRY_RUN:"
        echo "  true    Show commands without executing"
        echo "  false   Execute commands (default)"
        echo ""
        echo "Examples:"
        echo "  $0                    # Deploy both environments"
        echo "  $0 prod               # Deploy only production"
        echo "  $0 both true         # Dry run for both environments"
        exit 0
        ;;
    *)
        main
        ;;
esac