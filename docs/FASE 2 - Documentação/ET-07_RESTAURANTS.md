# ET-07 — Restaurantes

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-07_RESTAURANTS.md

---

# 1. Objetivo

Definir a especificação técnica do módulo de Restaurantes do BORAH, responsável pela descoberta, armazenamento, sincronização e utilização dos estabelecimentos gastronômicos dentro da plataforma.

---

# 2. Escopo

O módulo permitirá:

- Buscar restaurantes
- Importar dados do Google Places
- Manter um cache local
- Exibir detalhes dos estabelecimentos
- Favoritar restaurantes
- Consultar histórico de visitas
- Associar restaurantes aos eventos

---

# 3. Fontes de Dados

## Google Places API

Fonte principal de informações.

Dados importados:

- Place ID
- Nome
- Endereço
- Latitude
- Longitude
- Fotos
- Categoria
- Horário de funcionamento
- Avaliação média
- Telefone
- Website

---

## Base Local BORAH

Após a primeira consulta, os dados poderão ser armazenados localmente para reduzir custos e melhorar desempenho.

---

# 4. Funcionalidades

## Busca

Filtros:

- Nome
- Cidade
- Categoria
- Distância
- Avaliação
- Favoritos

---

## Detalhes

Cada restaurante exibirá:

- Nome
- Endereço
- Fotos
- Categoria
- Localização
- Horários
- Avaliações do BORAH
- Avaliação Google
- Histórico de eventos realizados

---

## Favoritos

Usuários poderão:

- Adicionar aos favoritos
- Remover dos favoritos
- Consultar lista de favoritos

---

## Histórico

Será possível visualizar:

- Quantas vezes o grupo visitou
- Quantas vezes o usuário visitou
- Última visita
- Média das avaliações do grupo

---

# 5. Regras de Negócio

RN-001 — Restaurantes serão identificados pelo Google Place ID.

RN-002 — O cache local poderá ser atualizado periodicamente.

RN-003 — Restaurantes não poderão ser removidos caso possuam histórico de eventos.

RN-004 — Um restaurante poderá estar associado a diversos eventos.

RN-005 — Favoritos são individuais por usuário.

---

# 6. Modelo de Dados

## restaurants

Campos principais:

- id
- google_place_id
- name
- address
- city
- state
- country
- latitude
- longitude
- phone
- website
- category
- google_rating
- created_at
- updated_at

---

## favorite_restaurants

Campos principais:

- id
- user_id
- restaurant_id
- created_at

---

# 7. APIs

Busca

- GET /api/v1/restaurants
- GET /api/v1/restaurants/{id}
- GET /api/v1/restaurants/search

Favoritos

- POST /api/v1/restaurants/{id}/favorite
- DELETE /api/v1/restaurants/{id}/favorite
- GET /api/v1/users/me/favorites

---

# 8. Segurança

- Consultas autenticadas quando relacionadas ao usuário.
- Proteção contra abuso da Google Places API.
- Rate Limiting.
- Cache para redução de chamadas externas.

---

# 9. Performance

- Cache local obrigatório.
- Paginação nas buscas.
- Lazy Loading de imagens.
- Atualização assíncrona de dados externos.

---

# 10. Testes

Cobrir:

- Busca de restaurantes
- Sincronização com Google Places
- Favoritar e desfavoritar
- Histórico de visitas
- Associação com eventos
- Paginação
- Cache

---

# 11. Critérios de Aceite

- Busca funcionando
- Importação de dados validada
- Favoritos persistidos
- Histórico disponível
- APIs documentadas
- Testes aprovados

---

# 12. Checklist

- Modelo de dados revisado
- APIs documentadas
- Integração com Google Places definida
- Cache especificado
- Segurança validada
- Casos de teste definidos
