
# AR-12 — Secrets Management

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-12_SECRETS_MANAGEMENT.md

---

# 1. Objetivo

Definir a estratégia de gerenciamento de segredos do BORAH, garantindo que credenciais, tokens, chaves e certificados sejam armazenados, distribuídos e utilizados de forma segura durante todo o ciclo de vida da aplicação.

---

# 2. Escopo

Este documento abrange:

- Variáveis de ambiente
- API Keys
- Tokens
- Certificados
- Credenciais de serviços
- Chaves criptográficas

---

# 3. Princípios

- Menor privilégio
- Zero Trust
- Rotação periódica
- Segregação por ambiente
- Auditoria
- Nunca versionar segredos

---

# 4. Classificação

| Tipo | Exemplos |
|-------|----------|
| Público | URLs públicas |
| Interno | Configurações não sensíveis |
| Confidencial | API Keys |
| Restrito | Service Role Keys, certificados |

---

# 5. Ambientes

Cada ambiente deverá possuir segredos independentes:

- Development
- Staging
- Production

Nunca reutilizar credenciais entre ambientes.

---

# 6. Variáveis de Ambiente

Arquivos previstos:

```text
.env.example
.env.local
.env.development
.env.staging
.env.production
```

Somente `.env.example` poderá ser versionado.

---

# 7. Principais Segredos

- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY
- GOOGLE_PLACES_API_KEY
- FCM_SERVER_KEY
- JWT_SECRET (quando aplicável)

---

# 8. Armazenamento

Utilizar:

- GitHub Secrets
- Secrets do Supabase
- Variáveis do ambiente local

Nunca armazenar segredos em código-fonte.

---

# 9. Rotação

Toda credencial deve possuir plano de rotação.

Situações:

- Vazamento
- Expiração
- Mudança de fornecedor
- Rotina preventiva

---

# 10. Controle de Acesso

Aplicar:

- Menor privilégio
- Acesso baseado em função
- Registro de alterações
- Revisão periódica

---

# 11. Uso no Flutter

O aplicativo nunca deverá conter:

- Service Role Key
- Tokens administrativos
- Credenciais privadas

Somente informações apropriadas para clientes.

---

# 12. Uso nas Edge Functions

As Edge Functions poderão acessar:

- Secrets do Supabase
- Credenciais de integrações
- Tokens administrativos

Sempre através de variáveis de ambiente.

---

# 13. Auditoria

Registrar:

- Criação
- Alteração
- Revogação
- Rotação
- Acessos administrativos

---

# 14. Incidentes

Em caso de vazamento:

1. Revogar a credencial.
2. Gerar nova chave.
3. Atualizar ambientes.
4. Validar funcionamento.
5. Registrar o incidente.

---

# 15. Segurança

- HTTPS obrigatório
- Criptografia em trânsito
- Criptografia em repouso quando suportado
- Segredos mascarados em logs

---

# 16. Boas Práticas

- Utilizar nomes padronizados.
- Remover segredos obsoletos.
- Revisar permissões regularmente.
- Documentar proprietários de cada segredo.

---

# 17. Anti-patterns

Evitar:

- Chaves em commits
- Segredos em prints
- Compartilhamento por chat
- Mesma chave para múltiplos ambientes
- Credenciais permanentes sem rotação

---

# 18. Critérios de Aceite

- Segredos separados por ambiente
- Política de rotação definida
- Controle de acesso documentado
- Auditoria prevista
- Flutter sem credenciais críticas

---

# 19. Checklist

- Ambientes separados
- .env.example criado
- GitHub Secrets configurado
- Secrets do Supabase definidos
- Política de rotação documentada
- Auditoria prevista
- Incidentes documentados
- Anti-patterns registrados
