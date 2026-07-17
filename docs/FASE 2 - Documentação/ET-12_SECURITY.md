# ET-12 — Segurança

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-12_SECURITY.md

---

# 1. Objetivo

Definir a arquitetura de segurança do BORAH, estabelecendo políticas, controles e requisitos para proteger usuários, dados, infraestrutura e integrações.

---

# 2. Escopo

Abrange:

- Aplicativo Flutter
- API NestJS
- Banco PostgreSQL
- Firebase
- Google Places
- Infraestrutura
- Dados dos usuários

---

# 3. Princípios

- Security by Design
- Privacy by Design
- Least Privilege
- Defense in Depth
- Zero Trust
- Secure Defaults

---

# 4. Autenticação

- JWT para autenticação
- Refresh Token rotativo
- BCrypt para senhas
- Login Google
- Login Apple
- Expiração automática de sessões

---

# 5. Autorização

Modelo RBAC.

Perfis iniciais:

- Usuário
- Administrador

Todas as rotas protegidas validarão autenticação e autorização.

---

# 6. Proteção de Dados

- HTTPS obrigatório
- Criptografia em trânsito (TLS)
- Dados sensíveis protegidos
- Segredos fora do código-fonte
- Backups criptografados

---

# 7. Segurança da API

- Validação de entrada
- Sanitização
- Rate Limiting
- CORS configurado
- Proteção contra SQL Injection
- Proteção contra XSS
- Proteção contra CSRF (quando aplicável)

---

# 8. Segurança do Banco

- Menor privilégio para usuários do banco
- Migrações controladas
- Auditoria de alterações críticas
- Índices revisados periodicamente

---

# 9. LGPD

- Consentimento quando necessário
- Direito de exclusão da conta
- Minimização de dados
- Registro das operações relevantes
- Política de retenção de dados

---

# 10. Logs e Auditoria

Registrar:

- Login
- Logout
- Alteração de perfil
- Exclusão de conta
- Mudanças administrativas
- Erros críticos

Nunca registrar:

- Senhas
- Tokens
- Dados sensíveis em texto

---

# 11. Gestão de Segredos

Utilizar variáveis de ambiente para:

- JWT_SECRET
- DATABASE_URL
- GOOGLE_API_KEY
- FIREBASE_CREDENTIALS

Nunca armazenar segredos no repositório.

---

# 12. Monitoramento

- Health Checks
- Logs estruturados
- Alertas
- Crash Reporting
- Métricas de segurança

---

# 13. Plano de Resposta a Incidentes

Etapas:

1. Detectar
2. Conter
3. Investigar
4. Corrigir
5. Restaurar
6. Documentar

---

# 14. Testes de Segurança

- Testes de autenticação
- Testes de autorização
- Testes de força bruta
- Testes de Rate Limiting
- Testes de validação
- Análise de dependências
- Verificação de vulnerabilidades

---

# 15. Critérios de Aceite

- HTTPS habilitado
- JWT validado
- LGPD atendida
- Logs implementados
- Segredos protegidos
- Testes de segurança aprovados

---

# 16. Checklist

- Autenticação revisada
- Autorização validada
- Proteção de dados implementada
- Auditoria definida
- Gestão de segredos documentada
- Plano de incidentes registrado
