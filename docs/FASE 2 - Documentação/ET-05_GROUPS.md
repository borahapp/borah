# ET-05 — Grupos

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-05_GROUPS.md

---

# 1. Objetivo

Definir a arquitetura funcional e técnica do módulo de Grupos, núcleo da experiência social do BORAH.

---

# 2. Escopo

O módulo permitirá:

- Criar grupos
- Convidar participantes
- Gerenciar membros
- Definir papéis
- Configurar preferências do grupo
- Controlar o rodízio de escolha de restaurantes
- Gerenciar temporadas e estatísticas

---

# 3. Funcionalidades

## Criação de Grupo

Campos:

- Nome
- Foto (opcional)
- Descrição (opcional)
- Privacidade (Privado/Público*)

\*Na versão MVP apenas grupos privados.

Regras:

- O criador torna-se Owner.
- Cada grupo possui um UUID.
- Código de convite único.

---

## Convites

Métodos:

- Link
- Código
- Convite direto entre usuários

Regras:

- Convites podem expirar.
- Owner e Administradores podem convidar.
- Convites podem ser revogados.

---

## Papéis

### Owner

- Excluir grupo
- Transferir propriedade
- Promover/Rebaixar administradores
- Gerenciar configurações

### Administrador

- Convidar membros
- Remover membros
- Criar eventos
- Alterar configurações permitidas

### Membro

- Participar de eventos
- Avaliar restaurantes
- Confirmar presença
- Visualizar estatísticas

---

# 4. Rodízio de Escolha

Cada grupo manterá um ciclo de escolha.

Regras:

RN-001 — O sistema registra quem escolheu por último.

RN-002 — O próximo participante é sugerido automaticamente.

RN-003 — O grupo pode alterar manualmente a ordem.

RN-004 — O histórico permanece disponível.

---

# 5. Temporadas

Cada grupo poderá iniciar temporadas.

Cada temporada armazenará:

- Data inicial
- Data final
- Ranking
- Estatísticas
- Campeão

---

# 6. Modelo de Dados

## groups

- id
- name
- description
- photo_url
- owner_id
- invite_code
- created_at
- updated_at

## group_members

- id
- group_id
- user_id
- role
- joined_at

## group_seasons

- id
- group_id
- name
- starts_at
- ends_at
- status

---

# 7. APIs

- POST /api/v1/groups
- GET /api/v1/groups
- GET /api/v1/groups/{id}
- PATCH /api/v1/groups/{id}
- DELETE /api/v1/groups/{id}

Membros:

- POST /api/v1/groups/{id}/invite
- POST /api/v1/groups/join
- DELETE /api/v1/groups/{id}/members/{userId}

Temporadas:

- POST /api/v1/groups/{id}/seasons
- GET /api/v1/groups/{id}/seasons

---

# 8. Segurança

- Apenas membros acessam dados do grupo.
- Apenas Owner exclui grupos.
- Permissões baseadas em RBAC.
- Convites protegidos por token/código.

---

# 9. Testes

- Criar grupo
- Entrar por convite
- Remover membro
- Alterar Owner
- Criar temporada
- Validar rodízio
- Verificar permissões

---

# 10. Critérios de Aceite

- Grupo criado com sucesso
- Convites funcionais
- Papéis respeitados
- Rodízio persistido
- APIs documentadas
- Testes aprovados

---

# 11. Checklist

- Estrutura definida
- Modelo de dados revisado
- APIs documentadas
- Regras de negócio registradas
- Segurança validada
- Casos de teste definidos
