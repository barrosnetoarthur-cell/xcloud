#!/bin/bash
set -euo pipefail

# Install Cilium CNI
echo "Installing Cilium CNI..."

# Download and install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Install Cilium with configuration
cilium install --version 1.15.6 \
  --set tunnel=disabled \
  --set ipam.mode=kubernetes \
  --set autoDirectNodeRoutes=true \
  --set enableIPv4Masquerade=false \
  --set kubeProxyReplacement=partial \
  --set hostServices.enabled=true \
  --set externalIPs.enabled=true \
  --set nodePort.enabled=true \
  --set hostPort.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set prometheus.enabled=true \
  --set operator.prometheus.enabled=true \
  --set policyAuditMode=true

# Wait for Cilium to be ready
echo "Waiting for Cilium to be ready..."
cilium status --wait

echo "Cilium installation completed!"