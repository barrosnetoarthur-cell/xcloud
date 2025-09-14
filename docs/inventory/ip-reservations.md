# Reservas de IP e Endereçamento

## Resumo da LAN
- Rede: 192.168.1.0/24
- Gateway: 192.168.1.1
- DNS: 192.168.1.1 (ou servidores externos)

## VIPs (kube-vip)
- PROD API VIP: 192.168.1.250
- STG  API VIP: 192.168.1.240

## Pools MetalLB
- PROD: 192.168.1.200–192.168.1.219
- STG:  192.168.1.220–192.168.1.229

## VMs — IPs Estáticos (Sugeridos)
- prod-cp1: 192.168.1.101
- prod-cp2: 192.168.1.102
- prod-cp3: 192.168.1.103
- prod-w1:  192.168.1.111
- prod-w2:  192.168.1.112
- stg-cp1:  192.168.1.121
- stg-w1:   192.168.1.122
- vm-portainer (opc): 192.168.1.130
- vm-minio (opc):     192.168.1.131
- vm-teste (Vagrant): 192.168.1.150

## VPS e VPN
- VPS (público): 136.243.94.243
- WireGuard:
  - VPS wg0: 10.8.0.1/24
  - Site wg0: 10.8.0.2/24
- Portas abertas no VPS: 22/tcp, 80/tcp, 443/tcp, 51820/udp, 41641/udp (Tailscale opcional)

## DNS públicos (Cloudflare)
- Os hostnames públicos devem apontar para 136.243.94.243 (VPS) e serem servidos pelo proxy NGINX/Traefik:
  - api.safepurelink.com
  - tunnel.safepurelink.com
  - registry.safepurelink.com
  - gitlab.safepurelink.com
  - ingress.safepurelink.com
  - echo.safepurelink.com
  - velero.safepurelink.com
  - argo.safepurelink.com
  - alertmanager.safepurelink.com
  - prometheus.safepurelink.com
  - grafana.safepurelink.com
  - portainer.safepurelink.com

## Observações
- Garanta reserva/ARP no roteador/DHCP para evitar conflitos.
- Atualize este documento quando IPs forem reatribuídos.
