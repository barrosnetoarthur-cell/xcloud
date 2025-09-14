# TODOs por Sprints — Montagem do Ambiente de Produção Kubernetes

Este plano deriva do `README.md` e organiza a montagem do ambiente de PRODUÇÃO (com STG de apoio para validação) em sprints curtas, com entregáveis claros e critérios de aceite. Ajuste conforme cronograma e equipe.

Legenda
- CP = control-plane; W = worker
- VIP = IP virtual da API (kube-vip)
- Ferramentas base: k3s, Cilium, NGINX/Traefik, cert-manager, MetalLB, Longhorn, Velero, Argo CD/Flux, Prometheus/Grafana/Loki

Referências úteis
- Seções 8, 9, 12, 13, 14, 15 e 16 do `README.md`

---

## Sprint 0 — Planejamento e Inventário
Objetivo: alinhar escopo, inventariar workloads e preparar decisões de base.

Tarefas
- [x] Inventariar workloads atuais: Deployments/StatefulSets, PVCs, Ingress, Secrets, ConfigMaps (rascunho em `docs/inventory/workloads.md`)
- [x] Identificar requisitos de rede (DNS, domínios, TLS, VIPs, ranges MetalLB) (rascunho em `docs/network/requirements.md`)
- [x] Definir emissor de certificados (Let’s Encrypt ou CA interna)
- [x] Escolher stack Ingress (NGINX ou Traefik) e CNI (Cilium preferido)
- [x] Definir política de storage (Longhorn padrão, classes e réplicas)
- [x] Definir estratégia de GitOps (Argo CD ou Flux) e layout do repositório Git
- [x] Decidir sobre MinIO para backups (Velero) e endpoint S3 (VM dedicada `vm-minio`)
- [x] Elaborar janela e estratégia de cutover + rollback
- [x] Escolher provedor DNS (Cloudflare recomendado), emitir API Tokens mínimos

Entregáveis/DoD
- [x] Documento de inventário completo e decisões registradas
- [x] Domínios, VIPs e ranges IP aprovados
- [x] Tokens/API (Cloudflare) provisionados com escopo mínimo; chaves WG planejadas

---

## Sprint 1 — Preparação do Host e Vagrant
Objetivo: preparar o host físico, rede e esqueleto das VMs.

Tarefas
- [x] Validar capacidade do host (CPU/RAM/Disco) e reservar headroom (Sec. 16)
- [x] Configurar diretório de VDIs em disco de dados (ex.: `/mnt/storage/virtualbox`)
- [x] Revisar e ajustar `Vagrantfile` (IPs, BRIDGE_IFACE, tamanhos de disco extras, CPU/RAM)
- [x] Confirmar NIC em modo Bridged e Promiscuous = allow-all nos CPs
- [x] Reservar/garantir IPs estáticos na LAN (CPs, Ws, VIPs de PROD e STG)
- [x] Planejar VM do Portainer Server (opcional): DNS, TLS, sizing, política de RBAC
- [x] Planejar VPS hub (WireGuard/Tailscale) com IP fixo público

### ** FAZER ISSO DPOIS *** Checklist prático de implementação
- [ ] Provisionar VM Rancher (ex: 2 vCPU, 4GB RAM, 30GB disco)
- [ ] Configurar DNS: rancher.safepurelink.com → IP fixo
- [ ] Instalar Docker e Rancher Server (container)
- [ ] Gerar e instalar certificado TLS (Let's Encrypt via proxy no VPS)
- [ ] Configurar RBAC/SSO no Rancher (somente leitura por padrão onde aplicável)
- [ ] Garantir acesso apenas via HTTPS
- [ ] Provisionar VPS hub (ex: 1 vCPU, 1GB RAM, 20GB SSD, Ubuntu/Debian)
- [ ] Liberar portas: UDP 51820 (WireGuard), TCP 22 (SSH restrito), UDP 41641 (Tailscale), HTTP/HTTPS se necessário
- [ ] Instalar e configurar WireGuard (chaves no Vault via ESO)
- [ ] Instalar e configurar Tailscale (opcional, com ACLs)
- [ ] Configurar firewall (UFW/firewalld) permitindo apenas portas necessárias
- [ ] Habilitar atualizações automáticas de segurança
- [ ] Documentar peers e rotas WireGuard
- [ ] Testar conectividade site↔VPS e acesso remoto seguro

Entregáveis/DoD
- [ ] `Vagrant up` conclui uma VM de teste com IP bridged acessível
- [ ] IPs reservados/registrados
- [ ] VPS contratado/provisionado com IP fixo e portas liberadas

---

## Prioridade Máxima — Edge Router (RouterOS/CHR via Vagrant)
Objetivo: padronizar e proteger a borda de rede usando os blocos públicos do VPS.

Contexto de IPs disponíveis
- IPv4 Principal (WAN): 136.243.94.243/32
- IPv4 Subnet roteada: 136.243.208.128/29 (6 utilizáveis)
- IPv6 Subnet: 2a01:48:171:76b::/64

Tarefas
- [ ] Criar VM RouterOS CHR via Vagrant/VirtualBox (2 NICs):
  - NIC1 (WAN): bridged na interface pública do VPS
  - NIC2 (LAN): rede interna VirtualBox (vboxnet) para VMs downstream
- [ ] Configurar endereçamento e roteamento:
  - WAN IPv4: usar 136.243.94.243/32 com gateway do provedor
  - Anunciar/rotear 136.243.208.128/29 atrás do CHR; atribuir IPs públicos às VMs que precisarem
  - IPv6: anunciar /64 na LAN (SLAAC/RA) e permitir roteamento
- [ ] Firewall base no CHR: policy drop, permitir established/related, SSH/Winbox de IPs confiáveis
- [ ] NAT/masquerade para LAN privada quando não usar IP público
- [ ] WireGuard no CHR (wg0: 10.8.0.1/24) para admin e túnel com site on‑prem
- [ ] Opcional: DHCP/DNS na LAN virtual (endereços estáticos por reserva)
- [ ] Documentar mapa de IPs públicos/privados e regras (atualizar `docs/inventory/ip-reservations.md`)

Entregáveis/DoD
- [ ] `vagrant up` do CHR concluído; acesso SSH/Winbox
- [ ] WAN ativa e /29 roteado funcional para VMs downstream
- [ ] IPv6 /64 anunciado e conectividade validada
- [ ] Firewall e NAT aplicados; WireGuard ativo

---

## Sprint 2 — Provisionamento de VMs (PROD e STG base)
Objetivo: criar VMs conforme topologia e sizing base.

Tarefas
- [ ] Subir VMs PROD: cp1, cp2, cp3, w1, w2 (w2 opcional iniciar desligada)
- [ ] Subir VMs STG: cp1, w1
- [ ] Anexar discos extras nos workers para Longhorn (conforme `Vagrantfile`)
- [ ] Provisionamento base: atualizações, `curl`, `jq`, NTP/hora sincronizada
- [ ] Criar VM `vm-portainer` (opcional) e preparar Docker/Compose + certificados TLS
- [ ] Configurar MikroTik: DDNS habilitado, NTP e regras básicas; preparar peers/chaves WG

Entregáveis/DoD
- [ ] Todas as VMs ativas com IP fixo e acesso SSH
- [ ] Discos extras visíveis no SO dos workers

---

## Sprint 3 — Cluster PROD (k3s HA + kube-vip)
Objetivo: formar o cluster de produção HA com VIP da API.

Tarefas
- [ ] Instalar k3s no cp1 com `--cluster-init`, `--tls-san <VIP>`, desativar Traefik/servicelb
- [ ] Implantar kube-vip no diretório de manifests estáticos do k3s (VIP ativo no CPs)
- [ ] Juntar cp2 e cp3 ao cluster via VIP
- [ ] Juntar w1 e w2 (ou manter w2 desligado para economia)
- [ ] Validar etcd (saúde/quorum), latência intra-cluster e kube-vip failover
- [ ] (Opcional) Preparar namespace e access secrets para Edge Agent do Portainer
- [ ] Preparar namespace `platform/tunnel` para cloudflared (Helm/manifest)

Entregáveis/DoD
- [ ] `kubectl get nodes` com 3 CPs Ready + ≥1 W Ready
- [ ] Acesso à API por VIP estável

---

## Sprint 4 — Rede e Ingress (PROD)
Objetivo: rede de pods, entrada HTTP(S) e TLS prontos.

Tarefas
- [ ] Instalar CNI (Cilium) com NetworkPolicies habilitadas
- [ ] Instalar Ingress Controller (NGINX ou Traefik) no namespace `ingress`
- [ ] Instalar cert-manager e configurar `ClusterIssuer` (LE ou CA interna)
- [ ] Configurar MetalLB com pool de IP de PROD (192.168.1.200–219 exemplo)
- [ ] Validar Service LoadBalancer do Ingress Controller com certificado válido
- [x] Decisão de publicação: WireGuard site→VPS (136.243.94.243) + proxy NGINX/Traefik no VPS
- [ ] Aplicar NetworkPolicy permitindo tráfego apenas do IP WG do VPS (ex.: 10.8.0.1) para o namespace `ingress`
- [ ] Ajustar Ingress públicos com annotation external-dns target para 136.243.94.243
- [ ] Criar app de teste (echo) com Ingress `echo.safepurelink.com` e validar via VPS

Entregáveis/DoD
- [ ] Ingress acessível via DNS e TLS ok (cadeia e renovação)
- [ ] DNS público resolvendo para 136.243.94.243 e proxy do VPS encaminhando ao Ingress

---

## Sprint 5 — Storage e Backup (PROD)
Objetivo: provisionamento persistente e proteção de dados.

Tarefas
- [ ] Instalar Longhorn e definir StorageClass padrão
- [ ] Criar/validar réplicas e anti-affinity conforme recursos
- [ ] Instalar Velero com destino S3 (MinIO ou externo) e credenciais restritas
- [ ] Criar jobs de backup (agendamentos por namespaces/aplicações críticas)
- [ ] Executar teste de restore em namespace de prova

Entregáveis/DoD
- [ ] PVCs funcionais e réplicas OK
- [ ] Restore de Velero validado

---

## Sprint 6 — Observabilidade (PROD)
Objetivo: métricas, logs e dashboards operacionais.

Tarefas
- [ ] Instalar Prometheus, kube-state-metrics, node-exporter
- [ ] Instalar Alertmanager com rotas/canais definidos
- [ ] Instalar Grafana com dashboards base (K8s/Nodes/Etcd/Ingress)
- [ ] Instalar Loki + Promtail (ou EFK) com retenção definida
- [ ] Opcional: Tracing (OpenTelemetry + Tempo/Jaeger)
- [ ] (Opcional) Integrar Portainer com logs/métricas para troubleshooting rápido
- [ ] Monitorar túnel WireGuard (site↔VPS) e proxy no VPS (logs/uptime)

Entregáveis/DoD
- [ ] Dashboards e alertas ativos; SLOs mínimos definidos

---

## Sprint 7 — Segurança (PROD)
Objetivo: segurança por padrão e políticas de admissão.

Tarefas
- [ ] Ativar Pod Security Admission (baseline/restricted por namespace)
- [ ] Criar NetworkPolicies padrão deny-all + exceções por app
- [ ] Instalar Kyverno/OPA com políticas: sem privileged, sem `:latest`, limits/requests obrigatórios
- [ ] Implantar External Secrets Operator e integrar com Vault/Secret Manager
- [ ] Pipeline de image scanning (Trivy/Grype) integrado ao CI
- [ ] (Opcional) Implantar Edge Agent do Portainer via Helm com RBAC mínimo; restringir acesso por NetworkPolicy
- [ ] Publicar painéis (Grafana/ArgoCD/Portainer) somente via VPN ou Tunnel + OIDC (Casdoor/oauth2-proxy)
- [ ] Armazenar tokens/segredos (Cloudflare, WG) no Vault e consumir via ESO
- [ ] NetworkPolicy aplicada restringindo IP do VPS; revisar cabeçalhos de segurança no VPS

Entregáveis/DoD
- [ ] Namespaces com PSA, NPs efetivas e políticas de admissão ativas
- [ ] Segredos consumidos via ESO (sem segredos no Git)
- [ ] Acesso administrativo funcionando via VPN (WireGuard/Tailscale) com ACLs/SSO
- [ ] Acesso público HTTP(S) apenas via Tunnel com proteção OIDC quando aplicável

---

## Sprint 8 — GitLab CE, Runners e GitOps
Objetivo: fluxo de CI/CD e GitOps padronizado.

Tarefas
- [ ] Implantar GitLab CE (VM dedicada) com TLS, backup configurado
- [ ] Habilitar GitLab Container Registry e políticas de retenção
- [ ] Instalar GitLab Runner no cluster PROD (executor Kubernetes, permissões mínimas)
- [x] Estruturar repositório Git com `environments/dev|stg|prod` e overlays (Kustomize/Helm)
- [ ] Instalar e bootstrap do Argo CD/Flux apontando para repositórios/overlays de PROD
- [x] Definir política: Portainer apenas para operações pontuais; mudanças persistentes via GitOps (documentar no `copilot_instrutions.md`)

Entregáveis/DoD
- [ ] Pipeline CI publica imagem no Registry e atualiza manifests
- [ ] GitOps sincroniza automaticamente para o cluster PROD sob controle de MR

---

## Sprint 9 — Homologação (STG) para Validação
Objetivo: validar em ambiente próximo ao PROD antes do corte.

Tarefas
- [ ] Repetir baseline do PROD em STG (cp1 + w1): CNI, Ingress, cert-manager, MetalLB, Longhorn, Velero
- [ ] Bootstrap do GitOps em STG (overlays próprios)
- [ ] Restaurar dados amostrados via Velero (se aplicável) e executar smoke/labs
- [ ] Implantar cloudflared também em STG (se necessário) e validar DNS/TLS
- [ ] (Opcional) Conectar STG ao Portainer Server com Edge Agent e validar acesso read-only

Entregáveis/DoD
- [ ] Deploys em STG via GitOps; smoke e testes de carga mínimos aprovados

---

## Sprint 10 — Migração e Cutover (PROD)
Objetivo: publicar aplicações e realizar o corte controlado.

Tarefas
- [ ] Migrar segredos para Vault/ESO; ajustar manifests para referências externas
- [ ] Promover versões aprovadas (STG → PROD) via MR
- [ ] Janela de mudança: freeze, backup final, aplicar via GitOps
- [ ] Smoke tests, canary/rollout e validação de SLOs
- [ ] Plano de rollback documentado e testado (se necessário)

Entregáveis/DoD
- [ ] Tráfego em PROD com SLOs atendidos e observabilidade verde

---

## Sprint 11 — Pós‑produção e Operação
Objetivo: estabilizar, documentar e otimizar custos/capacidade.

Tarefas
- [ ] Documentar runbooks: upgrade k3s, backup/restore, incidentes
- [ ] Ajustar quotas/limits por namespace e budget da observabilidade
- [ ] Testes mensais de restore (Velero, DBs) e auditoria trimestral de RBAC
- [ ] Monitorar capacidade (CPU/RAM/I/O) e ligar w2 em picos conforme política

Entregáveis/DoD
- [ ] Runbooks publicados; rotinas de teste e auditoria calendarizadas

---

## Backlog Técnico (opcional)
- [ ] Agregação de métricas com Thanos/VictoriaMetrics
- [ ] Malha de serviços (Istio/Linkerd) se houver caso de uso real
- [ ] Assinatura de imagens (cosign) e política de verificação em admissão
- [ ] Elasticsearch/Kibana em VM dedicada se I/O do host for gargalo

## Checklist Rápido de Go‑Live (PROD)
- [ ] 3 CPs Ready e etcd saudável; ≥1–2 Ws prontos
- [ ] Ingress + TLS válidos; DNS apontando para LB/MetalLB
- [ ] StorageClass padrão Longhorn e testes de I/O
- [ ] Backups Velero agendados e restore validado
- [ ] Observabilidade e alertas prontos; NPs e políticas de admissão ativas
- [ ] GitOps em modo Sync, pipelines CI/CD operando e versionamento por MR
- [ ] (Se adotado) Portainer Server publicado com HTTPS, RBAC/2FA; Edge Agents conectados; políticas de somente leitura por padrão
- [ ] Acesso externo enterprise: WireGuard/Tailscale operacional; Cloudflare Tunnel ativo; external-dns e cert-manager (DNS-01) ok

---

**Nota:** As tarefas restantes nas sprints e no backlog técnico exigem execução manual ou instruções mais específicas para automação. Por favor, forneça mais detalhes se desejar que eu auxilie em alguma tarefa específica.
