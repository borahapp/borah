
# AR-13 — Row Level Security (RLS)

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-13_ROW_LEVEL_SECURITY.md

---

# 1. Objetivo

Definir a estratégia oficial de Row Level Security (RLS) do BORAH, garantindo que cada usuário acesse apenas os dados permitidos, com a segurança aplicada diretamente no PostgreSQL/Supabase.

---

# 2. Objetivos

- Segurança por padrão
- Menor privilégio
- Isolamento de dados
- Controle por usuário e grupo
- Redução de riscos de acesso indevido

---

# 3. Princípios

- RLS habilitada em todas as tabelas da aplicação
- Permissões explícitas
- Nunca confiar apenas no cliente
- Políticas simples e auditáveis

---

# 4. Arquitetura

```text
Flutter
   │
   ▼
Supabase Auth
   │
   ▼
JWT
   │
   ▼
PostgreSQL
   │
   ▼
RLS Policies
   │
   ▼
Dados Permitidos
```

---

# 5. Escopo

Aplicar RLS em:

- users
- groups
- group_members
- events
- restaurants
- reviews
- rankings
- notifications

---

# 6. Tipos de Políticas

- SELECT
- INSERT
- UPDATE
- DELETE

Cada operação deverá possuir política própria.

---

# 7. Regras Gerais

## Leitura (SELECT)

Permitir apenas:

- Dados públicos
- Dados do próprio usuário
- Dados de grupos dos quais participa

---

## Inserção (INSERT)

Permitir somente usuários autenticados e respeitando regras de negócio.

---

## Atualização (UPDATE)

Somente o proprietário do recurso ou administradores autorizados.

---

## Exclusão (DELETE)

Restringir ao proprietário quando aplicável ou administradores.

---

# 8. Controle por Grupo

Usuários poderão acessar apenas informações relacionadas aos grupos dos quais são membros.

Papéis previstos:

- Owner
- Admin
- Member

---

# 9. Dados Públicos

Podem possuir leitura pública:

- Restaurantes
- Badges
- Configurações públicas

Escrita sempre autenticada.

---

# 10. Dados Privados

Protegidos por RLS:

- Perfil
- Eventos privados
- Convites
- Feed privado
- Notificações

---

# 11. Edge Functions

Operações administrativas deverão ocorrer por Edge Functions utilizando a Service Role Key em ambiente seguro.

Nunca expor essa chave ao aplicativo.

---

# 12. Testes

Validar:

- Usuário autenticado
- Usuário não autenticado
- Membro do grupo
- Não membro
- Administrador
- Tentativas de acesso indevido

---

# 13. Auditoria

Registrar:

- Alterações de políticas
- Falhas de autorização
- Operações administrativas

---

# 14. Boas Práticas

- Habilitar RLS antes da publicação.
- Criar políticas específicas por operação.
- Evitar políticas excessivamente complexas.
- Revisar políticas periodicamente.

---

# 15. Anti-patterns

Evitar:

- Tabelas sem RLS
- Políticas permissivas ("TRUE")
- Lógica de autorização apenas no Flutter
- Uso desnecessário da Service Role Key

---

# 16. Critérios de Aceite

- Todas as tabelas protegidas
- Políticas documentadas
- Testes previstos
- Auditoria definida
- Acesso mínimo garantido

---

# 17. Checklist

- RLS habilitada
- SELECT documentado
- INSERT documentado
- UPDATE documentado
- DELETE documentado
- Papéis definidos
- Testes planejados
- Auditoria prevista
