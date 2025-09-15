# 🤖 Scripts de Integração Copilot para Pull Requests

Este diretório contém scripts para facilitar a colaboração entre você e o Copilot na criação e gerenciamento de Pull Requests.

## 📁 Scripts Disponíveis

### 1. `copilot-pr.sh` - Preparação de Sprint
**Uso:** `./copilot-pr.sh <sprint_number>`

Prepara o ambiente para trabalhar em um sprint específico, criando:
- Checklist detalhado das tarefas
- Arquivo de progresso
- Estrutura organizada

**Exemplo:**
```bash
./scripts/copilot-pr.sh 2
```

### 2. `create-sprint-pr.sh` - Criação de PR
**Uso:** `./create-sprint-pr.sh <sprint_number> [description]`

Automatiza a criação de Pull Requests para sprints:
- Cria branch específica
- Faz commit das mudanças
- Cria PR com template padrão

**Exemplo:**
```bash
./scripts/create-sprint-pr.sh 2 "Provisionar VMs e validar k3s"
```

### 3. `pr-workflow.sh` - Gerenciamento Completo
**Uso:** `./pr-workflow.sh <action> [args]`

Script principal para gerenciar todo o workflow de PRs:

#### Ações Disponíveis:
- `create <sprint> [description]` - Criar PR para sprint
- `list` - Listar PRs abertos
- `status` - Status dos PRs e repositório
- `review <pr_number>` - Revisar PR específico
- `merge <pr_number>` - Fazer merge do PR
- `close <pr_number>` - Fechar PR
- `sync` - Sincronizar com remoto
- `cleanup` - Limpar branches antigas

**Exemplos:**
```bash
# Criar PR
./scripts/pr-workflow.sh create 2 "Provisionar VMs"

# Listar PRs
./scripts/pr-workflow.sh list

# Revisar PR
./scripts/pr-workflow.sh review 123

# Fazer merge
./scripts/pr-workflow.sh merge 123
```

## 🚀 Workflow Recomendado

### Iniciando um Sprint
1. **Preparar ambiente:**
   ```bash
   ./scripts/copilot-pr.sh 2
   ```

2. **Revisar checklist:**
   ```bash
   cat sprints/sprint-2/checklist.md
   ```

3. **Implementar tarefas** (com ajuda do Copilot)

4. **Atualizar progresso:**
   ```bash
   # Editar sprints/sprint-2/progress.md conforme avança
   ```

### Criando Pull Request
5. **Fazer commit das mudanças:**
   ```bash
   git add .
   git status  # Revisar mudanças
   ```

6. **Criar PR:**
   ```bash
   ./scripts/pr-workflow.sh create 2 "Provisionar VMs e validar k3s"
   ```

### Gerenciando PRs
7. **Acompanhar status:**
   ```bash
   ./scripts/pr-workflow.sh status
   ```

8. **Fazer merge quando aprovado:**
   ```bash
   ./scripts/pr-workflow.sh merge 123
   ```

## 🔧 Configuração Inicial

### 1. Autenticar GitHub CLI
```bash
gh auth login
```

### 2. Verificar configuração
```bash
gh auth status
```

### 3. Configurar repositório remoto (se necessário)
```bash
git remote add origin https://github.com/seu-usuario/xcloud.git
```

## 💡 Dicas para Trabalhar com Copilot

### ✅ Boas Práticas
- **Seja específico:** "Execute vagrant up e verifique se todas as VMs estão rodando"
- **Compartilhe logs:** Cole saídas de comandos quando houver erros
- **Documente problemas:** Use os arquivos de progresso para registrar issues
- **Use checklists:** Siga os checklists gerados para cada sprint

### 📝 Como Pedir Ajuda
1. **Contexto claro:** "Estou no Sprint 2, tentando provisionar VMs"
2. **Comando executado:** "Executei `vagrant up` e obtive este erro:"
3. **Log do erro:** Cole a saída completa do comando
4. **Objetivo:** "Preciso que todas as VMs estejam rodando para continuar"

### 🔍 Comandos Úteis para Debug
```bash
# Verificar status geral
./scripts/pr-workflow.sh status

# Ver logs detalhados
git log --oneline -10

# Verificar mudanças não commitadas
git status
git diff

# Verificar branches
git branch -a
```

## 📊 Estrutura de Diretórios

```
/opt/k8s/
├── scripts/
│   ├── copilot-pr.sh           # Preparação de sprint
│   ├── create-sprint-pr.sh     # Criação de PR
│   ├── pr-workflow.sh          # Workflow completo
│   └── README.md               # Esta documentação
├── sprints/
│   ├── sprint-1/
│   │   ├── checklist.md        # Checklist do sprint
│   │   └── progress.md         # Progresso e logs
│   └── sprint-2/
│       ├── checklist.md
│       └── progress.md
└── ...
```

## 🤖 Integração com Copilot

Os scripts foram projetados para facilitar nossa colaboração:

1. **Estrutura clara:** Cada sprint tem sua pasta e arquivos organizados
2. **Checklists detalhados:** Sabemos exatamente o que precisa ser feito
3. **Progresso visível:** Posso acompanhar onde você está no sprint
4. **PRs padronizados:** Templates consistentes facilitam reviews
5. **Automação:** Menos trabalho manual, mais foco na implementação

## 🆘 Troubleshooting

### GitHub CLI não autenticado
```bash
gh auth login
# Escolha "GitHub.com"
# Escolha "HTTPS"
# Autentique via browser ou token
```

### Erro de permissão nos scripts
```bash
chmod +x scripts/*.sh
```

### Repositório remoto não configurado
```bash
git remote -v  # Verificar remotos
git remote add origin https://github.com/seu-usuario/xcloud.git
```

---

🎯 **Objetivo:** Tornar a criação e gerenciamento de PRs mais eficiente e colaborativo entre você e o Copilot, mantendo alta qualidade e organização no desenvolvimento dos sprints.