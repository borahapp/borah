# DV-05 --- Rankings Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-05_RANKINGS_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação do módulo de rankings do BORAH, responsável por
transformar avaliações em classificações dinâmicas e confiáveis para
auxiliar os usuários na descoberta dos melhores restaurantes.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Ranking Geral
-   Ranking por Cidade
-   Ranking por Categoria
-   Ranking Personalizado
-   Ranking entre Amigos
-   Critérios de desempate
-   Atualização automática
-   Cache e otimização

------------------------------------------------------------------------

# 3. Regras de Negócio

-   Rankings são gerados a partir de avaliações válidas.
-   Restaurantes sem avaliações não participam do ranking.
-   Avaliações removidas deixam de influenciar imediatamente.
-   Empates seguem critérios padronizados.
-   Apenas avaliações públicas entram no cálculo.

------------------------------------------------------------------------

# 4. Fluxo Funcional

``` text
Nova Avaliação
      ↓
Validar Dados
      ↓
Recalcular Métricas
      ↓
Atualizar Ranking
      ↓
Atualizar Cache
      ↓
Exibir ao Usuário
```

------------------------------------------------------------------------

# 5. Tipos de Ranking

## Ranking Geral

Classificação global de todos os restaurantes.

## Ranking por Cidade

Exibe restaurantes de uma cidade específica.

## Ranking por Categoria

Filtra por categoria (Hambúrguer, Japonês, Italiano etc.).

## Ranking Personalizado

Combina filtros como cidade, categoria, distância e faixa de preço.

## Ranking entre Amigos

Considera apenas avaliações realizadas por membros do mesmo grupo ou
amigos.

------------------------------------------------------------------------

# 6. Critérios de Classificação

Ordem de prioridade:

1.  Média das avaliações
2.  Quantidade de avaliações
3.  Avaliações recentes
4.  Nome do restaurante (desempate final)

------------------------------------------------------------------------

# 7. Atualização

O ranking deve ser atualizado quando ocorrer:

-   Nova avaliação
-   Edição de avaliação
-   Exclusão de avaliação
-   Moderação de conteúdo

------------------------------------------------------------------------

# 8. Arquitetura

``` text
Reviews
    ↓
Ranking Service
    ↓
Queries Otimizadas
    ↓
Cache
    ↓
Flutter
```

------------------------------------------------------------------------

# 9. Estrutura do Módulo

``` text
rankings/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── rankings.dart
```

------------------------------------------------------------------------

# 10. Modelo de Dados

  Campo              Tipo
  ------------------ -----------
  restaurant_id      UUID
  average_rating     Decimal
  total_reviews      Integer
  ranking_position   Integer
  city               String
  category           String
  updated_at         Timestamp

------------------------------------------------------------------------

# 11. Estados

-   Initial
-   Loading
-   Loaded
-   Refreshing
-   Empty
-   Error

------------------------------------------------------------------------

# 12. Performance

-   Paginação
-   Cache de resultados
-   Índices nas consultas
-   Atualizações incrementais
-   Limite de registros por página

------------------------------------------------------------------------

# 13. Tratamento de Erros

-   Ranking indisponível
-   Sem resultados
-   Filtros inválidos
-   Falha na atualização
-   Sem conexão

------------------------------------------------------------------------

# 14. Segurança

-   Consultas somente leitura para usuários comuns
-   RLS aplicada às avaliações utilizadas
-   Auditoria de recálculos administrativos

------------------------------------------------------------------------

# 15. Integrações

-   Reviews
-   Restaurants
-   Feed
-   Favoritos
-   Gamificação

------------------------------------------------------------------------

# 16. Testes

-   Ranking geral
-   Ranking por cidade
-   Ranking por categoria
-   Ranking personalizado
-   Ranking entre amigos
-   Critérios de desempate
-   Atualização automática
-   Performance das consultas

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Rankings exibidos corretamente
-   Filtros funcionando
-   Atualização automática validada
-   Desempates corretos
-   Desempenho dentro dos SLAs

------------------------------------------------------------------------

# 18. Checklist

-   Ranking geral
-   Ranking por cidade
-   Ranking por categoria
-   Ranking personalizado
-   Ranking entre amigos
-   Cache implementado
-   Testes concluídos

------------------------------------------------------------------------

# 19. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Rankings por período (semana, mês e ano)
-   Tendências de crescimento
-   Ranking por região geográfica
-   Recomendação baseada em IA
-   Score de confiabilidade das avaliações
-   Ranking por grupos privados
-   Histórico de posições
-   Atualização em tempo real via Supabase Realtime
