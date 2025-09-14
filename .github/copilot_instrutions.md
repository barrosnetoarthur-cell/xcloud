# Instruções para uso do GitHub Copilot neste repositório

Objetivo
- Padronizar como solicitar e aplicar mudanças com apoio do Copilot para montar e operar os clusters Kubernetes (dev/stg/prod) via GitOps, conforme o `README.md`.

Princípios (derivados do README)
- Ambientes separados (dev, homolog/stg, prod) — nunca misturar.
- Git como fonte única de verdade (GitOps) com promoção por MR (dev → stg → prod).
- Segurança por padrão: PSA, NetworkPolicy, RBAC mínimo, sem segredos no Git (ESO + Vault).
- Observabilidade completa e backups testados.
- Portainer é opcional e serve para apoio operacional (diagnóstico). Mudanças devem ser feitas via GitOps.

Estrutura de pastas recomendada (GitOps)
- environments/
  - base/ → manifests/helm charts compartilhados
  - dev/  → overlays Kustomize ou values Helm específicos
  - stg/
  - prod/
- platform/ → add-ons por cluster (cilium, ingress, cert-manager, external-dns, metallb, longhorn, velero, observability, gitops, security)
- apps/ → aplicações por domínio/projeto (cada uma com base + overlays dev/stg/prod)
- policies/ → Kyverno/OPA, PodSecurity, NetworkPolicies genéricas
- scripts/ → automações (lint/validate/kubeconform/helm/template)
- docs/ → runbooks, decisões, diagramas

Branches e versionamento
- main como linha principal.
- feature/<slug>, fix/<slug>, chore/<slug> para mudanças.
- Conventional Commits (feat, fix, chore, docs, refactor, perf, test, ci, build).

Boas práticas de Git (sempre comitar)
- Faça mudanças atômicas e pequenos MRs.
- Sempre versionar alterações geradas com o Copilot (sem drifts fora do GitOps).
- Commits frequentes, mensagens no padrão Conventional Commits.
- Preferir commits assinados (GPG/SSH) quando possível.
- Evitar arquivos sensíveis (segredos/kubeconfig) — já cobertos no `.gitignore`.
- Exemplo de ciclo local:
  - git checkout -b feature/<slug>
  - git add -A
  - git commit -m "feat: <descrição curta>"
  - git push -u origin feature/<slug>
  - Abrir MR para revisão/merge

MR/PR — regras
- Uma mudança por MR, pequena e revisável.
- Descrição deve conter: objetivo, escopo, impacto, rollout/rollback, validação e links de observabilidade.
- Checklist de segurança e operação concluído (abaixo).

Padrões de Kubernetes (obrigatórios)
- resources: requests/limits em todos os pods.
- probes: readiness/liveness onde aplicável.
- securityContext: sem privileged; drop ALL + add mínimos; fsGroup quando necessário.
- imagens: sem tag :latest; usar registry do GitLab; considerar assinatura (cosign) quando disponível.
- NetworkPolicy: default deny e allow estritamente necessário.
- PSA: rótulos por namespace (baseline/restricted conforme o caso).
- PDB/HPA: onde fizer sentido para disponibilidade e elasticidade.
- Storage: usar StorageClass padrão Longhorn; PVCs com tamanho justificado; anotações de snapshot quando crítico.
- Backups: rótulos/annot para seleção do Velero em namespaces/aplicações críticas.
- Ingress: TLS obrigatório via cert-manager; cabeçalhos de segurança (HSTS) e redirects 80→443.

Segredos
- Nunca commitar Kubernetes Secret com dados sensíveis.
- Usar External Secrets Operator (ESO) + Vault/Secret Manager.
- Manifestos devem referenciar `ExternalSecret`/`SecretStore`/`ClusterSecretStore`.

Validação local (antes do MR)
- kustomize build overlays (dev/stg/prod) sem erros.
- kubeconform/kubeval conforme schemas do cluster.
- helm template (se usar charts) gera YAML válido.
- yamllint/markdownlint passam.

Fluxo GitOps
- Cada cluster roda Argo CD/Flux apontando para `environments/<env>`.
- Promoção por MR: alterar tag/versão nos overlays do ambiente alvo.
- Auditoria nativa do Git (revisões e histórico) + observabilidade pós-deploy.

Ambiente Portainer (se adotado)
- Local: VM dedicada fora dos clusters (`vm-portainer`) com HTTPS e DNS (ex.: `portainer.seu.domínio`).
- Conexão: Edge Agent em cada cluster (Helm). Evitar exposição pública de agents; preferir conexão outbound segura.
- Política: acesso read-only por padrão; perfis de operador com escopo mínimo; registrar qualquer mudança manual e refletir em Git (MR) imediatamente.

Acesso remoto enterprise (sem IP fixo, MikroTik)
- Padrão recomendado
  - Administração: VPN (WireGuard em túnel site→hub com VPS IP fixo) ou Tailscale com Subnet Router e ACLs/SSO.
  - Publicação HTTP(S): Cloudflare Tunnel (cloudflared) + external-dns (Cloudflare) + cert-manager DNS-01.
- Segredos e credenciais
  - Armazenar tokens Cloudflare, chaves WireGuard e credenciais no Vault e consumir via ESO.
  - Não expor portas em WAN quando sob CGNAT; preferir túneis outbound.
- Políticas
  - GUIs (ArgoCD, Grafana, Portainer) restritas a VPN ou Tunnel + OIDC (Casdoor/oauth2-proxy).
  - NetworkPolicies para liberar somente DNS/IdP/Registry/Tunnel necessários.

Checklists para MR/PR
- [ ] Padrões K8s atendidos (limits/requests, probes, securityContext, sem :latest)
- [ ] NetworkPolicies e PSA corretos para os namespaces afetados
- [ ] TLS/Ingress e DNS (se aplicável) configurados e validados
- [ ] PVCs e StorageClass revisados; impacto de I/O considerado
- [ ] Backups/Velero: inclusão ou exclusão consciente; teste de restore planejado
- [ ] Observabilidade: métricas/logs/dashboards/alerts previstos
- [ ] GitOps: overlays atualizados; caminho/branch corretos; diffs revisados
- [ ] Plano de rollout/rollback e smoke tests descritos
- [ ] (Se Portainer for usado) Mudanças manuais documentadas e refletidas nos manifests via MR
- [ ] Tokens/segredos (Cloudflare/WG) referenciados via ESO; sem segredos em YAML plano
- [ ] external-dns e cert-manager DNS-01 validados para os domínios
- [ ] cloudflared funcional e bloqueios de rede ajustados (NPs)
- [ ] GUIs restritas a VPN/Tunnel + OIDC

Como pedir coisas ao Copilot (exemplos de prompts)
- "Crie um overlay Kustomize para `environments/prod` da app X com image tag `v1.2.3`, requests/limits e readiness probe HTTP em `/healthz`."
- "Escreva uma NetworkPolicy deny-all e outra permitindo `app=frontend` → `app=backend` na porta 8080 no namespace `foo`."
- "Gere manifests do cert-manager: ClusterIssuer Let’s Encrypt HTTP-01 usando o Ingress NGINX do cluster." 
- "Crie o manifest do MetalLB IPAddressPool 192.168.1.200-219 e L2Advertisement para PROD."
- "Produza políticas Kyverno proibindo `:latest` e exigindo limits/requests." 
- "Crie um ExternalSecret que leia `kv/prod/appx` do Vault e popule `DATABASE_URL`."
- "Gere manifests Helm/manifest para instalar cloudflared (Cloudflare Tunnel) no namespace `platform/tunnel`, conectando `grafana.seu.domínio` ao Service `grafana` via HTTP." 
- "Crie ExternalSecret para token do Cloudflare em `platform/tunnel` e referencie no Deployment do cloudflared." 
- "Configure external-dns para provider Cloudflare com API Token de escopo mínimo e domínio `seu.domínio`."
- "Crie Issuer/ClusterIssuer do cert-manager usando solver DNS-01 do Cloudflare." 
- "Forneça configuração WireGuard (peer MikroTik ↔ VPS) e rotas para rede 192.168.1.0/24, com notas para armazenar chaves no Vault via ESO." 
- "Crie NetworkPolicies permitindo egress do namespace `platform/tunnel` para endpoints do Cloudflare e DNS apenas."

Roteiro por sprints
- Seguir o `TODOS.md` (Sprints 0–11). Cada MR deve referenciar a sprint e tarefa.

Integração CI/CD (alto nível)
- Pipeline: lint → validate (kustomize/kubeconform/helm) → security scan → publish (se app) → atualizar overlays (via MR) → GitOps aplica.

Operação pós-deploy
- Smoke tests; verificação de SLOs (latência p95/p99, taxa de erro, saturação).
- Se falhar: rollback do MR + restore (se necessário) + post-mortem.

Runbooks essenciais (docs/)
- Upgrade k3s; backup/restore Velero; rotinas de observabilidade; procedimentos de incidentes.

Referências do README
- Seções 2–7 (GitOps, Rede/Ingress, Storage/Backup, Observabilidade, Segurança)
- Seção 8 (Plano de migração) e 9 (Guia de instalação k3s)
- Seção 13 e 16 (VirtualBox/Vagrant e capacidade do host)
- Seção 7 (Gestão/Portainer) e 13/16 (VM dedicada para Portainer)
- Seções 3, 7, 9, 13, 16 e 17 (rede, Portainer e acesso remoto/VPN)

Nota
- Ajuste nomes de domínios, VIPs e ranges MetalLB conforme realidade local descrita no `README.md`.
