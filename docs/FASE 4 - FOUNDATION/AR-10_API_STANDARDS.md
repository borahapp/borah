
# AR-10 — API Standards

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-10_API_STANDARDS.md

---

# 1. Objetivo

Definir o padrão oficial para desenvolvimento, documentação e evolução das APIs do BORAH, garantindo consistência, segurança, previsibilidade e facilidade de integração.

---

# 2. Princípios

- RESTful
- Versionamento explícito
- Contratos estáveis
- Consistência
- Segurança por padrão
- Compatibilidade retroativa sempre que possível

---

# 3. Arquitetura

```text
Flutter
   │
   ▼
Repository
   │
   ▼
Datasource
   │
   ▼
API / Edge Function
   │
   ▼
PostgreSQL
```

---

# 4. Versionamento

Todas as APIs deverão possuir versão.

Exemplo:

```text
/v1/auth/login
/v1/groups
/v1/events
```

Mudanças incompatíveis deverão gerar uma nova versão.

---

# 5. Convenções de Endpoints

Recursos no plural e em `kebab-case`.

Exemplos:

- GET /v1/groups
- POST /v1/groups
- GET /v1/groups/{id}
- PATCH /v1/groups/{id}
- DELETE /v1/groups/{id}

Evitar verbos na URL.

---

# 6. Métodos HTTP

| Método | Finalidade |
|---------|------------|
| GET | Consultar |
| POST | Criar |
| PUT | Substituir |
| PATCH | Atualizar parcialmente |
| DELETE | Remover |

---

# 7. Formato de Requisição

- JSON UTF-8
- Content-Type: application/json
- Validação de entrada obrigatória

---

# 8. Formato de Resposta

## Sucesso

```json
{
  "data": {},
  "meta": {}
}
```

## Erro

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Recurso não encontrado."
  }
}
```

---

# 9. Códigos HTTP

- 200 OK
- 201 Created
- 204 No Content
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 422 Unprocessable Entity
- 429 Too Many Requests
- 500 Internal Server Error

---

# 10. Paginação

Padrão:

- page
- limit

Resposta:

```json
{
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150
  }
}
```

---

# 11. Filtros

Utilizar query parameters.

Exemplos:

```text
GET /v1/restaurants?city=Campinas
GET /v1/events?status=active
```

---

# 12. Ordenação

Parâmetro:

```text
sort=name
sort=-created_at
```

Sinal "-" indica ordem decrescente.

---

# 13. Autenticação

- JWT Bearer Token
- HTTPS obrigatório
- Refresh Token via Supabase Auth

---

# 14. Idempotência

Operações críticas deverão suportar idempotência quando aplicável.

Exemplos:

- pagamentos futuros
- criação de eventos
- integrações externas

---

# 15. Rate Limiting

Aplicar limites por:

- IP
- Usuário
- Endpoint

Retornar HTTP 429 quando excedido.

---

# 16. Documentação

Toda API deverá possuir documentação OpenAPI.

Informações mínimas:

- Endpoint
- Método
- Parâmetros
- Corpo
- Respostas
- Exemplos
- Erros

---

# 17. Segurança

- Sanitização de entradas
- Validação de payload
- Menor privilégio
- Logs de auditoria
- Nunca expor dados sensíveis

---

# 18. Boas Práticas

- APIs pequenas
- Contratos estáveis
- Campos consistentes
- Erros padronizados
- Documentação atualizada

---

# 19. Anti-patterns

Evitar:

- Respostas inconsistentes
- Mudanças breaking sem versão
- Erros genéricos
- Dados sensíveis nas respostas
- Verbos na URL

---

# 20. Critérios de Aceite

- Endpoints padronizados
- Respostas consistentes
- Versionamento definido
- Segurança documentada
- OpenAPI prevista

---

# 21. Checklist

- Versionamento definido
- Convenções documentadas
- Métodos HTTP padronizados
- Respostas definidas
- Paginação prevista
- Filtros documentados
- Segurança registrada
- OpenAPI prevista
