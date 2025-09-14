# Requisitos de Rede (Inicial)

Domínio e DNS
- Base domain: safepurelink.com
- Subdomínios públicos previstos (via Cloudflare Tunnel + external-dns):
  - grafana.safepurelink.com
  - argocd.safepurelink.com
  - apps (*.safepurelink.com conforme necessário)
- Subdomínios internos (opcional): internal.safepurelink.com (split-horizon)

TLS
- Emissor: Let’s Encrypt (ClusterIssuer `letsencrypt-dns01` via DNS-01 Cloudflare)
- Política: TLS obrigatório; HSTS nos hosts públicos

VIPs e Pools (LAN)
- VIP API PROD: 192.168.1.250 (kube-vip)
- VIP API STG:  192.168.1.240 (kube-vip)
- MetalLB PROD: 192.168.1.200–192.168.1.219
- MetalLB STG:  192.168.1.220–192.168.1.229

Acesso Externo sem IP fixo
- HTTP(S): Cloudflare Tunnel (cloudflared) apontando para Ingress
- Administração: WireGuard (MikroTik→VPS) ou Tailscale (Subnet Router)

Policies
- NetworkPolicies default deny; liberações mínimas por app
- Apenas egress necessário: DNS (53/udp,tcp), Registry GitLab, Cloudflare, IdP (Casdoor)

Observações
- Confirmar ranges LAN reais e reservar IPs
- Validar nomes finais dos subdomínios
