# ET-04 — Usuários

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-04_USERS.md

---

# 1. Objetivo

Definir os requisitos técnicos, regras de negócio e estrutura do módulo de Usuários do BORAH.

---

# 2. Escopo

O módulo de usuários é responsável por:

- Cadastro e perfil
- Avatar
- Preferências
- Estatísticas
- Nível e XP
- Privacidade
- Configurações da conta

---

# 3. Funcionalidades

## Perfil

Cada usuário possuirá:

- Nome
- Nome de usuário (@username)
- Foto de perfil
- Biografia (opcional)
- Cidade (opcional)
- Data de cadastro

### Regras

- Username único.
- Nome pode ser alterado.
- Avatar pode ser atualizado.

---

## Estatísticas

O sistema exibirá:

- Restaurantes visitados
- Eventos participados
- Eventos organizados
- Avaliações realizadas
- Média das avaliações
- XP total
- Nível atual
- Badges conquistadas

---

## XP e Níveis

O usuário acumula XP por ações como:

- Participar de eventos
- Organizar eventos
- Fazer check-in
- Avaliar restaurantes
- Conquistar desafios

O cálculo do XP será definido em documento específico de gamificação.

---

## Privacidade

Opções:

- Perfil público
- Perfil privado
- Permitir convites
- Exibir estatísticas
- Exibir localização aproximada

---

## Configurações

- Alterar senha
- Alterar e-mail
- Alterar foto
- Preferências de notificações
- Idioma
- Exclusão da conta

---

# 4. Regras de Negócio

RN-001 — Cada e-mail pertence a apenas um usuário.

RN-002 — Username deve ser único.

RN-003 — Exclusão da conta seguirá política de retenção definida pela LGPD.

RN-004 — XP nunca poderá assumir valor negativo.

RN-005 — Apenas o próprio usuário poderá editar seu perfil, exceto administradores.

---

# 5. Modelo de Dados

Tabela principal:

users

Campos principais:

- id
- name
- username
- email
- avatar_url
- bio
- city
- xp
- level
- privacy
- created_at
- updated_at

---

# 6. APIs

- GET /api/v1/users/me
- GET /api/v1/users/{id}
- PATCH /api/v1/users/me
- DELETE /api/v1/users/me
- POST /api/v1/users/avatar

---

# 7. Segurança

- Autenticação obrigatória
- Autorização por JWT
- Validação de arquivos de avatar
- Limite de tamanho para upload
- Proteção de dados pessoais conforme LGPD

---

# 8. Testes

Cobrir:

- Atualização de perfil
- Alteração de avatar
- Username duplicado
- Exclusão de conta
- Cálculo de nível
- Permissões de edição

---

# 9. Critérios de Aceite

- Perfil editável pelo usuário
- Estatísticas exibidas corretamente
- Regras de privacidade respeitadas
- APIs documentadas
- Testes aprovados

---

# 10. Checklist

- Estrutura do perfil definida
- APIs especificadas
- Regras de negócio documentadas
- Segurança validada
- Testes previstos
