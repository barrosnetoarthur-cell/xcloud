#!/bin/bash
set -euo pipefail

# Script para gerenciar workflow completo de PRs
# Uso: ./pr-workflow.sh <action> [args...]

ACTION=${1:-help}

show_help() {
    echo "🔄 Gerenciador de Workflow de Pull Requests"
    echo ""
    echo "Uso: $0 <action> [args...]"
    echo ""
    echo "Ações disponíveis:"
    echo "  create <sprint> [description]  - Criar PR para sprint"
    echo "  list                          - Listar PRs abertos"
    echo "  status                        - Status dos PRs"
    echo "  review <pr_number>            - Revisar PR específico"
    echo "  merge <pr_number>             - Fazer merge do PR"
    echo "  close <pr_number>             - Fechar PR"
    echo "  sync                          - Sincronizar com remoto"
    echo "  cleanup                       - Limpar branches antigas"
    echo ""
    echo "Exemplos:"
    echo "  $0 create 2 'Provisionar VMs'"
    echo "  $0 list"
    echo "  $0 merge 123"
}

create_pr() {
    local sprint_number=$1
    local description=${2:-"Implementação"}
    
    echo "🚀 Criando PR para Sprint ${sprint_number}..."
    ./scripts/create-sprint-pr.sh "$sprint_number" "$description"
}

list_prs() {
    echo "📋 Pull Requests abertos:"
    echo ""
    gh pr list --state open
}

show_status() {
    echo "📊 Status do repositório:"
    echo ""
    echo "🌿 Branch atual: $(git branch --show-current)"
    echo "📦 Status do Git:"
    git status --short
    echo ""
    echo "📋 PRs abertos:"
    gh pr list --state open --limit 5
    echo ""
    echo "🏷️  Últimas tags:"
    git tag --sort=-version:refname | head -5 || echo "Nenhuma tag encontrada"
}

review_pr() {
    local pr_number=$1
    echo "👀 Revisando PR #${pr_number}..."
    
    # Mostrar detalhes do PR
    gh pr view "$pr_number"
    echo ""
    
    # Fazer checkout da branch do PR
    gh pr checkout "$pr_number"
    echo ""
    echo "✅ Branch do PR #${pr_number} ativa. Você pode agora:"
    echo "  - Testar as mudanças"
    echo "  - Fazer review do código"
    echo "  - Adicionar comentários: gh pr comment ${pr_number} --body 'Comentário'"
}

merge_pr() {
    local pr_number=$1
    echo "🔄 Fazendo merge do PR #${pr_number}..."
    
    # Verificar se o PR está pronto
    if gh pr view "$pr_number" --json isDraft --jq '.isDraft' | grep -q true; then
        echo "⚠️  PR #${pr_number} ainda está em draft. Marque como pronto primeiro:"
        echo "gh pr ready ${pr_number}"
        exit 1
    fi
    
    # Fazer merge
    gh pr merge "$pr_number" --squash --delete-branch
    echo "✅ PR #${pr_number} merged com sucesso!"
    
    # Voltar para main e atualizar
    git checkout main
    git pull origin main
}

close_pr() {
    local pr_number=$1
    echo "❌ Fechando PR #${pr_number}..."
    gh pr close "$pr_number"
    echo "✅ PR #${pr_number} fechado."
}

sync_repo() {
    echo "🔄 Sincronizando repositório..."
    
    # Salvar branch atual
    current_branch=$(git branch --show-current)
    
    # Ir para main e atualizar
    git checkout main
    git pull origin main
    
    # Limpar branches merged
    git branch --merged | grep -v "\*\|main\|master" | xargs -n 1 git branch -d 2>/dev/null || true
    
    # Voltar para branch original se não for main
    if [[ "$current_branch" != "main" ]]; then
        git checkout "$current_branch"
    fi
    
    echo "✅ Repositório sincronizado!"
}

cleanup_branches() {
    echo "🧹 Limpando branches antigas..."
    
    # Branches locais merged
    echo "Removendo branches locais já merged:"
    git branch --merged | grep -v "\*\|main\|master" | xargs -n 1 git branch -d 2>/dev/null || true
    
    # Branches remotas que não existem mais
    echo "Limpando referências remotas:"
    git remote prune origin
    
    echo "✅ Limpeza concluída!"
}

# Verificar se gh está disponível e autenticado
check_gh() {
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI (gh) não está instalado."
        echo "Instale com: sudo apt install gh"
        exit 1
    fi
    
    if ! gh auth status &>/dev/null; then
        echo "❌ GitHub CLI não está autenticado."
        echo "Execute: gh auth login"
        exit 1
    fi
}

# Main
case "$ACTION" in
    create)
        check_gh
        sprint_number=${2:-}
        description=${3:-}
        if [[ -z "$sprint_number" ]]; then
            echo "❌ Especifique o número do sprint"
            echo "Uso: $0 create <sprint_number> [description]"
            exit 1
        fi
        create_pr "$sprint_number" "$description"
        ;;
    list)
        check_gh
        list_prs
        ;;
    status)
        check_gh
        show_status
        ;;
    review)
        check_gh
        pr_number=${2:-}
        if [[ -z "$pr_number" ]]; then
            echo "❌ Especifique o número do PR"
            echo "Uso: $0 review <pr_number>"
            exit 1
        fi
        review_pr "$pr_number"
        ;;
    merge)
        check_gh
        pr_number=${2:-}
        if [[ -z "$pr_number" ]]; then
            echo "❌ Especifique o número do PR"
            echo "Uso: $0 merge <pr_number>"
            exit 1
        fi
        merge_pr "$pr_number"
        ;;
    close)
        check_gh
        pr_number=${2:-}
        if [[ -z "$pr_number" ]]; then
            echo "❌ Especifique o número do PR"
            echo "Uso: $0 close <pr_number>"
            exit 1
        fi
        close_pr "$pr_number"
        ;;
    sync)
        sync_repo
        ;;
    cleanup)
        cleanup_branches
        ;;
    help|*)
        show_help
        ;;
esac