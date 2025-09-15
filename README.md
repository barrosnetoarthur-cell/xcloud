# XCloud Kubernetes Platform - Production Ready

## ⚡ Quick Start - Platform Deployment Complete!

**The XCloud platform is now fully implemented with all sprints completed!** ✅

### Automated Deployment
```bash
# Complete deployment (both PROD and STG environments)
./setup-xcloud.sh

# Deploy only production
./setup-xcloud.sh prod

# Validate deployment
./validate-platform.sh prod
```

📖 **For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md)**
📋 **For sprint completion status, see [TODOS.md](TODOS.md)**

---

# Original Documentation: Arquitetura Recomendada de Clusters Kubernetes

Este documento substitui o desenho anterior de “um único cluster distribuído por WAN” e define uma arquitetura opinativa e pragmática para ambientes separados, com alta disponibilidade em produção, boas práticas de rede, armazenamento, segurança e operação.

## Resumo
- Ambientes separados: dev, homolog e produção (clusters distintos).
- Produção com alta disponibilidade: 3 control-planes (k3s server com etcd embutido) + ≥2 workers, no mesmo site/região.
- Nada de workers remotos por WAN/Tailscale. Se houver múltiplos sites, use multi-cluster.
- Entrega e configuração via GitOps (Argo CD ou Flux).
- Ingress, TLS, DNS, storage e backup padronizados.
- Observabilidade completa (métricas, logs, traces).
- Segurança por padrão: RBAC, PSA, NetworkPolicy, escaneamento de imagens e gestão de segredos.
- Controle de versão/CI/CD: GitLab CE self-hosted (com GitLab Runner) e GitLab Container Registry; Redmine para gestão de projetos.

## 1. Topologias por Ambiente

### 1.1 Desenvolvimento (Local)
**Objetivo:** feedback rápido e isolamento total.
- Opções:
  - kind ou k3d no computador do desenvolvedor; ou
  - k3s single-node em VM local/WSL2.
- Não une o PC ao cluster de produção.
- Opcional: usar Tailscale apenas para acesso administrativo seguro (SSH/kubectl) ao Git/registry internos.

### 1.2 Homologação (Staging)
**Objetivo:** validar integrações próximas de produção, custo moderado.
- 1 control-plane + 2 workers (pode ser HA leve com 3 servers, se orçamento permitir).
- Mesmo stack de rede/ingress, storage e observabilidade da produção.
- Mesma estratégia GitOps (branch/environment overlays).

### 1.3 Produção
**Objetivo:** disponibilidade e previsibilidade.
- 3 nós control-plane k3s (server) com etcd embutido (quorum ímpar).
- ≥2 nós worker dedicados (separar workloads por taints/tolerations).
- Mesmo site/região (baixa latência interna). Se houver demanda multi-site, usar multi-cluster.
- Hypervisor/host: bare-metal ou Proxmox/ESXi. Evitar VirtualBox em produção.

**Sizing inicial (ponto de partida)**
- Control-plane: 4 vCPU, 8 GB RAM, disco SSD/NVMe rápido, rede 1–10 GbE.
- Worker: 4–8 vCPU, 8–32 GB RAM, SSD/NVMe; ajustar por workload/stateful.
- Planejar headroom de 30–50% para picos e upgrades.

## 2. Multi‑cluster e Entrega (GitOps)
- Repositório Git no GitLab CE com diretórios por ambiente: environments/dev, environments/stg, environments/prod.
- Base compartilhada + overlays (Kustomize ou Helm) por ambiente.
- Argo CD ou Flux instalado em cada cluster para sincronizar o estado a partir do Git (GitLab).
- Promover por Merge Requests (dev → stg → prod). Auditoria e rastreabilidade nativas do GitLab.
- Pipelines GitLab CI/CD para build/test/security scan e publicação de imagens no GitLab Container Registry.
- GitLab Runner por cluster (Helm chart) com executores Kubernetes; tags por ambiente para roteamento de jobs.

## 3. Rede e Ingress
- CNI: Cilium (preferido) ou Calico (habilitar NetworkPolicies).
- Ingress Controller: NGINX Ingress Controller ou Traefik (um por cluster).
- TLS: cert-manager + emissor ACME (Let’s Encrypt) ou CA interna.
- DNS: external-dns (opcional) para automatizar registros públicos/privados.
- Bare-metal: MetalLB para LoadBalancer. Em cloud, usar LB gerenciado.
- Evitar workers via WAN. Entre sites, usar clusters separados e, se necessário, malha de serviços (Istio/Linkerd) ou federation — apenas quando houver caso de uso real.
- Publicação externa (decisão): WireGuard site→VPS + NGINX/Traefik
  - VPS público: 136.243.94.243 (IP fixo). O DNS externo aponta para este IP.
  - Túnel WireGuard entre site e VPS; proxy reverso no VPS para o Service do Ingress (MetalLB) no cluster.
  - TLS termina no VPS (Let’s Encrypt). No cluster, Ingress pode operar HTTP (ou TLS pass-through se necessário).
  - Em Ingress públicos, usar annotation do external-dns para forçar target: external-dns.alpha.kubernetes.io/target: "136.243.94.243".
- Alternativa (quando sem VPS/IP público): Cloudflare Tunnel (cloudflared) + external-dns + cert-manager DNS-01.

## 4. Armazenamento e Backup
- Storage em produção: Longhorn (simples e eficaz em bare‑metal) ou OpenEBS/Ceph conforme necessidades de performance/capacidade.
- Classes de Storage claras (rápido vs padrão; réplicas/zoneamento definidos).
- Snapshots CSI habilitados para PVCs críticos.
- Backups: Velero (agendamentos por namespace/aplicação), destino S3 compatível (MinIO/objeto cloud), retenção definida e testes de restore periódicos.

## 5. Observabilidade
- Métricas: Prometheus + kube-state-metrics + node-exporter; Alertmanager com playbooks e canais (e-mail/Slack/Teams).
- Dashboards: Grafana com dashboards importados (Kubernetes/Nodes/Etcd/Ingress/Aplicação).
- Logs: Loki + Promtail (ou EFK). Definir retenção e budget de armazenamento.
- Tracing: OpenTelemetry + Tempo/Jaeger para serviços distribuídos.
- Provas de vida: SLOs e alertas por latência/erro (p95/p99, taxa de erro HTTP, saturação de filas, etc.).

## 6. Segurança
- RBAC de menor privilégio. Revisões de permissões trimestrais.
- Pod Security Admission (PSA) em modo ‘baseline’/‘restricted’ por namespace.
- NetworkPolicies padrão “deny-all” e regras mínimas por app.
- Escaneamento de imagens (Trivy/Grype) no CI e no registro.
- Runtime security: Falco (opcional) para detecção de anomalias.
- Segredos: External Secrets Operator + Vault (ou AWS/GCP/Azure Key Vault). Nunca commitar segredos.
- Admission Control: OPA Gatekeeper ou Kyverno para políticas (no privileged, no :latest, resource limits, etc.).
- Auditoria do API Server habilitada (rotação e retenção de logs).

## 7. Gestão e Operação
- Gestão do cluster: Rancher será a ferramenta padrão para gestão de Kubernetes e multi‑cluster. Portainer não será adotado para gestão de Kubernetes neste projeto.
- Rancher (padrão)
  - Instalação: Helm chart oficial em `cattle-system`, 3 réplicas (HA), Ingress + TLS (cert-manager), DNS: `rancher.safepurelink.com` apontando para o IP público (via VPS/proxy).
  - Acesso: restringir a VPN/Tunnel; habilitar OIDC/SSO quando disponível; considerar desabilitar login local após SSO.
  - Segurança: RBAC mínimo, auditoria, backups/config export; seguir hardening da SUSE/Rancher.
- Portainer (opcional, uso pontual de Docker/VMs)
  - Se necessário, hospedar em VM fora dos clusters; não usar para gerenciar Kubernetes; evitar agents nos clusters; acesso somente via HTTPS e restrito.

## 8. Plano de Migração (do desenho atual → recomendado)
- **Passo 0:** Inventário. Liste todos os workloads, PVCs, segredos e ingress atuais.
- **Passo 1:** Criar cluster dev local (kind/k3d) e cluster homolog (novo). Configurar GitOps.
- **Passo 2:** Provisionar novo cluster produção HA (3 servers + ≥2 workers) no mesmo site.
- **Passo 3:** Instalar baseline (CNI, Ingress, cert-manager, external-dns/MetalLB, Longhorn, Velero, observabilidade, segurança, GitOps).
- **Passo 4:** Migrar segredos para Vault/ESO. Ajustar manifests para overlays por ambiente.
- **Passo 5:** Restaurar dados (se necessário) com Velero/snapshots para homolog; validar.
- **Passo 6:** Executar smoke tests e testes de carga em homolog. Corrigir gargalos.
- **Passo 7:** Fazer cutover para o novo cluster de produção (janela de mudança, freeze, backup final, apply via GitOps). Monitorar SLOs.
- **Passo 8:** Descontinuar a prática de unir o PC como worker. Manter Tailscale apenas para acesso administrativo (SSH/VPN), não para tráfego de pods.

## 9. Guia de Instalação (Exemplo k3s em bare‑metal)
Ajuste conforme seu provedor/hypervisor. Em produção, prefira Ansible/Terraform para padronizar.
- **Control-planes (3 nós):**
  - Instalar SO (Ubuntu 22.04 LTS), configurar hostname, IP, NTP.
  - Instalar k3s server com etcd e SAN para o VIP/LB:
    - Exemplo (resumo conceitual):
      - server --cluster-init --tls-san <VIP> --disable traefik
      - servers subsequentes: server --server https://<VIP>:6443 --tls-san <VIP>
- **Workers (≥2 nós):**
  - Instalar k3s agent apontando para https://<VIP>:6443 com token.
- **Ingress:** instalar NGINX Ingress Controller (ou Traefik).
- **TLS:** instalar cert-manager e configurar ClusterIssuer (Let’s Encrypt).
- **DNS:** instalar external-dns (se necessário) com credenciais limitadas.
- **LB bare‑metal:** instalar MetalLB com pool IP.
- **Storage:** instalar Longhorn e definir StorageClass padrão.
- **Backup:** instalar Velero (destino S3), jobs de agendamento e testes de restore.
- **Observabilidade:** stack de métricas/logs/traces.
- **GitOps:** instalar Argo CD/Flux e apontar para os repositórios/overlays.
- **Publicação/Acesso externo**
  - Opção adotada: WireGuard site↔VPS (136.243.94.243) + NGINX/Traefik no VPS.
    - DNS: external-dns com annotation target para 136.243.94.243 nos Ingress públicos.
    - Proxy: VPS encaminha tráfego 80/443 para o IP MetalLB do Ingress (ex.: 192.168.1.200) via túnel.
    - TLS: Let’s Encrypt no VPS (HSTS/Owasp headers). Opcional pass-through.
    - Segurança: NetworkPolicy permitindo apenas o IP WireGuard do VPS (ex.: 10.8.0.1) ao namespace do Ingress.
  - Alternativa: Cloudflare Tunnel (cloudflared) apontando para Ingress.

## 10. Checklist de Produção (mínimo viável)
- [ ] 3 control-planes e quorum ok (etcd saudável, latência intra‑cluster baixa).
- [ ] ≥2 workers e taints/tolerations conforme criticidade.
- [ ] CNI com NetworkPolicies aplicadas.
- [ ] Ingress + TLS válidos; redirects e HSTS quando aplicável.
- [ ] DNS automatizado (external-dns) ou playbook de atualização manual documentado.
- [ ] StorageClass padrão e políticas de réplicas definidas.
- [ ] Backups Velero agendados e restore testado.
- [ ] Observabilidade com alertas para SLOs-chave.
- [ ] Políticas de segurança (PSA, OPA/Kyverno) ativas; segredos via ESO+Vault.
- [ ] Pipelines CI/CD publicando imagens assinadas e manifestos versionados.
- [ ] Procedimento de upgrade e rollback documentados.

## 11. Notas sobre Ferramentas citadas
- **k3s:** leve, suporta etcd embutido em HA.
- **kind/k3d:** ótimos para dev local.
- **Rancher:** gestão multi‑cluster com RBAC centralizado.
- **Longhorn:** simples e eficiente para estado em bare‑metal.
- **Velero:** padrão de mercado para backup/restore.
- **Cilium:** CNI com observabilidade e eBPF avançado.
- **NGINX/Traefik, cert-manager, external-dns, MetalLB:** base de rede/ingress sólida.
- **GitLab CE:** repositórios, MR, CI/CD, Container Registry integrados.
- **GitLab Runner:** executores Kubernetes por cluster/ambiente.
- **Redmine:** gestão de projetos/issue tracking (integra com GitLab via webhooks/URLs).

## 12. Diagrama da Arquitetura

### 12.1 Visão geral multi‑cluster (GitOps)
```
                           +----------------------------+
                           |        Git Repository      |
                           |   (manifests Helm/Kustom)  |
                           +-------------+--------------+
                                         |
             +---------------------------+---------------------------+
             |                           |                           |
+------------v-----------+   +-----------v------------+   +----------v------------+
|   Cluster DEV          |   |   Cluster STG          |   |   Cluster PROD        |
| (kind/k3d/k3s local)   |   | (1 CP + 2 W)           |   | (3 CP + >=2 W)        |
| - CNI (Cilium)         |   | - CNI (Cilium)         |   | - CNI (Cilium)        |
| - Ingress + TLS        |   | - Ingress + TLS        |   | - Ingress + TLS       |
| - GitOps Agent (Flux/  |   | - GitOps Agent         |   | - GitOps Agent        |
|   Argo CD)             |   | - Observabilidade      |   | - Observabilidade     |
|                        |   | - Storage (opcional)   |   | - Storage (Longhorn)  |
|                        |   | - Backup (Velero)      |   | - Backup (Velero)     |
+------------------------+   +------------------------+   +-----------------------+
```

### 12.2 Topologia de Produção (HA)
```
                                VIP/LB (6443)
                                     |
                     +---------------+---------------+
                     |                               |
           +---------v---------+           +---------v---------+           +---------v---------+
           | Control-plane #1  |           | Control-plane #2  |           | Control-plane #3  |
           | k3s server + etcd |           | k3s server + etcd |           | k3s server + etcd |
           +---------+---------+           +---------+---------+           +---------+---------+
                     |                               |                               |
                     +---------------+---------------+---------------+---------------+
                                     |                               |
                         +-----------v-----------+       +-----------v-----------+
                         |      Worker #1        |       |      Worker #2        |    ... (>=2)
                         |   app pods / Daemons  |       |   app pods / Daemons  |
                         +-----------+-----------+       +-----------+-----------+
                                     |                               |
             +-----------------------+-------------------------------+-----------------------+
             |                    Cluster Add‑ons (Prod)                                      |
             |  - CNI (Cilium)   - Ingress (NGINX/Traefik)   - TLS (cert-manager)            |
             |  - MetalLB (LB)    - Storage (Longhorn)       - Backup (Velero)               |
             |  - Observabilidade (Prometheus/Grafana/Loki)  - Políticas (PSA, Kyverno/OPA)  |
             +--------------------------------------------------------------------------------+
```

## 13. Perfil Single Host: VirtualBox + Vagrant (1 servidor)

Este perfil adapta a arquitetura para um único host físico executando VirtualBox+Vagrant. É 100% open-source e aceita o risco de SPOF físico.

### 13.1 Premissas e Limitações
- Um único servidor físico (SPOF). Alta disponibilidade apenas dentro do cluster (falhas de VM ou serviço), não de hardware.
- VirtualBox com adaptadores em modo Bridged para IPs na LAN (evite depender de NAT/port-forward).
- Recomendado habilitar Promiscuous Mode = Allow All nas NICs das VMs que fizerem ARP announcement (kube-vip).
- Isolamento por clusters: PROD e STG compartilham o host, mas não os recursos do cluster.
- Dev roda local no seu PC (kind/k3d ou k3s single-node); não se conecta como worker.

### 13.2 Topologia de VMs (sugestão)
- PROD (k3s): cp1, cp2, cp3, w1, w2
- STG (k3s): cp1, w1 (w2 opcional)
- Backup (opcional, fora dos clusters): vm-minio (objeto S3 para Velero)
- Portainer Server (opcional, fora dos clusters): vm-portainer (GUI web do Portainer)
- VIP da API (PROD): 192.168.1.250 (exemplo)
- VIP da API (STG): 192.168.1.240 (exemplo)

### 13.3 Rede
- Cada VM com uma NIC Bridged para sua LAN (ex.: 192.168.1.0/24).
- kube-vip para expor a API do cluster (VIP/ARP) nos control-planes.
- MetalLB para Services LoadBalancer (Ingress Controller, etc.):
  - PROD pool: 192.168.1.200-192.168.1.219
  - STG pool: 192.168.1.220-192.168.1.229
- Portainer
  - Server exposto via HTTPS na VM dedicada (ex.: https://portainer.seu.domínio). Preferir Edge Agent nos clusters (conexão outbound), evitando exposição do agent.
- Publicação via VPS (decisão)
  - VPS IP público: 136.243.94.243. WireGuard: wg0 com 10.8.0.1 (VPS) e 10.8.0.2 (site) sugeridos.
  - NGINX/Traefik no VPS → proxy para Ingress (MetalLB) via túnel. DNS aponta para o VPS.
- DNS público/privado opcional com external-dns.

### 13.4 Sizing base (ajuste conforme o hardware)
- PROD:
  - cp1/cp2/cp3: 2–4 vCPU, 4–8 GB RAM, SSD, 1 NIC bridged
  - w1/w2: 4–8 vCPU, 8–16 GB RAM, SSD, discos extras para Longhorn (100–300 GB por VM)
- STG:
  - cp1: 2–4 vCPU, 4–8 GB RAM
  - w1: 4 vCPU, 8–12 GB RAM, 1 disco extra para Longhorn
- vm-minio (opcional): 2 vCPU, 4 GB RAM, disco conforme retenção de backups
- vm-portainer (opcional): 1 vCPU, 2 GB RAM, disco 10–20 GB, HTTPS habilitado; conecta a Edge Agents em PROD/STG.

### 13.5 Vagrantfile (esqueleto)
Exemplo conceitual para múltiplas VMs (ajuste box, rede e recursos):
```ruby
Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu/jammy64'
  # Ajuste para sua interface física (ex.: 'Intel(R) Ethernet')
  BRIDGE_IFACE = nil # nil deixa o Vagrant perguntar

  nodes = [
    # PROD control-planes
    {name: 'prod-cp1', cpus: 2, mem: 4096, ip: '192.168.1.101'},
    {name: 'prod-cp2', cpus: 2, mem: 4096, ip: '192.168.1.102'},
    {name: 'prod-cp3', cpus: 2, mem: 4096, ip: '192.168.1.103'},
    # PROD workers
    {name: 'prod-w1',  cpus: 4, mem: 8192, ip: '192.168.1.111', disks: [200]},
    {name: 'prod-w2',  cpus: 4, mem: 8192, ip: '192.168.1.112', disks: [200]},
    # STG
    {name: 'stg-cp1',  cpus: 2, mem: 4096, ip: '192.168.1.121'},
    {name: 'stg-w1',   cpus: 4, mem: 6144, ip: '192.168.1.122', disks: [150]},
    # Opcional
    # {name: 'minio',   cpus: 2, mem: 4096, ip: '192.168.1.130'}
  ]

  nodes.each do |n|
    config.vm.define n[:name] do |node|
      node.vm.hostname = n[:name]
      node.vm.network 'public_network', bridge: BRIDGE_IFACE, ip: n[:ip]
      node.vm.provider 'virtualbox' do |vb|
        vb.name   = n[:name]
        vb.cpus   = n[:cpus]
        vb.memory = n[:mem]
        # Habilitar promiscuous mode no adaptador 1 (bridged)
        vb.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
      end
      # Discos extras (Longhorn): tamanhos em GB
      Array(n[:disks]).each_with_index do |size_gb, i|
        disk = "#{n[:name]}-disk#{i+1}.vdi"
        node.vm.provider 'virtualbox' do |vb|
          vb.customize ['createhd', '--filename', disk, '--size', size_gb * 1024]
          vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2 + i, '--device', 0, '--type', 'hdd', '--medium', disk]
        end
      end
      # Provisionamento básico: atualizações e ferramentas
      node.vm.provision 'shell', inline: <<-SHELL
        set -eux
        apt-get update -y
        apt-get install -y curl jq
      SHELL
    end
  end
end
```
Notas:
- Se o nome da interface bridged não for detectado, o Vagrant perguntará ao levantar a VM.
- Em alguns hosts, o controlador SATA pode ter outro nome; ajuste o storageattach conforme necessário.

### 13.6 Provisionamento dos clusters (k3s + add‑ons)
Ordem sugerida (por cluster):
1) Control-plane #1 (cluster-init) com kube-vip (VIP) e Traefik desabilitado se usar NGINX.
2) Control-planes #2 e #3 juntam ao cluster via VIP.
3) Workers juntam via VIP.
4) Add-ons: NGINX Ingress, cert-manager, MetalLB, Longhorn, Velero, GitOps (Argo CD/Flux), Observabilidade.

Exemplos (conceituais):
- CP #1 (PROD):
```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --cluster-init \
  --tls-san 192.168.1.250 --disable traefik --disable servicelb \
  --write-kubeconfig-mode 644' sh -
# Deploy kube-vip manifest em /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
```
- CP #2/#3 (PROD):
```bash
export K3S_URL=https://192.168.1.250:6443
export K3S_TOKEN=$(ssh prod-cp1 'sudo cat /var/lib/rancher/k3s/server/node-token')
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --tls-san 192.168.1.250 --disable traefik --disable servicelb' sh -
```
- Workers:
```bash
export K3S_URL=https://192.168.1.250:6443
export K3S_TOKEN=... # mesmo token
curl -sfL https://get.k3s.io | sh -
```
- MetalLB (PROD): pool 192.168.1.200-219
- Ingress (NGINX), cert-manager (Let’s Encrypt/CA interna), Longhorn (discos extras), Argo CD/Flux (GitOps), Velero (endpoint S3 do MinIO se optar por VM separada).

Repita o mesmo padrão para STG com VIP 192.168.1.240 e pool 192.168.1.220-229.

### 13.7 Diagrama (single host VirtualBox)
```
+-------------------------------------------------------------------------------------------+
|                           Servidor Físico (VirtualBox + Vagrant)                          |
|-------------------------------------------------------------------------------------------|
|  Rede LAN (Bridged)                 |                                                    |
|  192.168.1.0/24                     |                                                    |
|                                     v                                                    |
|     +----------------------+     +------------------------------+                        |
|     | Cluster PROD (k3s)   |     | Cluster STG (k3s)            |                        |
|     | VIP API: 192.168.1.250|    | VIP API: 192.168.1.240       |                        |
|     | cp1 cp2 cp3 w1 w2    |     | cp1 w1 (w2 opcional)         |                        |
|     | Ingress, MetalLB      |     | Ingress, MetalLB             |                        |
|     | Longhorn, Velero      |     | Longhorn, Velero             |                        |
|     +----------------------+     +------------------------------+                        |
|            ^         ^                    ^        ^                                      |
|            |         |                    |        |                                      |
|         kube-vip  MetalLB              kube-vip  MetalLB                                   |
|                                                                                           |
|  [Opcional] VM MinIO para backups Velero (S3)                                             |
+-------------------------------------------------------------------------------------------+
```

### 13.8 Checklist extra (VirtualBox)
- [ ] NICs em modo Bridged; Promiscuous Mode allow-all nas VMs de control-plane.
- [ ] IPs estáticos reservados na LAN para todas as VMs e VIPs.
- [ ] Discos extras anexados aos workers para Longhorn; verificar I/O do host.
- [ ] Sincronização de horário (NTP) nas VMs.
- [ ] Backups Velero testados para repositório fora do cluster (idealmente fora do host).
- [ ] Quotas e limits para a stack de observabilidade para não competir com apps.

## 14. Política de Serviços Compartilhados (por ambiente)

Esta seção define quais serviços podem ser compartilhados entre projetos dentro de um mesmo ambiente (prod/stg/dev) e quais devem ser dedicados por projeto.

### 14.1 Serviços compartilháveis (recomendados)
- Casdoor (IdP) único por ambiente
  - Multi‑tenant (orgs/apps/clients por projeto), RBAC e políticas de senha/MFA centralizadas.
- Observabilidade
  - Prometheus: 1 por cluster; para retenção longa, agregue com Thanos/VictoriaMetrics central no ambiente.
  - Alertmanager central com rotas por labels (projeto/equipe/criticidade).
  - Grafana único (folders/dashboards e RBAC por projeto; datasources segregados).
  - Logs: Elasticsearch + Kibana únicos (índices/ILM e Spaces por projeto) ou Loki + Grafana (tenants/labels por projeto).
- MinIO (S3) único por ambiente
  - Buckets/policies/quotas por projeto; credenciais isoladas. Usado por Velero/Longhorn e uploads de apps.
- Vault + External Secrets Operator (se adotado)
  - Namespaces/paths por projeto e políticas de acesso mínimas.
- Registry: GitLab Container Registry (preferido) ou Harbor, único por ambiente
  - Projetos, retenção, escaneamento e assinatura (cosign) por política.

### 14.2 Serviços que preferimos dedicar por projeto
- MongoDB
  - Ideal: instância/replica set por projeto. Mínimo: database + usuário dedicado com quotas.
- Redis
  - Preferir instância por projeto/uso (cache, fila, rate‑limit). Se compartilhar: DB lógico + prefixos, maxmemory‑policy por workload e monitoramento de evictions.
- MySQL (ver diretrizes abaixo)
  - Compartilhar com cuidado; projetos críticos/ruidosos em instância dedicada.

### 14.3 MySQL: diretrizes de compartilhamento
- 1 instância/cluster por ambiente (prod/stg/dev) é aceitável;
  - Dentro da instância, 1 database + 1 usuário por projeto (least privilege, TLS on, limites de conexão por app).
- Para projetos críticos/variáveis em carga: instância/cluster MySQL dedicado.
- Backups: full + binlog, retenção por projeto, testes de restore regulares.
- Parâmetros de isolamento: innodb_buffer_pool_size adequado, connection limits por usuário, QoS (se disponível), e observabilidade (latência, locks, slow queries).

### 14.4 Regras e boas práticas gerais
- Nunca misturar ambientes: prod ≠ stg ≠ dev (instâncias separadas por ambiente, ainda que no mesmo host físico).
- Quotas/retention por projeto (Prometheus/Thanos, Elastic/Loki, MinIO, GitLab Registry).
- Backups segregados e testes de restore por projeto/ambiente.
- Em host único, isolar I/O
  - Executar bancos/Elasticsearch/MinIO/Redis em VMs/nós distintos e, se possível, em discos virtuais separados.
- Segurança
  - Segregação de credenciais por projeto, rotação periódica, TLS entre serviços, políticas de rede (NetworkPolicies) restritivas.
- Operação
  - SLIs/SLOs por serviço; alertas por latência/erro/saturação; capacity planning periódico.

## 15. GitLab CE self-hosted e Redmine

### 15.1 Decisões
- Git principal e CI/CD: GitLab CE self-hosted.
- Container Registry: GitLab Registry (substitui Harbor neste projeto).
- Gestão de projetos: Redmine (integração com GitLab por webhooks/links).

### 15.2 Implantação recomendada
- GitLab CE (Omnibus) em VM dedicada
  - Vantagem: pacote auto-contido (PostgreSQL, Redis, Gitaly, Registry, Pages) e manutenção simplificada.
  - Sizing inicial: 4–8 vCPU, 8–16 GB RAM, disco rápido (≥200 GB para repositórios/artefatos/registry), NIC bridged.
  - DNS/TLS: gitlab.seu.domínio (Let’s Encrypt via Omnibus) ou cert interno.
  - Backup: jobs nativos do GitLab + cópia off‑host (snapshot/rsync/S3).
- GitLab Runner por cluster (Helm)
  - Runners com executor Kubernetes; tags dev/stg/prod; service account com permissões mínimas.
- Redmine
  - Opção A (recomendada): deploy em Kubernetes (STG/PROD) via Helm, com Ingress, TLS, PV e DB externo (MySQL/PostgreSQL).
  - Opção B: VM dedicada (2 vCPU, 4–8 GB RAM), DB externo. DNS: redmine.seu.domínio.
  - Integração com GitLab: webhooks (commits → issues), links de MR/commit em issues, autenticação via OIDC/SAML (opcional).

### 15.3 Banco de dados e dependências
- GitLab Omnibus usa PostgreSQL e Redis internos (ou externos se preferir). Manter internos simplifica.
- Redmine: pode usar MySQL (alinhado à política 14.3) ou PostgreSQL. Criar schema/usuário dedicados por ambiente.

### 15.4 Rede e segurança
- Ingress com TLS obrigatório; cabeçalhos de segurança (HSTS) e redirects 80→443.
- Backup e retenção definidos; testes de restore trimestrais.
- Acesso administrativo via VPN (Tailscale/ZeroTier) opcional.

### 15.5 Fluxo CI/CD (alto nível)
- Dev faz MR no GitLab → pipeline CI (lint/test/build/scan) → push imagem no GitLab Registry.
- GitOps (Argo/Flux) detecta mudança de versão/manifest em branch de ambiente → sincroniza cluster.
- Observabilidade e alertas monitoram deploy; rollback via MR revert se necessário.

## 16. Capacidade do Host e Plano de Alocação (VirtualBox + Vagrant)

Host dedicado (fornecido)
- CPU: 12 vCPU (Ryzen 5 3600, 6C/12T)
- RAM: 62 GB
- Disco SO: NVMe (md) ~888 GB montado em /
- Dados: HDD 14.6 TB montado em /mnt/storage (ideal para VDIs de dados)
- Virtualização: AMD‑V habilitado

Diretrizes gerais
- Manter 15–25% de headroom de CPU/RAM. Evitar sobrecommit pesado.
- Armazenar discos de dados (VDIs) das VMs em /mnt/storage/virtualbox para isolar I/O do SO.
- NICs em modo Bridged; VIPs via kube‑vip; Services LB via MetalLB (pools dedicados por cluster).
- Backups Velero em MinIO local; agendar cópia off‑host (rsync/S3 externo) quando possível.

Alocação recomendada de VMs (inicial, ajustável)
- Produção (k3s, VIP 192.168.1.250, MetalLB 192.168.1.200‑219)
  - prod‑cp1/2/3: 2 vCPU, 5 GB RAM, disco SO 30–40 GB (NVMe)
  - prod‑w1:       2 vCPU, 10 GB RAM, SO 40 GB + disco dados 200–300 GB (VDI em /mnt/storage)
  - prod‑w2:       2 vCPU, 10 GB RAM, SO 40 GB + disco dados 200–300 GB (Opcional: iniciar parado e ligar sob demanda)
  - Observação: em caso de pressão de CPU, mantenha apenas w1 ligado e habilite w2 quando necessário.
- Homologação (k3s, VIP 192.168.1.240, MetalLB 192.168.1.220‑229)
  - stg‑cp1: 1 vCPU, 4 GB RAM, SO 30 GB
  - stg‑w1:  2 vCPU, 6 GB RAM, SO 30 GB + disco dados 150–200 GB
- Desenvolvimento (k3s single‑node)
  - dev‑single: 1 vCPU, 3–4 GB RAM, SO 20–30 GB (ligar sob demanda)
- GitLab CE (Omnibus, self‑hosted)
  - gitlab: 2 vCPU (mínimo), 6–8 GB RAM, disco 200+ GB (VDI em /mnt/storage)
  - Registry integrado; GitLab Runner implantado nos clusters (Helm) com executor Kubernetes.
  - Nota: para equipes maiores, planejar 4 vCPU/12–16 GB RAM.
- Redmine
  - Implantar em Kubernetes (PROD), com DB externo (MySQL/PostgreSQL conforme política 14.3)
  - Requests iniciais: 0.5–1 vCPU, 2–4 GB RAM; PVC 10–20 GB.
- Portainer Server (opcional)
  - portainer: 1 vCPU, 2 GB RAM, disco 10–20 GB, HTTPS habilitado; conecta a Edge Agents em PROD/STG.
- Infra de Acesso (opcional/enterprise)
  - VPS hub (WireGuard/Tailscale relay/Jump): 1 vCPU, 1–2 GB RAM, disco 10 GB, IP fixo público.
  - cloudflared (se dedicado fora do cluster): 0.5 vCPU, 0.5–1 GB RAM.

Consumo estimado (quando PROD + STG ativos, DEV desligado, w2 opcional desligado)
- CPU: ~10–11 vCPU (com w2 off), deixando ~1–2 vCPU de headroom.
- RAM: ~31–35 GB (PROD) + 10 GB (STG) + 6–8 GB (GitLab) ≈ 47–53 GB, headroom ~9–15 GB.
- Ações:
  - Evitar rodar DEV quando STG estiver em testes de carga.
  - Ligar prod‑w2 apenas em janelas de pico/atualização.

Colocação de serviços compartilhados (por ambiente)
- MinIO: em PROD (K8s), PVs do Longhorn; buckets por projeto; VDI dos workers em /mnt/storage.
- Elasticsearch/Kibana: em PROD (K8s) com limites (ex.: 2 vCPU/6 GB); se I/O for gargalo, migrar para VM dedicada com VDI em /mnt/storage.
- Prometheus/Grafana/Alertmanager: por cluster; retenção curta; opcional agregação futura.
- Redis: por projeto/uso (ou compartilhado com DB lógico/prefixos); monitorar evictions.
- MongoDB/MySQL: conforme seção 14 (ideal dedicar por projeto crítico; mínimo DB+usuário por projeto).

Rede e VIPs
- PROD: API VIP 192.168.1.250; MetalLB 192.168.1.200–219.
- STG:  API VIP 192.168.1.240; MetalLB 192.168.1.220–229.
- Cert‑manager com emissor LE/CA interna; Ingress NGINX/Traefik.

Operação
- Power policy: manter DEV off por padrão; STG on/off conforme necessidade; PROD sempre on.
- Monitorar CPU steal/ready nas VMs; ajustar vCPU se filas persistirem.
- Testes de restore (Velero, DBs) mensais; auditoria de recursos trimestral.
- Portainer: acesso administrativo restrito; somente leitura por padrão; mudanças refletidas em GitOps.

## 17. Acesso Remoto e VPN (MikroTik sem IP fixo)
Objetivo: prover acesso administrativo e publicação segura de serviços mesmo sem IP público fixo.

Cenários e opções
- Administração (kubectl/SSH/GUI internas)
  1) WireGuard site→hub
     - Requisitos: MikroTik RouterOS v7+, VPS com IP fixo (Ubuntu), porta UDP aberta.
     - Fluxo: MikroTik inicia túnel WG para o VPS (136.243.94.243); admins conectam ao VPS (ou bastion) e alcançam redes do cluster via rotas/ACLs.
  2) Tailscale (overlay)
     - Vantagens: NAT traversal, sem portar; ACLs e SSO; Subnet Router para redes dos clusters.
     - Nota: uso administrativo apenas.
- Publicação HTTP(S) externa (apps/painéis)
  - Opção adotada: VPS (136.243.94.243) com NGINX/Traefik, DNS apontando para o VPS e túnel WireGuard até o cluster.
  - Alternativa: Cloudflare Tunnel (cloudflared) apontando para o Ingress do cluster.

Requisitos e segredos
- Domínio e provedor DNS (Cloudflare recomendado) com API Token de escopo mínimo para external-dns e, se usado, cert-manager DNS-01.
- Chaves WireGuard armazenadas no Vault e consumidas via ESO.
- Credenciais do Cloudflare (API Token) no Vault/ESO quando external-dns gerenciar safepurelink.com.

Boas práticas
- Restringir GUIs (ArgoCD, Grafana, Portainer) ao acesso via VPN ou VPS + OIDC.
- NetworkPolicies para permitir apenas tráfego do IP WG do VPS no namespace de Ingress.
- Observabilidade do túnel VPN e do proxy no VPS (logs/alertas).

Referências
- Runbook: `docs/runbooks/wireguard/site-to-vps.md`