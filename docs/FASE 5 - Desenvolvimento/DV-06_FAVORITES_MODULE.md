# DV-06 --- Favorites Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-06_FAVORITES_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação do módulo de favoritos do BORAH, permitindo que
usuários salvem restaurantes de interesse e acessem rapidamente sua
lista personalizada.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Adicionar aos favoritos
-   Remover dos favoritos
-   Listagem
-   Busca
-   Ordenação
-   Filtros
-   Sincronização entre dispositivos

------------------------------------------------------------------------

# 3. Regras de Negócio

-   Apenas usuários autenticados podem utilizar favoritos.
-   Um restaurante pode ser favoritado apenas uma vez por usuário.
-   A remoção deve ser refletida imediatamente em todos os dispositivos.
-   Favoritos pertencem exclusivamente ao usuário.

------------------------------------------------------------------------

# 4. Fluxo Funcional

``` text
Visualizar Restaurante
        ↓
Favoritar
        ↓
Persistir no Banco
        ↓
Atualizar Interface
        ↓
Sincronizar Dispositivos
```

------------------------------------------------------------------------

# 5. Funcionalidades

## Favoritar

-   Adicionar restaurante
-   Feedback visual imediato
-   Atualização otimista da interface

## Remover

-   Desfavoritar rapidamente
-   Atualizar lista automaticamente

## Listagem

-   Todos os favoritos
-   Busca por nome
-   Ordenação por nome, avaliação ou data
-   Filtros por cidade e categoria

------------------------------------------------------------------------

# 6. Telas

-   Lista de Favoritos
-   Detalhes do Restaurante
-   Estado vazio

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
```

------------------------------------------------------------------------

# 8. Estrutura do Módulo

``` text
favorites/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── favorites.dart
```

------------------------------------------------------------------------

# 9. Modelo de Dados

  Campo           Tipo
  --------------- -----------
  id              UUID
  user_id         UUID
  restaurant_id   UUID
  created_at      Timestamp

------------------------------------------------------------------------

# 10. Estados

-   Initial
-   Loading
-   Loaded
-   Empty
-   Syncing
-   Error

------------------------------------------------------------------------

# 11. Sincronização

-   Persistência em tempo real
-   Recuperação automática após login
-   Consistência entre dispositivos
-   Suporte futuro ao Supabase Realtime

------------------------------------------------------------------------

# 12. Tratamento de Erros

-   Restaurante inexistente
-   Favorito duplicado
-   Falha de sincronização
-   Sem conexão
-   Permissão negada

------------------------------------------------------------------------

# 13. Segurança

-   RLS na tabela de favoritos
-   Usuário acessa apenas seus próprios registros
-   Consultas autenticadas via JWT

------------------------------------------------------------------------

# 14. Integrações

-   Restaurants
-   Users
-   Rankings
-   Feed
-   Recomendações futuras

------------------------------------------------------------------------

# 15. Performance

-   Paginação
-   Cache local
-   Lazy Loading
-   Índices por user_id e restaurant_id

------------------------------------------------------------------------

# 16. Testes

-   Adicionar favorito
-   Remover favorito
-   Listagem
-   Busca
-   Filtros
-   Sincronização
-   Permissões
-   Performance

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Favoritar funcionando
-   Remoção funcionando
-   Lista sincronizada
-   Busca e filtros operacionais
-   Segurança validada

------------------------------------------------------------------------

# 18. Checklist

-   Adicionar implementado
-   Remover implementado
-   Listagem implementada
-   Busca implementada
-   Sincronização implementada
-   Testes concluídos

------------------------------------------------------------------------

# 19. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Coleções de favoritos
-   Pastas personalizadas
-   Favoritos compartilhados
-   Sugestões inteligentes
-   Alertas de novos restaurantes favoritos
-   Importação e exportação
-   Sincronização em tempo real
-   Recomendações baseadas nos favoritos
