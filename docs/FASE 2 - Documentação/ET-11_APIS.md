# ET-11 — APIs

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-11_APIS.md

---

# 1. Objetivo

Definir os padrões técnicos para todas as APIs do BORAH, garantindo consistência, segurança, versionamento e facilidade de integração.

---

# 2. Arquitetura

- Estilo REST
- JSON UTF-8
- HTTPS obrigatório
- Versionamento por URL
- OpenAPI 3.1 (Swagger)

Base:

`/api/v1`

---

# 3. Convenções

## Métodos

- GET: consulta
- POST: criação
- PATCH: atualização parcial
- PUT: atualização completa (quando necessário)
- DELETE: remoção

## URLs

- Substantivos no plural
- snake_case apenas quando inevitável
- IDs em UUID

Exemplos:

- GET /api/v1/groups
- POST /api/v1/events
- GET /api/v1/restaurants/{id}

---

# 4. Autenticação

- JWT Bearer Token
- Refresh Token
- Endpoints públicos apenas quando definidos em ET-03

Header:

Authorization: Bearer <token>

---

# 5. Padrão de Resposta

Sucesso:

```json
{
  "data": {},
  "meta": {},
  "links": {}
}
```

Erro:

```json
{
  "code": "RESOURCE_NOT_FOUND",
  "message": "Recurso não encontrado.",
  "details": null,
  "traceId": "uuid"
}
```

---

# 6. Paginação

Parâmetros:

- page
- limit
- sort
- order

Resposta:

- total
- page
- totalPages
- hasNext
- hasPrevious

---

# 7. Filtros

Suporte para:

- busca textual
- intervalos de datas
- ordenação
- filtros por status
- filtros por grupo

---

# 8. Códigos HTTP

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

# 9. Rate Limiting

Aplicado por usuário/IP.

Headers:

- X-RateLimit-Limit
- X-RateLimit-Remaining
- Retry-After

---

# 10. Segurança

- HTTPS obrigatório
- Validação de entrada
- Sanitização
- CORS configurado
- Proteção contra SQL Injection
- Proteção contra XSS
- Auditoria de operações críticas

---

# 11. Documentação

Toda API deverá conter:

- descrição
- parâmetros
- exemplos
- respostas
- códigos de erro
- autenticação
- exemplos de request/response

---

# 12. Versionamento

- v1 compatível com versões anteriores
- mudanças incompatíveis exigem nova versão

---

# 13. Testes

Cobrir:

- sucesso
- autenticação
- autorização
- validações
- erros
- paginação
- filtros
- performance

---

# 14. Critérios de Aceite

- Swagger atualizado
- APIs padronizadas
- Testes aprovados
- Segurança validada
- Versionamento respeitado

---

# 15. Checklist

- OpenAPI atualizada
- Endpoints documentados
- Respostas padronizadas
- Rate Limiting configurado
- Casos de teste definidos
