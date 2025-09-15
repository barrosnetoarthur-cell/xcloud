#!/bin/bash
set -euo pipefail

# Script de integração Copilot - facilita a criação de PRs com minha ajuda
# Uso: ./copilot-pr.sh <sprint_number>

SPRINT_NUMBER=${1:-}

if [[ -z "$SPRINT_NUMBER" ]]; then
    echo "❌ Uso: $0 <sprint_number>"
    echo "Exemplo: $0 2"
    exit 1
fi

echo "🤖 Preparando ambiente para Sprint ${SPRINT_NUMBER} com assistência do Copilot..."

# Criar diretório de trabalho para o sprint se não existir
SPRINT_DIR="sprints/sprint-${SPRINT_NUMBER}"
mkdir -p "$SPRINT_DIR"

# Criar arquivo de checklist específico do sprint
CHECKLIST_FILE="${SPRINT_DIR}/checklist.md"

# Gerar checklist baseado no sprint
generate_checklist() {
    case "$SPRINT_NUMBER" in
        2)
            cat > "$CHECKLIST_FILE" << 'EOF'
# Sprint 2: Provisionar VMs e Validar k3s

## 📋 Checklist de Tarefas

### Provisionar VMs
- [ ] Executar `vagrant up` para todas as VMs
- [ ] Verificar status de todas as VMs: `vagrant status`
- [ ] Testar conectividade SSH: `vagrant ssh prod-cp1`
- [ ] Verificar recursos (CPU, RAM, Disk) das VMs

### Validar k3s
- [ ] Verificar se k3s está rodando: `systemctl status k3s`
- [ ] Testar kubectl: `kubectl get nodes`
- [ ] Verificar cluster health: `kubectl get pods -A`
- [ ] Validar API server accessibility

### Testes de Conectividade
- [ ] Ping entre VMs
- [ ] Resolução DNS
- [ ] Conectividade de rede do cluster

### Documentação
- [ ] Atualizar README.md com status do Sprint 2
- [ ] Documentar problemas encontrados e soluções
- [ ] Screenshots/logs de evidência

## 🔧 Comandos Úteis

```bash
# Verificar status das VMs
vagrant status

# SSH nas VMs
vagrant ssh prod-cp1
vagrant ssh prod-w1
vagrant ssh stg-cp1
vagrant ssh stg-w1

# Verificar k3s
kubectl get nodes -o wide
kubectl get pods -A
kubectl cluster-info
```

## 📝 Notas
<!-- Adicione suas observações aqui -->
EOF
            ;;
        3)
            cat > "$CHECKLIST_FILE" << 'EOF'
# Sprint 3: Configurar kube-vip

## 📋 Checklist de Tarefas

### Instalar kube-vip
- [ ] Deploy do kube-vip nos control planes
- [ ] Configurar VIPs (192.168.56.200 para PROD, 192.168.56.210 para STG)
- [ ] Testar failover do VIP

### Validar Configuração
- [ ] Ping para os VIPs
- [ ] Kubectl via VIP
- [ ] Testar alta disponibilidade

### Testes
- [ ] Simular falha de um control plane
- [ ] Verificar se VIP migra corretamente
- [ ] Testar conectividade durante failover

## 🔧 Comandos Úteis

```bash
# Testar VIPs
ping 192.168.56.200  # PROD
ping 192.168.56.210  # STG

# Kubectl via VIP
kubectl --server=https://192.168.56.200:6443 get nodes
```
EOF
            ;;
        4)
            cat > "$CHECKLIST_FILE" << 'EOF'
# Sprint 4: Rede e Ingress + TLS e LoadBalancer

## 📋 Checklist de Tarefas

### CNI (Cilium)
- [ ] Instalar Cilium
- [ ] Configurar network policies
- [ ] Verificar conectividade entre pods

### Ingress Controller (NGINX)
- [ ] Deploy do NGINX Ingress Controller
- [ ] Testar roteamento HTTP/HTTPS
- [ ] Configurar exemplo de aplicação

### cert-manager
- [ ] Instalar cert-manager
- [ ] Configurar ClusterIssuer
- [ ] Testar geração automática de certificados

### MetalLB
- [ ] Instalar MetalLB
- [ ] Configurar IP pools
- [ ] Testar LoadBalancer services

## 🔧 Comandos Úteis

```bash
# Verificar Cilium
cilium status
kubectl get pods -n kube-system -l k8s-app=cilium

# Verificar Ingress
kubectl get pods -n ingress-nginx
kubectl get ingress

# Verificar cert-manager
kubectl get pods -n cert-manager
kubectl get certificates

# Verificar MetalLB
kubectl get pods -n metallb-system
kubectl get svc --field-selector spec.type=LoadBalancer
```
EOF
            ;;
        *)
            cat > "$CHECKLIST_FILE" << EOF
# Sprint ${SPRINT_NUMBER}: Implementação

## 📋 Checklist de Tarefas

### Tarefas Principais
- [ ] Tarefa 1
- [ ] Tarefa 2
- [ ] Tarefa 3

### Validação
- [ ] Testes executados
- [ ] Documentação atualizada
- [ ] Configurações validadas

### Documentação
- [ ] README.md atualizado
- [ ] Logs e evidências coletados

## 🔧 Comandos Úteis

\`\`\`bash
# Comandos específicos do sprint
\`\`\`

## 📝 Notas
<!-- Adicione suas observações aqui -->
EOF
            ;;
    esac
}

# Gerar checklist
generate_checklist

# Criar arquivo de progresso
PROGRESS_FILE="${SPRINT_DIR}/progress.md"
cat > "$PROGRESS_FILE" << EOF
# Progresso do Sprint ${SPRINT_NUMBER}

## 📊 Status Atual
- **Iniciado em:** $(date)
- **Status:** Em andamento
- **Progresso:** 0%

## 📝 Log de Atividades

### $(date)
- Sprint ${SPRINT_NUMBER} iniciado
- Checklist criado
- Ambiente preparado

## 🔍 Problemas Encontrados
<!-- Documente problemas aqui -->

## ✅ Soluções Implementadas
<!-- Documente soluções aqui -->

## 📋 Próximos Passos
1. Revisar checklist
2. Executar tarefas do sprint
3. Validar implementações
4. Criar Pull Request
EOF

echo "✅ Ambiente preparado para Sprint ${SPRINT_NUMBER}!"
echo ""
echo "📁 Arquivos criados:"
echo "  - ${CHECKLIST_FILE}"
echo "  - ${PROGRESS_FILE}"
echo ""
echo "🚀 Próximos passos:"
echo "1. Revisar checklist: cat ${CHECKLIST_FILE}"
echo "2. Implementar tarefas do sprint"
echo "3. Atualizar progresso em: ${PROGRESS_FILE}"
echo "4. Quando finalizar, criar PR: ./scripts/pr-workflow.sh create ${SPRINT_NUMBER}"
echo ""
echo "💡 Dicas para trabalhar comigo:"
echo "  - Use comandos claros e específicos"
echo "  - Documente problemas encontrados"
echo "  - Compartilhe logs quando houver erros"
echo "  - Mantenha o progresso atualizado"
echo ""
echo "🤖 Estou pronto para ajudar! Apenas me informe:"
echo "  - O que você está tentando fazer"
echo "  - Quais comandos executou"
echo "  - Quais erros encontrou"