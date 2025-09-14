# External Secrets Operator (ESO)
- Armazene tokens/segredos (ex.: Cloudflare API, WireGuard keys) no Vault.
- Crie `ClusterSecretStore` apontando para o Vault.
- Referencie via `ExternalSecret` nos namespaces (ex.: `platform/tunnel`).
