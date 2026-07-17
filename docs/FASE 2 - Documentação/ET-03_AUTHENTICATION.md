# ET-03 — Autenticação

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-03_AUTHENTICATION.md

---

# 1. Objetivo

Definir a arquitetura, os fluxos, os requisitos funcionais e não funcionais do módulo de autenticação do BORAH.

---

# 2. Escopo

O módulo de autenticação será responsável por:

- Cadastro de usuários
- Login
- Logout
- Renovação de sessão
- Recuperação de senha
- Login social
- Gerenciamento de sessões
- Controle de acesso

---

# 3. Tecnologias

- NestJS
- PostgreSQL
- Prisma ORM
- JWT
- BCrypt
- Firebase Authentication
- Google Sign-In
- Apple Sign-In (iOS)

---

# 4. Métodos de Autenticação

## Cadastro por e-mail

Campos obrigatórios:

- Nome
- E-mail
- Senha

Regras:

- E-mail único.
- Senha nunca armazenada em texto.
- Hash utilizando BCrypt.

---

## Login por e-mail

Credenciais:

- E-mail
- Senha

Resposta:

- Access Token
- Refresh Token
- Dados básicos do usuário

---

## Login com Google

Fluxo:

1. Usuário autentica pelo Google.
2. Firebase valida a identidade.
3. Backend cria ou localiza o usuário.
4. Tokens JWT são emitidos.

---

## Login com Apple

Disponível para dispositivos iOS seguindo o mesmo fluxo do Google.

---

# 5. Tokens

## Access Token

- JWT
- Curta duração
- Utilizado para acesso às APIs

## Refresh Token

- Longa duração
- Armazenado de forma segura
- Utilizado para renovar sessões

---

# 6. Fluxos

## Cadastro

Usuário → Cadastro → Validação → Criação → Login automático

## Login

Usuário → Validação → JWT → Aplicação

## Logout

Usuário → Revogação do Refresh Token → Encerramento da sessão

## Recuperação de Senha

1. Solicitação por e-mail.
2. Geração de token temporário.
3. Definição de nova senha.

---

# 7. Controle de Sessões

Cada sessão deverá registrar:

- Usuário
- Dispositivo
- Data de criação
- Último acesso
- Status

Permitir encerramento de sessões ativas.

---

# 8. Requisitos de Segurança

- HTTPS obrigatório
- BCrypt para senhas
- JWT assinado
- Refresh Token rotativo
- Rate Limiting
- Proteção contra força bruta
- Validação de entrada
- Logs de autenticação

---

# 9. Permissões

Perfis iniciais:

- Usuário
- Administrador

A autorização deverá utilizar RBAC (Role-Based Access Control).

---

# 10. APIs

Principais endpoints:

- POST /api/v1/auth/register
- POST /api/v1/auth/login
- POST /api/v1/auth/google
- POST /api/v1/auth/apple
- POST /api/v1/auth/refresh
- POST /api/v1/auth/logout
- POST /api/v1/auth/forgot-password
- POST /api/v1/auth/reset-password

---

# 11. Requisitos Não Funcionais

- Tempo médio de autenticação inferior a 2 segundos.
- Disponibilidade mínima de 99,9%.
- Compatibilidade com Android e iOS.

---

# 12. Testes

Cobrir:

- Cadastro
- Login válido
- Login inválido
- Refresh Token
- Logout
- Recuperação de senha
- Login Google
- Login Apple
- Tentativas de ataque

---

# 13. Checklist

- Fluxos documentados
- APIs definidas
- Regras de segurança revisadas
- Testes previstos
- Compatibilidade com LGPD validada
