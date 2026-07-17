# DV-04 --- Reviews Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-04_REVIEWS_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação do módulo de avaliações do BORAH, permitindo que
usuários compartilhem experiências, atribuam notas aos restaurantes e
interajam com avaliações da comunidade.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Criar avaliação
-   Editar avaliação
-   Excluir avaliação
-   Curtidas
-   Comentários
-   Upload de fotos
-   Sistema de notas
-   Moderação
-   Integração com rankings

------------------------------------------------------------------------

# 3. Regras de Negócio

-   Apenas usuários autenticados podem avaliar.
-   Um usuário pode possuir apenas uma avaliação por restaurante.
-   Apenas o autor pode editar ou excluir sua avaliação.
-   Curtidas não podem ser duplicadas pelo mesmo usuário.
-   Conteúdos denunciados poderão ser moderados.

------------------------------------------------------------------------

# 4. Fluxo Funcional

``` text
Selecionar Restaurante
        ↓
Criar Avaliação
        ↓
Adicionar Nota
        ↓
Escrever Comentário
        ↓
Adicionar Fotos (Opcional)
        ↓
Publicar
        ↓
Atualizar Ranking
```

------------------------------------------------------------------------

# 5. Funcionalidades

## Avaliações

-   Nota (1 a 5 estrelas)
-   Comentário
-   Fotos
-   Data
-   Autor

## Edição

-   Alterar nota
-   Alterar comentário
-   Adicionar/remover fotos

## Exclusão

-   Exclusão lógica
-   Atualização automática da média

## Interações

-   Curtidas
-   Comentários
-   Denúncias

------------------------------------------------------------------------

# 6. Telas

-   Lista de avaliações
-   Criar avaliação
-   Editar avaliação
-   Detalhes da avaliação
-   Comentários

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
Supabase Storage
```

------------------------------------------------------------------------

# 8. Estrutura do Módulo

``` text
reviews/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── reviews.dart
```

------------------------------------------------------------------------

# 9. Modelo de Dados

  Campo           Tipo
  --------------- -----------
  id              UUID
  restaurant_id   UUID
  user_id         UUID
  rating          Decimal
  comment         Text
  likes_count     Integer
  photos_count    Integer
  created_at      Timestamp
  updated_at      Timestamp

------------------------------------------------------------------------

# 10. Estados

-   Initial
-   Loading
-   Publishing
-   Loaded
-   Success
-   Error

------------------------------------------------------------------------

# 11. Fotos

Fluxo:

``` text
Selecionar
   ↓
Validar
   ↓
Comprimir
   ↓
Upload
   ↓
Associar à Avaliação
```

Regras:

-   Máximo 5 fotos
-   JPG, PNG ou WEBP
-   Até 10 MB por imagem

------------------------------------------------------------------------

# 12. Tratamento de Erros

-   Nota inválida
-   Comentário vazio (quando obrigatório)
-   Upload falhou
-   Sem conexão
-   Permissão negada
-   Avaliação duplicada

------------------------------------------------------------------------

# 13. Segurança

-   RLS para avaliações
-   Apenas o autor pode editar/excluir
-   Fotos protegidas por políticas do Storage
-   Auditoria de alterações

------------------------------------------------------------------------

# 14. Integrações

-   Restaurantes (atualização da média)
-   Rankings
-   Feed
-   Notificações

------------------------------------------------------------------------

# 15. Testes

-   Criar avaliação
-   Editar
-   Excluir
-   Curtir
-   Comentar
-   Upload de fotos
-   Atualização do ranking
-   Permissões

------------------------------------------------------------------------

# 16. Critérios de Aceite

-   Avaliações publicadas corretamente
-   Média atualizada
-   Curtidas funcionando
-   Comentários persistidos
-   Fotos armazenadas
-   Regras de segurança respeitadas

------------------------------------------------------------------------

# 17. Checklist

-   Criar avaliação
-   Editar avaliação
-   Excluir avaliação
-   Curtidas
-   Comentários
-   Upload de fotos
-   Integração com rankings
-   Testes concluídos

------------------------------------------------------------------------

# 18. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Avaliações verificadas
-   Respostas dos restaurantes
-   Reações além de curtidas
-   IA para moderação de conteúdo
-   Detecção de spam
-   Avaliações em vídeo
-   Edição com histórico
-   Tradução automática de comentários
