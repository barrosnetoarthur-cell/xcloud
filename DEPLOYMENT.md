# XCloud Platform Deployment Guide

## Quick Start

This guide will help you deploy the complete XCloud Kubernetes platform in both PROD and STG environments.

### Prerequisites

- VirtualBox installed
- Vagrant installed
- At least 16GB RAM and 8 CPU cores available
- 100GB+ free disk space

### 1. Deploy VMs

```bash
# Clone the repository
git clone https://github.com/barrosnetoarthur-cell/xcloud.git
cd xcloud

# Deploy all VMs
vagrant up

# Verify VMs are running
vagrant status
```

### 2. Deploy Platform Components

```bash
# Deploy PROD platform
vagrant ssh prod-cp1 -c "sudo /vagrant/deploy-platform.sh prod"

# Deploy STG platform
vagrant ssh stg-cp1 -c "sudo /vagrant/deploy-platform.sh stg"
```

### 3. Access Services

#### From Host Machine

Add to your `/etc/hosts` (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
192.168.56.220  echo-prod.local
192.168.56.240  echo-stg.local
```

#### Access Applications

- **Echo PROD**: https://echo-prod.local
- **Echo STG**: https://echo-stg.local

#### Access Dashboards

```bash
# Grafana (monitoring)
vagrant ssh prod-cp1 -c "kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
# Access: http://localhost:3000 (admin/admin123)

# Longhorn (storage)
vagrant ssh prod-cp1 -c "kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
# Access: http://localhost:8080

# Argo CD (GitOps)
vagrant ssh prod-cp1 -c "kubectl port-forward -n argocd svc/argocd-server 8081:443"
# Access: https://localhost:8081 (admin/<password>)
```

## Architecture Overview

### VM Layout

| VM | Role | CPU | RAM | IP | Purpose |
|----|------|-----|-----|----|----|
| prod-cp1 | Control Plane | 2 | 4GB | 192.168.56.101 | PROD k3s server |
| prod-w1 | Worker | 4 | 8GB | 192.168.56.111 | PROD workloads |
| stg-cp1 | Control Plane | 2 | 4GB | 192.168.56.121 | STG k3s server |
| stg-w1 | Worker | 4 | 6GB | 192.168.56.122 | STG workloads |

### Network Configuration

- **VIP PROD**: 192.168.56.200 (kube-vip)
- **VIP STG**: 192.168.56.210 (kube-vip)
- **MetalLB PROD**: 192.168.56.220-239
- **MetalLB STG**: 192.168.56.240-249

### Platform Components

- **CNI**: Cilium with NetworkPolicies
- **Ingress**: NGINX Ingress Controller
- **Certificates**: cert-manager with Let's Encrypt
- **Storage**: Longhorn (distributed storage)
- **Load Balancer**: MetalLB
- **Monitoring**: Prometheus + Grafana + Loki
- **GitOps**: Argo CD
- **Security**: Kyverno policies + External Secrets

## Troubleshooting

### VM Issues

```bash
# Check VM status
vagrant status

# Restart a specific VM
vagrant reload prod-cp1 --provision

# SSH into a VM
vagrant ssh prod-cp1
```

### Cluster Issues

```bash
# Check cluster status
vagrant ssh prod-cp1 -c "kubectl get nodes -o wide"

# Check pod status
vagrant ssh prod-cp1 -c "kubectl get pods -A"

# Check service status
vagrant ssh prod-cp1 -c "kubectl get svc -A"
```

### Network Issues

```bash
# Test VIP connectivity
ping 192.168.56.200  # PROD VIP
ping 192.168.56.210  # STG VIP

# Check MetalLB status
vagrant ssh prod-cp1 -c "kubectl get svc -n ingress-nginx"
```

## Customization

### Modify VM Resources

Edit `Vagrantfile` and adjust CPU/memory for your environment:

```ruby
{name: 'prod-cp1', cpus: 4, mem: 8192, ip: '192.168.56.101', k3s_role: 'server', k3s_vip: '192.168.56.200'},
```

### Add More Workers

Add to the `agents` array in `Vagrantfile`:

```ruby
{name: 'prod-w2', cpus: 4, mem: 8192, ip: '192.168.56.112', k3s_role: 'agent', k3s_server_ip: '192.168.56.101', disks: [200]},
```

### Change IP Ranges

Update IP addresses in:
- `Vagrantfile` (VM IPs)
- `platform/kube-vip/kube-vip.yaml` (VIP addresses)
- `platform/metallb/*.yaml` (LoadBalancer pools)

## Production Considerations

### Security

- Change default passwords in production
- Configure proper TLS certificates (Let's Encrypt or CA)
- Implement proper RBAC policies
- Enable audit logging
- Configure network policies for production workloads

### Backup & Recovery

- Configure Velero for cluster backups
- Set up external storage for Longhorn backups
- Test restore procedures regularly
- Document recovery runbooks

### Monitoring & Alerting

- Configure Alertmanager for production alerts
- Set up proper log retention policies
- Configure grafana dashboards for business metrics
- Implement health checks and SLOs

## Support

For issues and questions:
- Check the logs: `kubectl logs -n <namespace> <pod-name>`
- Review documentation in `docs/`
- Check GitHub issues
- Contact the platform team