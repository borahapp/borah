
# AR-09 — Edge Functions

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-09_EDGE_FUNCTIONS.md

---

# 1. Objetivo

Definir a arquitetura, organização e padrões para desenvolvimento das Edge Functions do BORAH utilizando Supabase Edge Functions (Deno), centralizando regras de negócio que não devem ser executadas no cliente.

---

# 2. Objetivos

- Segurança
- Escalabilidade
- Reutilização
- Baixo acoplamento
- Observabilidade
- Facilidade de manutenção

---

# 3. Quando utilizar

As Edge Functions deverão ser utilizadas para:

- Integrações externas
- Webhooks
- Processamentos assíncronos
- Validações críticas
- Agendamentos
- Envio de notificações
- Operações administrativas

Evitar mover lógica simples que possa ser executada diretamente pelo Supabase.

---

# 4. Arquitetura

```text
Flutter
   │
   ▼
Supabase SDK
   │
   ▼
Edge Function
   │
 ┌─┴───────────────┐
 ▼                 ▼
PostgreSQL    Serviços Externos
```

---

# 5. Estrutura

```text
backend/
└── supabase/
    └── functions/
        ├── shared/
        ├── auth/
        ├── notifications/
        ├── rankings/
        ├── integrations/
        ├── scheduler/
        └── webhooks/
```

---

# 6. Organização

Cada função deverá conter:

- index.ts
- validações
- regras de negócio
- tratamento de erros
- logs

---

# 7. Convenções

Nome das funções:

- kebab-case

Exemplos:

- send-notification
- update-ranking
- process-checkin
- sync-restaurants

---

# 8. Autenticação

- Validar JWT em todas as funções protegidas.
- Verificar permissões antes da execução.
- Nunca confiar em dados enviados pelo cliente.

---

# 9. Integrações

As integrações deverão utilizar:

- Timeout
- Retry controlado
- Logs
- Tratamento de falhas

Exemplos:

- Google Places
- Firebase Cloud Messaging
- APIs futuras

---

# 10. Tratamento de Erros

Padronizar respostas:

- 200 OK
- 201 Created
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 500 Internal Server Error

Nunca expor detalhes internos ao cliente.

---

# 11. Observabilidade

Registrar:

- Tempo de execução
- Usuário autenticado
- Erros
- Integrações externas
- Consumo de recursos

---

# 12. Segurança

- Secrets em variáveis de ambiente
- Menor privilégio possível
- Rate limiting quando aplicável
- Sanitização das entradas
- Validação de payloads

---

# 13. Performance

Boas práticas:

- Funções pequenas
- Execução rápida
- Evitar consultas desnecessárias
- Reutilizar código compartilhado
- Cache quando apropriado

---

# 14. Testes

Cada função deverá possuir:

- Testes unitários
- Testes de integração
- Cenários de erro
- Casos de autenticação

---

# 15. Versionamento

- Alterações compatíveis sempre que possível.
- Mudanças breaking devem ser documentadas.
- Utilizar migrações e releases coordenadas.

---

# 16. Boas Práticas

- Uma responsabilidade por função.
- Compartilhar utilitários em `shared/`.
- Documentar entradas e saídas.
- Manter funções independentes.

---

# 17. Anti-patterns

Evitar:

- Funções monolíticas
- Lógica duplicada
- Secrets no código
- Consultas pesadas sem otimização
- Respostas inconsistentes

---

# 18. Critérios de Aceite

- Estrutura documentada
- Convenções definidas
- Segurança aplicada
- Observabilidade prevista
- Estratégia de testes estabelecida

---

# 19. Checklist

- Estrutura criada
- Convenções definidas
- Autenticação prevista
- Logs planejados
- Tratamento de erros padronizado
- Integrações documentadas
- Testes definidos
- Boas práticas registradas
