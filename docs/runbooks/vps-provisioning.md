# Runbook — Provisionamento de VPS (Ubuntu/Debian)

Objetivo: contratar/provisionar uma VPS com IP fixo público e portas abertas para suportar WireGuard e proxy HTTP(S).

## Requisitos
- Provedor com IP público fixo
- Ubuntu 22.04 LTS ou Debian 12
- Acesso SSH inicial (chave) e usuário sudo

## Passos
1) Acesso inicial e atualização
```
ssh <user>@<IP_PUBLICO>
sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get install -y ufw curl jq ca-certificates gnupg lsb-release wireguard nginx certbot python3-certbot-nginx
```

2) Firewall (UFW)
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 51820/udp
# Opcional: Tailscale
sudo ufw allow 41641/udp
sudo ufw enable
sudo ufw status verbose
```

3) WireGuard (VPS 10.8.0.1/24)
```
sudo umask 077
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey
VPS_PRIV=$(cat /etc/wireguard/privatekey)
cat | sudo tee /etc/wireguard/wg0.conf >/dev/null <<'EOF'
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = REPLACE_VPS_PRIVATE

# Adicione peers do site depois (AllowedIPs 10.8.0.2/32, 192.168.1.0/24)
EOF
sudo sed -i "s|REPLACE_VPS_PRIVATE|$VPS_PRIV|" /etc/wireguard/wg0.conf
sudo systemctl enable --now wg-quick@wg0
sudo wg show
```

4) NGINX + TLS (Let’s Encrypt)
- Aponte DNS dos domínios para o IP público da VPS
- Crie server blocks com proxy_pass para o Ingress via túnel (endereço da LAN acessível via WireGuard)

Exemplo `/etc/nginx/sites-available/grafana`:
```
server {
  listen 80;
  server_name grafana.safepurelink.com;
  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://10.8.0.2:30080; # Ex.: Ingress LB na LAN
  }
}
```
```
sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d grafana.safepurelink.com --redirect
```

5) Hardening básico
- SSH: PermitRootLogin no, PasswordAuthentication no
- Fail2ban (opcional), unattended-upgrades

6) Verificação
- Portas abertas (nmap de fora)
- `wg show` com peer ativo
- `curl -I https://grafana.safepurelink.com` retorna 200/302 e certificado válido

## Notas
- Armazene chaves e tokens no Vault (consumo via ESO).
- Automatize com Ansible quando possível.
