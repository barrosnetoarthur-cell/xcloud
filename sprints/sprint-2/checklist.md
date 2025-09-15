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
