#!/bin/bash
set -euo pipefail

# Script para criar Pull Requests automatizados por sprint
# Uso: ./create-sprint-pr.sh <sprint_number> <description>

SPRINT_NUMBER=${1:-}
DESCRIPTION=${2:-}

if [[ -z "$SPRINT_NUMBER" ]]; then
    echo "❌ Uso: $0 <sprint_number> [description]"
    echo "Exemplo: $0 2 'Provisionar VMs e validar k3s'"
    exit 1
fi

# Configurações
BRANCH_NAME="sprint-${SPRINT_NUMBER}"
BASE_BRANCH="main"
PR_TITLE="Sprint ${SPRINT_NUMBER}: ${DESCRIPTION:-Implementação}"

echo "🚀 Criando PR para Sprint ${SPRINT_NUMBER}..."

# Verificar se estamos no diretório correto
if [[ ! -f "TODOS.md" ]]; then
    echo "❌ Execute este script no diretório raiz do projeto (onde está TODOS.md)"
    exit 1
fi

# Verificar se gh está autenticado
if ! gh auth status &>/dev/null; then
    echo "⚠️  GitHub CLI não está autenticado. Execute: gh auth login"
    exit 1
fi

# Verificar se há mudanças para commit
if git diff --quiet && git diff --cached --quiet; then
    echo "⚠️  Nenhuma mudança detectada. Adicione suas alterações primeiro."
    exit 1
fi

# Criar e fazer checkout da branch
echo "🌿 Criando branch ${BRANCH_NAME}..."
git checkout -B "$BRANCH_NAME"

# Adicionar todas as mudanças
echo "📦 Adicionando mudanças..."
git add .

# Commit com mensagem padrão
COMMIT_MSG="Sprint ${SPRINT_NUMBER}: ${DESCRIPTION:-Implementação}

- Implementação dos requisitos do Sprint ${SPRINT_NUMBER}
- Atualizações de documentação e configurações
- Testes e validações incluídos

Refs: Sprint ${SPRINT_NUMBER} do TODOS.md"

git commit -m "$COMMIT_MSG"

# Push da branch
echo "🔼 Fazendo push da branch..."
git push -u origin "$BRANCH_NAME"

# Criar template do PR
PR_BODY="## 🎯 Sprint ${SPRINT_NUMBER}: ${DESCRIPTION:-Implementação}

### 📋 Checklist do Sprint
- [ ] Todos os requisitos do Sprint ${SPRINT_NUMBER} implementados
- [ ] Documentação atualizada
- [ ] Testes executados com sucesso
- [ ] Configurações validadas

### 🔧 Mudanças Principais
<!-- Descreva as principais mudanças implementadas -->

### 🧪 Como Testar
\`\`\`bash
# Comandos para testar as implementações
\`\`\`

### 📚 Documentação
- [ ] README.md atualizado se necessário
- [ ] DEPLOYMENT.md atualizado se necessário
- [ ] Comentários no código adicionados

### 🔗 Issues Relacionadas
- Refs: Sprint ${SPRINT_NUMBER} do TODOS.md

---
*Este PR foi criado automaticamente usando create-sprint-pr.sh*"

# Criar o PR
echo "📝 Criando Pull Request..."
PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --base "$BASE_BRANCH" \
    --head "$BRANCH_NAME" \
    --draft)

echo "✅ Pull Request criado com sucesso!"
echo "🔗 URL: $PR_URL"
echo ""
echo "📝 Próximos passos:"
echo "1. Edite a descrição do PR se necessário"
echo "2. Adicione reviewers se necessário"
echo "3. Marque como pronto quando finalizado: gh pr ready"
echo "4. Para merge: gh pr merge --squash --delete-branch"

# Voltar para a branch main
git checkout "$BASE_BRANCH"