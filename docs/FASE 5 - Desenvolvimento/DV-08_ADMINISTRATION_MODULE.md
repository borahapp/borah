# DV-08 --- Administration Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-08_ADMINISTRATION_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação do módulo administrativo do BORAH, responsável
pela administração da plataforma, moderação de conteúdo, gestão de
usuários, restaurantes e acompanhamento dos indicadores operacionais.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Painel Administrativo
-   Gestão de Usuários
-   Gestão de Restaurantes
-   Moderação de Avaliações
-   Moderação de Comentários
-   Relatórios
-   Auditoria
-   Controle de Acesso (RBAC)

------------------------------------------------------------------------

# 3. Perfis Administrativos

  Perfil          Permissões
  --------------- ------------------------
  Super Admin     Acesso total
  Administrador   Gestão operacional
  Moderador       Moderação de conteúdo
  Suporte         Consulta e atendimento

------------------------------------------------------------------------

# 4. Regras de Negócio

-   Apenas usuários autorizados acessam o painel.
-   Todas as ações administrativas devem ser auditadas.
-   Exclusões críticas devem exigir confirmação.
-   Conteúdos moderados devem preservar histórico.
-   Permissões seguem o princípio do menor privilégio.

------------------------------------------------------------------------

# 5. Fluxo Funcional

``` text
Login Administrativo
        ↓
Validação de Permissões
        ↓
Dashboard
        ↓
Selecionar Módulo
        ↓
Executar Ação
        ↓
Registrar Auditoria
```

------------------------------------------------------------------------

# 6. Funcionalidades

## Dashboard

-   KPIs
-   Usuários ativos
-   Restaurantes cadastrados
-   Avaliações
-   Denúncias pendentes

## Gestão de Usuários

-   Consultar
-   Bloquear
-   Reativar
-   Alterar permissões
-   Visualizar histórico

## Gestão de Restaurantes

-   Aprovar cadastro
-   Editar informações
-   Arquivar registros
-   Gerenciar categorias

## Moderação

-   Avaliações
-   Comentários
-   Fotos
-   Denúncias

## Relatórios

-   Crescimento da base
-   Atividade dos usuários
-   Restaurantes mais avaliados
-   Conteúdo moderado

------------------------------------------------------------------------

# 7. Telas

-   Login Admin
-   Dashboard
-   Usuários
-   Restaurantes
-   Moderação
-   Relatórios
-   Auditoria

------------------------------------------------------------------------

# 8. Arquitetura

``` text
Admin UI
    ↓
Controllers
    ↓
Use Cases
    ↓
Repositories
    ↓
Supabase
    ↓
Database + Storage + Edge Functions
```

------------------------------------------------------------------------

# 9. Estrutura do Módulo

``` text
administration/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── administration.dart
```

------------------------------------------------------------------------

# 10. Modelo de Dados

## admin_roles

  Campo        Tipo
  ------------ -----------
  id           UUID
  user_id      UUID
  role         String
  created_at   Timestamp

## audit_logs

  Campo        Tipo
  ------------ -----------
  id           UUID
  actor_id     UUID
  action       String
  entity       String
  entity_id    UUID
  metadata     JSON
  created_at   Timestamp

------------------------------------------------------------------------

# 11. Estados

-   Initial
-   Loading
-   Loaded
-   Processing
-   Success
-   Error

------------------------------------------------------------------------

# 12. Segurança

-   RBAC obrigatório
-   RLS aplicada às tabelas
-   MFA recomendado para administradores
-   Sessões com tempo limite
-   Registro completo de auditoria

------------------------------------------------------------------------

# 13. Tratamento de Erros

-   Permissão insuficiente
-   Registro inexistente
-   Conflito de atualização
-   Falha na operação
-   Sessão expirada

------------------------------------------------------------------------

# 14. Integrações

-   Authentication
-   Users
-   Restaurants
-   Reviews
-   Social
-   Notifications
-   Audit Logs

------------------------------------------------------------------------

# 15. Performance

-   Paginação
-   Filtros avançados
-   Exportação assíncrona
-   Cache para consultas frequentes

------------------------------------------------------------------------

# 16. Testes

-   Controle de acesso
-   Gestão de usuários
-   Moderação
-   Relatórios
-   Auditoria
-   Performance
-   Segurança

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   RBAC validado
-   Dashboard funcional
-   Moderação operacional
-   Auditoria registrada
-   Relatórios disponíveis

------------------------------------------------------------------------

# 18. Checklist

-   Dashboard implementado
-   Gestão de usuários
-   Gestão de restaurantes
-   Moderação
-   Relatórios
-   Auditoria
-   Testes concluídos

------------------------------------------------------------------------

# 19. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Dashboard em tempo real
-   Aprovação em lote
-   Workflows de moderação
-   Exportação avançada
-   Alertas operacionais
-   Gestão de permissões granular
-   Indicadores DORA
-   IA para apoio à moderação
