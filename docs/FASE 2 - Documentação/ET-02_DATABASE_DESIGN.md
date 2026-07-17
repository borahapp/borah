# ET-02 — Banco de Dados

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-02_DATABASE_DESIGN.md

---

# 1. Objetivo

Definir a arquitetura do banco de dados do BORAH, estabelecendo padrões de modelagem, nomenclatura, integridade, desempenho e evolução do esquema.

---

# 2. Tecnologias

- PostgreSQL
- Prisma ORM
- UUID v7 (ou v4 enquanto necessário)
- UTC para todas as datas

---

# 3. Princípios

- Normalização até 3FN quando apropriado.
- Integridade referencial obrigatória.
- Soft Delete quando necessário.
- Auditoria em entidades críticas.
- Migrações exclusivamente via Prisma.

---

# 4. Convenções

## Tabelas

- snake_case
- Nome no plural

Exemplos:

- users
- groups
- events
- restaurants
- reviews

## Colunas obrigatórias

Todas as entidades deverão possuir:

```text
id
created_at
updated_at
```

Quando aplicável:

```text
deleted_at
created_by
updated_by
```

---

# 5. Entidades Principais

## users

Representa um usuário da plataforma.

Campos principais:

- id
- name
- email
- avatar_url
- xp
- level
- created_at
- updated_at

---

## groups

Representa grupos de amigos.

Campos:

- id
- name
- owner_id
- invite_code
- created_at
- updated_at

---

## group_members

Relaciona usuários e grupos.

Campos:

- group_id
- user_id
- role
- joined_at

---

## restaurants

Cache local de restaurantes oriundos do Google Places.

Campos:

- id
- google_place_id
- name
- address
- latitude
- longitude

---

## events

Encontros organizados pelos grupos.

Campos:

- id
- group_id
- restaurant_id
- organizer_id
- scheduled_at
- status

---

## attendances

Confirmação de presença.

Campos:

- id
- event_id
- user_id
- status
- checked_in_at

---

## reviews

Avaliações realizadas após o evento.

Campos:

- id
- event_id
- user_id
- food_score
- service_score
- ambience_score
- music_score
- cost_benefit_score
- cleanliness_score
- waiting_time_score
- would_return
- comment

---

## rankings

Pontuação acumulada.

Campos:

- id
- group_id
- user_id
- points
- position
- season

---

## badges

Conquistas disponíveis.

---

## user_badges

Relacionamento entre usuários e badges.

---

## notifications

Notificações enviadas aos usuários.

---

# 6. Relacionamentos

```text
User
 ├── GroupMember
 ├── Review
 ├── Attendance
 └── Ranking

Group
 ├── Members
 └── Events

Event
 ├── Restaurant
 ├── Attendances
 └── Reviews
```

---

# 7. Índices

Criar índices para:

- email
- google_place_id
- invite_code
- group_id
- user_id
- event_id

---

# 8. Integridade

- Foreign Keys obrigatórias.
- ON DELETE RESTRICT como padrão.
- ON DELETE CASCADE apenas em tabelas de relacionamento.

---

# 9. Performance

- Paginação obrigatória.
- Evitar N+1 Queries.
- Índices revisados a cada versão.
- Cache para consultas frequentes de restaurantes.

---

# 10. Segurança

- Nunca armazenar senhas em texto.
- Hash com BCrypt.
- Dados sensíveis protegidos.
- Auditoria para operações críticas.

---

# 11. Evolução

Toda alteração deverá ocorrer por migração versionada do Prisma.

Mudanças destrutivas exigem aprovação e plano de rollback.

---

# 12. Checklist

- Modelo atualizado
- Migração criada
- Índices revisados
- Chaves estrangeiras validadas
- Documentação sincronizada
- Testes de migração executados
