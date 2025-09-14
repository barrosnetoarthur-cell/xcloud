# Runbook — WireGuard Site→VPS + NGINX/Traefik

Cenário
- VPS público: 136.243.94.243 (IP fixo)
- Site (LAN): cluster K3s/MetalLB
- Objetivo: publicar HTTP(S) via NGINX/Traefik no VPS, encaminhando tráfego ao Ingress do cluster pela VPN WireGuard

Topologia
- wg0 (site) ⇄ wg0 (VPS)
- VPS expõe 80/443 (LE) → proxy reverso → 10.8.0.2:80/443 (site via wg)

Endereços sugeridos
- VPS wg0: 10.8.0.1/24
- Site wg0: 10.8.0.2/24

Passos
1) VPS (Ubuntu)
- Instale WireGuard e NGINX/Traefik; abra portas 51820/udp, 80/tcp, 443/tcp
- Config wg0 (VPS):
```
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = <VPS_PRIVATE_KEY>

[Peer]
PublicKey = <SITE_PUBLIC_KEY>
AllowedIPs = 10.8.0.2/32, 192.168.1.0/24
```

2) Site (MikroTik OU VM Linux)
- Se MikroTik v7: criar peer para VPS e interface wg, rotas para 10.8.0.0/24 e 136.243.94.243
- Em VM Linux (jump):
```
[Interface]
Address = 10.8.0.2/24
PrivateKey = <SITE_PRIVATE_KEY>

[Peer]
PublicKey = <VPS_PUBLIC_KEY>
Endpoint = 136.243.94.243:51820
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
```
- Adicionar rota do VPS para rede do cluster (ex.: 192.168.1.0/24) quando necessário

3) VPS — Proxy reverso
- NGINX: proxy_pass para o endereço do Ingress na LAN via 10.8.0.2
- TLS LE (nginx/certbot) nos domínios: ex. grafana.safepurelink.com, argocd.safepurelink.com

4) Cluster
- Ingress Controller (NGINX/Traefik) ativo; Service LB com IP MetalLB (ex.: 192.168.1.200)
- Ingress hosts conforme DNS

Segurança
- Limitar acesso ao Ingress Controller a partir do IP do VPS (NetworkPolicy)
- TLS fim no VPS ou pass-through; aplicar cabeçalhos de segurança

Notas
- Armazene as chaves WG no Vault e consuma via ESO
- Automatize configuração via Ansible no futuro
