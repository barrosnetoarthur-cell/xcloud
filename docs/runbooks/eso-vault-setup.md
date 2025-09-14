# Runbook — ESO + Vault Setup

Pré-requisitos
- Vault acessível em https://vault.safepurelink.com (ajuste URL se necessário)
- Auth Kubernetes habilitado no Vault (path: auth/kubernetes)
- Role `eso` criada e vinculada a uma policy mínima
- External Secrets Operator instalado no cluster (namespace `external-secrets`)

Passos no Vault (exemplo)
1. Habilitar engine KV v2 (se ainda não):
   - path: `kv`
2. Habilitar auth Kubernetes (se ainda não):
   - path: `auth/kubernetes`
3. Configurar o auth Kubernetes com o issuer do cluster e CA:
   - kubernetes_host: https://<VIP>:6443
   - kubernetes_ca_cert: <CA do cluster>
   - token_reviewer_jwt: <JWT de SA reviewer>
4. Criar policy mínima (ex.: `eso-read-kv`):
```
path "kv/data/prod/*" {
  capabilities = ["read"]
}
```
5. Criar role `eso` vinculada à service account `external-secrets` do namespace `external-secrets`:
```
vault write auth/kubernetes/role/eso \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=eso-read-kv \
  ttl=1h
```
6. Gravar segredos (exemplos):
```
vault kv put kv/prod/cloudflare/api apiToken=<TOKEN_CLOUDFLARE_ROTACIONADO>
vault kv put kv/prod/cloudflare/tunnel token=<TOKEN_TUNNEL>
```

K8s — ClusterSecretStore
- Arquivo: `platform/security/eso/clustersecretstore-vault.yaml`
- Ajuste `server:` para o endpoint do Vault e `mountPath`/`role` conforme configurado.

Validação
- Aplique kustomize do ESO e dos ExternalSecrets (cloudflared, external-dns, cert-manager)
- Verifique se os Secrets foram criados a partir do Vault
