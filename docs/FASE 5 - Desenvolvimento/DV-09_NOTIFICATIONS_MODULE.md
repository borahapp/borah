# DV-09 --- Notifications Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-09_NOTIFICATIONS_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação do módulo de notificações do BORAH, responsável
por informar os usuários sobre eventos relevantes da plataforma por meio
de notificações push e in-app.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Notificações Push
-   Notificações In-App
-   Preferências de Notificação
-   Histórico
-   Leitura e marcação
-   Integração com Edge Functions
-   Agendamento futuro

------------------------------------------------------------------------

# 3. Regras de Negócio

-   Apenas usuários autenticados recebem notificações.
-   Cada usuário controla suas preferências.
-   Notificações críticas não podem ser desativadas.
-   Toda notificação deve possuir tipo, data e status de leitura.
-   Notificações expiradas podem ser arquivadas.

------------------------------------------------------------------------

# 4. Fluxo Funcional

``` text
Evento
   ↓
Edge Function
   ↓
Gerar Notificação
   ↓
Persistir no Banco
   ↓
Enviar Push
   ↓
Atualizar Central de Notificações
```

------------------------------------------------------------------------

# 5. Tipos de Notificação

## Social

-   Novo seguidor
-   Curtida
-   Comentário
-   Compartilhamento

## Restaurantes

-   Novo restaurante favorito
-   Atualizações relevantes

## Avaliações

-   Respostas
-   Aprovação/Reprovação

## Sistema

-   Recuperação de senha
-   Atualizações
-   Avisos importantes

## Gamificação

-   Conquistas
-   Badges
-   Mudança de nível

------------------------------------------------------------------------

# 6. Telas

-   Central de Notificações
-   Preferências
-   Detalhes da Notificação

------------------------------------------------------------------------

# 7. Arquitetura

``` text
Evento
   ↓
Edge Function
   ↓
Notification Service
   ↓
Database
   ↓
Push Provider
   ↓
Flutter App
```

------------------------------------------------------------------------

# 8. Estrutura do Módulo

``` text
notifications/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── notifications.dart
```

------------------------------------------------------------------------

# 9. Modelo de Dados

  Campo        Tipo
  ------------ -----------
  id           UUID
  user_id      UUID
  type         String
  title        String
  message      Text
  payload      JSON
  is_read      Boolean
  created_at   Timestamp
  read_at      Timestamp

------------------------------------------------------------------------

# 10. Estados

-   Initial
-   Loading
-   Loaded
-   Sending
-   Empty
-   Error

------------------------------------------------------------------------

# 11. Preferências

Configurações por categoria:

-   Social
-   Restaurantes
-   Avaliações
-   Sistema
-   Gamificação

Separar Push e In-App quando aplicável.

------------------------------------------------------------------------

# 12. Tratamento de Erros

-   Falha no envio
-   Token inválido
-   Usuário inexistente
-   Preferência desabilitada
-   Sem conexão

------------------------------------------------------------------------

# 13. Segurança

-   RLS para notificações
-   Usuário acessa apenas suas notificações
-   Payload sem dados sensíveis
-   Auditoria de envios administrativos

------------------------------------------------------------------------

# 14. Integrações

-   Authentication
-   Users
-   Reviews
-   Restaurants
-   Social
-   Favorites
-   Rankings
-   Administration
-   Edge Functions

------------------------------------------------------------------------

# 15. Performance

-   Paginação
-   Cache local
-   Marcação em lote como lidas
-   Entrega assíncrona
-   Retry para falhas temporárias

------------------------------------------------------------------------

# 16. Testes

-   Envio de Push
-   Notificações In-App
-   Preferências
-   Marcar como lida
-   Histórico
-   Permissões
-   Performance

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Push funcionando
-   Central de notificações operacional
-   Preferências persistidas
-   Histórico disponível
-   Segurança validada

------------------------------------------------------------------------

# 18. Checklist

-   Push implementado
-   In-App implementado
-   Preferências implementadas
-   Histórico implementado
-   Integração com Edge Functions
-   Testes concluídos

------------------------------------------------------------------------

# 19. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Supabase Realtime
-   Notificações agendadas
-   Resumos diários e semanais
-   Agrupamento inteligente
-   Ações rápidas na notificação
-   Campanhas segmentadas
-   A/B testing de notificações
-   Analytics de entrega, abertura e conversão
