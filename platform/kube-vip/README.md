# Kube-VIP Configuration

Kube-VIP provides Virtual IP (VIP) management for Kubernetes clusters, enabling high availability for the control plane API server.

## Configuration

- **VIP Address**: 192.168.56.200 (PROD), 192.168.56.210 (STG)
- **Interface**: eth1 (private network interface)
- **Port**: 6443 (Kubernetes API server)

## Installation

The kube-vip static pod is automatically deployed during k3s cluster initialization through the Vagrantfile provisioning.

## Usage

After cluster initialization, the VIP will be available and can be used to access the Kubernetes API:

```bash
kubectl --server=https://192.168.56.200:6443 get nodes
```

## Troubleshooting

- Check kube-vip pod status: `kubectl -n kube-system get pods -l component=kube-vip`
- Verify VIP is active: `ping 192.168.56.200`
- Check logs: `kubectl -n kube-system logs kube-vip-<node>`