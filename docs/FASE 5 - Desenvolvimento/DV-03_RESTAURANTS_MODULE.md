# DV-03 --- Restaurants Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-03_RESTAURANTS_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação completa do módulo de restaurantes do BORAH,
responsável pelo cadastro, descoberta, busca, consulta e gerenciamento
das informações dos restaurantes utilizados pela plataforma.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Cadastro de restaurantes
-   Listagem
-   Busca
-   Filtros
-   Detalhes
-   Fotos
-   Categorias
-   Localização
-   Integração com mapas
-   Integração futura com Google Places

------------------------------------------------------------------------

# 3. Regras de Negócio

-   Restaurantes não podem ser duplicados.
-   Nome e localização devem ser validados.
-   Todo restaurante deve possuir ao menos uma categoria.
-   Fotos devem seguir as políticas do Storage.
-   Apenas usuários autorizados poderão editar dados estruturais.

------------------------------------------------------------------------

# 4. Fluxo Funcional

``` text
Buscar Restaurante
        ↓
Encontrado?
   ↓           ↓
 Sim          Não
 ↓             ↓
Detalhes   Solicitar Cadastro
     ↓           ↓
 Avaliar   Moderação (quando aplicável)
```

------------------------------------------------------------------------

# 5. Funcionalidades

## Cadastro

-   Nome
-   Categoria
-   Endereço
-   Cidade
-   Estado
-   CEP
-   Latitude
-   Longitude
-   Fotos
-   Horário de funcionamento
-   Contato
-   Website
-   Redes sociais

## Listagem

-   Mais bem avaliados
-   Mais recentes
-   Próximos
-   Favoritos
-   Tendências

## Busca

-   Nome
-   Cidade
-   Categoria
-   Endereço

## Filtros

-   Categoria
-   Nota
-   Cidade
-   Distância
-   Faixa de preço
-   Aberto agora

## Detalhes

-   Informações gerais
-   Fotos
-   Avaliações
-   Ranking
-   Localização
-   Horários
-   Contatos

------------------------------------------------------------------------

# 6. Telas

-   Listagem
-   Busca
-   Filtros
-   Detalhes
-   Cadastro (quando permitido)

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
restaurants/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── restaurants.dart
```

------------------------------------------------------------------------

# 9. Modelo de Dados

  Campo            Tipo
  ---------------- -----------
  id               UUID
  name             String
  category         String
  description      String
  address          String
  city             String
  state            String
  latitude         Decimal
  longitude        Decimal
  average_rating   Decimal
  total_reviews    Integer
  cover_image      String
  created_at       Timestamp
  updated_at       Timestamp

------------------------------------------------------------------------

# 10. Estados

-   Initial
-   Loading
-   Loaded
-   Searching
-   Filtering
-   Empty
-   Error

------------------------------------------------------------------------

# 11. Busca e Filtros

Suportar:

-   Busca parcial
-   Ordenação
-   Paginação
-   Combinação de filtros
-   Cache de resultados recentes

------------------------------------------------------------------------

# 12. Fotos

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
Storage
```

Regras:

-   JPG, PNG ou WEBP
-   Máximo 10 MB
-   Compressão obrigatória

------------------------------------------------------------------------

# 13. Integrações

## Banco

-   Consulta
-   Cadastro
-   Atualização

## Storage

-   Fotos
-   Capa

## Futuro

-   Google Places
-   Mapas

------------------------------------------------------------------------

# 14. Segurança

-   RLS para alterações
-   Leitura pública quando aplicável
-   Upload protegido
-   Auditoria de alterações

------------------------------------------------------------------------

# 15. Tratamento de Erros

-   Restaurante não encontrado
-   Busca sem resultados
-   Falha de upload
-   Dados inválidos
-   Sem conexão
-   Permissão insuficiente

------------------------------------------------------------------------

# 16. Testes

-   Cadastro
-   Busca
-   Filtros
-   Paginação
-   Detalhes
-   Upload de imagens
-   Integrações
-   Segurança

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Cadastro funcional
-   Busca rápida
-   Filtros corretos
-   Detalhes completos
-   Upload operacional
-   Integração validada

------------------------------------------------------------------------

# 18. Checklist

-   Cadastro implementado
-   Listagem implementada
-   Busca implementada
-   Filtros implementados
-   Detalhes implementados
-   Upload de imagens
-   Testes concluídos

------------------------------------------------------------------------

# 19. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Integração completa com Google Places
-   Geolocalização em tempo real
-   QR Code do restaurante
-   Horários especiais
-   Cardápio digital
-   Reservas
-   Inteligência para recomendações
-   Fotos verificadas
-   Sugestão automática de novos restaurantes
