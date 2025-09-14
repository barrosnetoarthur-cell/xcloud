# Runbook — Estratégia de Cutover e Rollback

## Objetivo
Definir um plano claro para a migração de workloads para o novo cluster de produção e, em caso de falha, um procedimento de rollback.

## Premissas
- Novo cluster PROD (k3s HA) e STG (k3s) estão operacionais e validados.
- GitOps (Argo CD/Flux) configurado e sincronizando manifests.
- Observabilidade (Prometheus/Grafana) ativa e monitorando SLOs.
- Backups (Velero) configurados e testados.
- Acesso administrativo via WireGuard/Tailscale ao cluster e VPS.
- DNS externo (Cloudflare) configurado para apontar para o VPS (136.243.94.243).

## Janela de Mudança (Cutover)
- **Data/Hora:** [Definir data e hora com equipe]
- **Duração Estimada:** [Ex: 2-4 horas]
- **Impacto:** Indisponibilidade temporária de serviços durante a transição de DNS.

## Plano de Cutover
1. **Pré-cutover (1 semana antes)**
   - [ ] Revisar e validar todos os manifests da aplicação no ambiente STG.
   - [ ] Executar testes de carga e smoke tests exaustivos em STG.
   - [ ] Confirmar que todos os segredos estão no Vault e referenciados via ESO.
   - [ ] Testar o processo de backup/restore com Velero em um namespace de teste.
   - [ ] Comunicar a janela de mudança a todas as partes interessadas.
   - [ ] Garantir que o TTL do DNS para `safepurelink.com` e subdomínios esteja baixo (ex: 5 minutos).

2. **Início da Janela de Mudança (D-Day)**
   - [ ] **Freeze:** Proibir novos deploys ou alterações no cluster antigo e no GitOps.
   - [ ] **Backup Final:** Executar backup completo do cluster antigo (etcd, PVCs, etc.) e do novo cluster PROD (Velero).
   - [ ] **Desligar Workloads Antigos (Opcional):** Se houver risco de split-brain ou escrita dupla, escalar workloads antigos para 0 réplicas.
   - [ ] **Promover Manifests:** No repositório GitOps, criar um Merge Request (MR) para promover as versões da aplicação de STG para PROD.
     - [ ] Revisar e mergear o MR.
     - [ ] Verificar se o Argo CD/Flux inicia a sincronização no cluster PROD.
   - [ ] **Validação Inicial:** Monitorar logs e métricas no novo cluster. Verificar `kubectl get pods`, `services`, `ingresses`.

3. **Cutover de Tráfego (DNS)**
   - [ ] **Atualizar DNS:** No Cloudflare, alterar os registros DNS (A/CNAME) para apontar para o IP público do VPS (136.243.94.243).
   - [ ] **Monitorar Propagação:** Usar ferramentas como `dig` ou `nslookup` para verificar a propagação do DNS.
   - [ ] **Smoke Tests Pós-DNS:** Executar testes de ponta a ponta nos serviços publicados (via navegador, curl).
   - [ ] **Monitorar SLOs:** Acompanhar métricas de latência, erro e saturação no Grafana.

4. **Pós-cutover**
   - [ ] **Desativar Cluster Antigo:** Após confirmação de estabilidade, desativar ou desprovisionar o cluster antigo.
   - [ ] **Comunicar Sucesso:** Informar as partes interessadas sobre a conclusão da migração.
   - [ ] **Post-mortem:** Realizar uma reunião de post-mortem para documentar lições aprendidas.

## Plano de Rollback
**Gatilho:** Falha crítica ou degradação inaceitável de serviço durante ou após o cutover que não pode ser resolvida rapidamente no novo ambiente.

1. **Decisão de Rollback:** A equipe de operação/desenvolvimento decide pelo rollback.

2. **Rollback de Tráfego (DNS)**
   - [ ] **Reverter DNS:** No Cloudflare, alterar os registros DNS (A/CNAME) para apontar de volta para o ambiente antigo (se ainda ativo) ou para uma página de manutenção.
   - [ ] **Monitorar Propagação:** Verificar a propagação do DNS.

3. **Reativação do Ambiente Antigo (se aplicável)**
   - [ ] Se o cluster antigo foi desligado, reativá-lo.
   - [ ] Restaurar backup do cluster antigo (se necessário).
   - [ ] Escalar workloads antigos para o estado operacional.

4. **Análise Pós-Rollback:**
   - [ ] Investigar a causa raiz da falha no novo ambiente.
   - [ ] Planejar correção e novo cutover.

## Checklist Rápido de Cutover
- [ ] Comunicação enviada
- [ ] TTL DNS baixo
- [ ] Freeze de deploys
- [ ] Backup final do antigo e novo
- [ ] MR de promoção mergeado
- [ ] Sincronização GitOps verificada
- [ ] DNS atualizado para VPS (136.243.94.243)
- [ ] Propagação DNS verificada
- [ ] Smoke tests pós-DNS OK
- [ ] SLOs monitorados e verdes

## Checklist Rápido de Rollback
- [ ] Decisão de rollback tomada
- [ ] DNS revertido
- [ ] Propagação DNS verificada
- [ ] Ambiente antigo reativado/restaurado (se aplicável)
- [ ] Análise de causa raiz iniciada
