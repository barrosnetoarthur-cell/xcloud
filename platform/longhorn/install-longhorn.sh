#!/bin/bash
set -euo pipefail

echo "Installing Longhorn..."

# Install required packages on nodes
echo "Installing Longhorn prerequisites..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: DaemonSet
metadata:
  name: longhorn-prereq
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: longhorn-prereq
  template:
    metadata:
      labels:
        name: longhorn-prereq
    spec:
      hostPID: true
      containers:
      - name: longhorn-prereq
        image: busybox:1.36
        command: ["/bin/sh"]
        args: ["-c", "nsenter --mount=/proc/1/ns/mnt -- sh -c 'apt-get update && apt-get install -y open-iscsi nfs-common util-linux && systemctl enable iscsid && systemctl start iscsid' && sleep 3600"]
        securityContext:
          privileged: true
        volumeMounts:
        - name: host
          mountPath: /host
          mountPropagation: Bidirectional
      volumes:
      - name: host
        hostPath:
          path: /
      hostNetwork: true
      hostPID: true
      hostIPC: true
EOF

sleep 30

# Install Longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.2/deploy/longhorn.yaml

# Wait for Longhorn to be ready
echo "Waiting for Longhorn to be ready..."
kubectl wait --namespace longhorn-system \
  --for=condition=ready pod \
  --selector=app=longhorn-manager \
  --timeout=300s

# Set Longhorn as default storage class
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "Longhorn installation completed!"
echo "Dashboard will be available at: http://longhorn-frontend.longhorn-system.svc.cluster.local"