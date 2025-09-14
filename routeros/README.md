# RouterOS CHR (Edge) — Guia Rápido

Subir com duas NICs:
- WAN: bridged (BRIDGE_IFACE, ex. enp35s0 no VPS)
- LAN: host-only (vboxnet0)

Comandos:
```
cd routeros
BRIDGE_IFACE=enp35s0 vagrant up
vagrant ssh
```

Configuração inicial no CHR (exemplo):
```
/user set admin password=<defina>
/interface print
# ether1 = WAN, ether2 = LAN

# IPv4 WAN /32 + rota default
/ip address add address=136.243.94.243/32 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=<GW-DO-PROVEDOR>

# Roteio do /29 atrás do CHR (ex.: /interface bridge + /ip address nos peers ou em VMs)
# Ex.: reservar 136.243.208.129 para o CHR na LAN pública
/ip address add address=136.243.208.129/29 interface=ether2

# IPv6 /64 na LAN com RA
/ipv6 settings set accept-router-advertisements=yes
/ipv6 address add address=2a01:48:171:76b::1/64 advertise=yes interface=ether2

# Firewall básico
/ip firewall filter add chain=input connection-state=established,related action=accept
/ip firewall filter add chain=input protocol=icmp action=accept
/ip firewall filter add chain=input src-address-list=admin-allowed action=accept comment="SSH/Winbox mgmt"
/ip firewall filter add chain=input action=drop

# NAT para LAN privada (quando necessário)
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade

# WireGuard (admin/túnel)
/interface wireguard add name=wg0 listen-port=51820
/ip address add address=10.8.0.1/24 interface=wg0
# Adicione peers conforme o site on‑prem
```

Notas:
- Crie `vboxnet0` no VirtualBox Host Network Manager para a LAN.
- Substitua `<GW-DO-PROVEDOR>` pelo gateway informado pelo provedor.
