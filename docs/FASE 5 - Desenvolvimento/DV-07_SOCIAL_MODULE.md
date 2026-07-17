# DV-07 --- Social Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-07_SOCIAL_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação do módulo social do BORAH, permitindo que
usuários interajam entre si por meio de seguidores, comentários,
compartilhamentos e um feed de atividades.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Compartilhamento
-   Comentários
-   Seguidores
-   Feed de atividades
-   Curtidas sociais
-   Privacidade das interações
-   Moderação de conteúdo

------------------------------------------------------------------------

# 3. Regras de Negócio

-   Apenas usuários autenticados podem interagir.
-   Usuários podem seguir ou deixar de seguir outros usuários.
-   O autor pode excluir seus próprios comentários.
-   Conteúdos denunciados podem ser ocultados durante moderação.
-   Configurações de privacidade devem ser respeitadas.

------------------------------------------------------------------------

# 4. Fluxo Funcional

``` text
Nova Avaliação
      ↓
Publicar no Feed
      ↓
Seguidores Visualizam
      ↓
Curtem / Comentam / Compartilham
      ↓
Gerar Notificações
```

------------------------------------------------------------------------

# 5. Funcionalidades

## Compartilhamento

-   Compartilhar restaurante
-   Compartilhar avaliação
-   Compartilhar ranking
-   Link profundo (Deep Link)

## Comentários

-   Criar
-   Editar (janela configurável)
-   Excluir
-   Denunciar

## Seguidores

-   Seguir usuário
-   Deixar de seguir
-   Listar seguidores
-   Listar seguindo

## Feed

-   Atividades recentes
-   Novas avaliações
-   Novos favoritos públicos (futuro)
-   Conquistas da gamificação
-   Atualização paginada

------------------------------------------------------------------------

# 6. Telas

-   Feed
-   Perfil público
-   Comentários
-   Seguidores
-   Seguindo

------------------------------------------------------------------------

# 7. Arquitetura

``` text
Presentation
      ↓
Controller
      ↓
Use Case
      ↓
Repository
      ↓
Datasource
      ↓
Supabase Database
        +
Edge Functions
        +
Realtime (futuro)
```

------------------------------------------------------------------------

# 8. Estrutura do Módulo

``` text
social/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── social.dart
```

------------------------------------------------------------------------

# 9. Modelo de Dados

## followers

  Campo          Tipo
  -------------- -----------
  id             UUID
  follower_id    UUID
  following_id   UUID
  created_at     Timestamp

## comments

  Campo        Tipo
  ------------ -----------
  id           UUID
  review_id    UUID
  user_id      UUID
  content      Text
  created_at   Timestamp
  updated_at   Timestamp

------------------------------------------------------------------------

# 10. Estados

-   Initial
-   Loading
-   Loaded
-   Publishing
-   Refreshing
-   Empty
-   Error

------------------------------------------------------------------------

# 11. Feed

Deve suportar:

-   Paginação
-   Infinite Scroll
-   Atualização manual
-   Cache local
-   Ordenação por data

------------------------------------------------------------------------

# 12. Notificações

Gerar eventos para:

-   Novo seguidor
-   Novo comentário
-   Curtida
-   Compartilhamento
-   Menções (futuro)

------------------------------------------------------------------------

# 13. Tratamento de Erros

-   Comentário inválido
-   Falha ao seguir usuário
-   Conteúdo indisponível
-   Sem conexão
-   Permissão negada

------------------------------------------------------------------------

# 14. Segurança

-   RLS em todas as tabelas
-   Respeito às configurações de privacidade
-   Sanitização de conteúdo
-   Auditoria de denúncias

------------------------------------------------------------------------

# 15. Integrações

-   Users
-   Reviews
-   Restaurants
-   Favorites
-   Rankings
-   Notifications
-   Gamification

------------------------------------------------------------------------

# 16. Testes

-   Seguir usuário
-   Deixar de seguir
-   Criar comentário
-   Excluir comentário
-   Compartilhar conteúdo
-   Carregar feed
-   Permissões
-   Performance

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Feed funcionando
-   Comentários persistidos
-   Seguidores atualizados
-   Compartilhamentos operacionais
-   Notificações geradas
-   Segurança validada

------------------------------------------------------------------------

# 18. Checklist

-   Feed implementado
-   Comentários implementados
-   Seguidores implementados
-   Compartilhamento implementado
-   Integração com notificações
-   Testes concluídos

------------------------------------------------------------------------

# 19. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Mensagens privadas
-   Menções com @usuário
-   Hashtags
-   Reações além de curtidas
-   Stories de restaurantes
-   Feed em tempo real com Supabase Realtime
-   Grupos de amigos
-   Compartilhamento para redes sociais
-   Sistema de reputação social
