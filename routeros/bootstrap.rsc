# RouterOS CHR Bootstrap — Edge Router
# Design: Host-only WAN (vboxnet1) e LAN (vboxnet0)
# Host (VPS):
#   - enp35s0: 136.243.94.243/32 (exclusivo do host)
#   - vboxnet1 (WAN interna host↔CHR): 192.168.57.1/24
#   - vboxnet0 (LAN host-only):        192.168.56.1/24
#   - Rotas no host (após subir CHR):
#       ip route add 136.243.208.128/29 via 192.168.57.2 dev vboxnet1
#       ip -6 route add 2a01:48:171:76b::/64 via fe80::<LL_CHR_VBOXNET1> dev vboxnet1  # ou via global quando configurado
#   - sysctl: net.ipv4.ip_forward=1, net.ipv6.conf.all.forwarding=1, rp_filter=2
# CHR:
#   - ether1 (WAN interna): 192.168.57.2/24, default gw 192.168.57.1
#   - ether2 (LAN): 192.168.56.2/24 + 136.243.208.129/29 + 2a01:48:171:76b::1/64 (RA)

# 0) Segurança básica
/user set admin password=10302088
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes
/ip service set www disabled=yes
/ip service set www-ssl disabled=yes
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
# Permite gerenciamento apenas de redes internas e do host público
# Adiciona também 10.0.2.2 (gateway NAT do VirtualBox) para acesso via port-forward 136.243.94.243:8291
/ip service set winbox disabled=no address=192.168.56.0/24,192.168.57.0/24,136.243.94.243/32,10.0.2.2/32
/ip service set ssh address=192.168.56.0/24,192.168.57.0/24,136.243.94.243/32 port=22

# 1) Endereçamento IPv4
# ether1 = WAN interna (vboxnet1)
/ip address add address=192.168.57.2/24 interface=ether1 comment=WAN-INT
# Rota default via host (vboxnet1)
/ip route add dst-address=0.0.0.0/0 gateway=192.168.57.1

# ether2 = LAN (vboxnet0)
/ip address add address=192.168.56.2/24 interface=ether2 comment=LAN-MGMT
# Gateway IPv4 público para as VMs do /29
/ip address add address=136.243.208.129/29 interface=ether2 comment=LAN-PUBLIC-GW

# 1.1) ether3 = NAT (VirtualBox NAT) — para Winbox via port-forward
/ip dhcp-client add interface=ether3 use-peer-dns=no add-default-route=no disabled=no comment=NAT-DHCP

# 2) IPv6 — anunciar /64 na LAN (SLAAC/RA)
/ipv6 settings set accept-router-advertisements=yes
/ipv6 address add address=2a01:48:171:76b::1/64 interface=ether2 advertise=yes comment=LANv6-GW
# Rota default IPv6 (opcional; ajuste next-hop quando disponível)
#: /ipv6 route add dst-address=::/0 gateway=<HOST_VBOXNET1_IPV6>

# 3) Listas e firewall (policy drop em input)
/ip firewall address-list add list=admin-allowed address=192.168.56.0/24 comment=Mgmt-LAN
/ip firewall address-list add list=admin-allowed address=192.168.57.0/24 comment=Mgmt-WAN-INT
/ip firewall address-list add list=admin-allowed address=136.243.94.243/32 comment=Host-Public

# Regras INPUT
/ip firewall filter add chain=input connection-state=established,related action=accept comment="allow established/related"
/ip firewall filter add chain=input protocol=icmp action=accept comment="allow ping"
# Permite Winbox via NAT PF (ether3:8291) a partir do host
/ip firewall filter add chain=input in-interface=ether3 protocol=tcp dst-port=8291 action=accept comment="allow winbox via NAT PF"
/ip firewall filter add chain=input src-address-list=admin-allowed action=accept comment="allow mgmt (winbox/ssh)"
/ip firewall filter add chain=input in-interface=ether2 protocol=udp dst-port=51820 action=accept comment="allow wg from LAN peers"
/ip firewall filter add chain=input in-interface=wg0 action=accept comment="allow wg mgmt"
/ip firewall filter add chain=input action=drop comment="drop all"

# Regras FORWARD
/ip firewall filter add chain=forward connection-state=established,related action=accept
/ip firewall filter add chain=forward in-interface=ether2 out-interface=ether1 action=accept comment="LAN -> WAN"
/ip firewall filter add chain=forward in-interface=ether1 out-interface=ether2 connection-state=new action=drop comment="block unsolicited WAN -> LAN"

# 4) NAT (apenas para a sub-rede privada de gestão)
/ip firewall nat add chain=srcnat src-address=192.168.56.0/24 out-interface=ether1 action=masquerade comment="NAT private LAN"

# 5) WireGuard (admin/túnel) — preencha chaves e peer
/interface wireguard add name=wg0 listen-port=51820
# /interface wireguard set [find name=wg0] private-key=<WG_PRIVATE_KEY>
/ip address add address=10.8.0.1/24 interface=wg0
# /interface wireguard peers add interface=wg0 public-key=<SITE_PUBLIC_KEY> allowed-address=10.8.0.2/32,192.168.1.0/24 endpoint-address=<SITE_ENDPOINT_IP_OR_DNS> endpoint-port=51820 persistent-keepalive=25

# 6) DHCP (opcional para LAN privada 192.168.56.0/24)
/ip pool add name=lan-pool ranges=192.168.56.100-192.168.56.200
/ip dhcp-server add name=lan-dhcp interface=ether2 address-pool=lan-pool lease-time=1h disabled=no
/ip dhcp-server network add address=192.168.56.0/24 gateway=192.168.56.2 dns-server=1.1.1.1,8.8.8.8

# 7) Salvamento
/system note set show-at-login=yes note="CHR bootstrap aplicado. Altere a senha admin e ajuste IPv6 default route/WG."
