# ET-09 — Feed e Compartilhamento

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-09_FEED_AND_SHARING.md

---

# 1. Objetivo

Definir a especificação técnica do módulo de Feed e Compartilhamento do BORAH, responsável por registrar, exibir e compartilhar as experiências gastronômicas dos usuários e grupos.

---

# 2. Escopo

O módulo permitirá:

- Exibir um feed de atividades
- Publicar registros dos eventos
- Compartilhar fotos
- Curtir publicações
- Comentar experiências
- Compartilhar conteúdos externamente
- Gerar retrospectivas (Wrapped)

---

# 3. Funcionalidades

## Feed

O feed apresentará:

- Eventos realizados
- Restaurantes visitados
- Avaliações recentes
- Novas badges
- Conquistas
- Novos membros
- Rankings atualizados

Ordenação padrão:

- Mais recentes primeiro.

---

## Publicações

Cada publicação poderá conter:

- Evento relacionado
- Restaurante
- Texto
- Fotos
- Data
- Autor

---

## Fotos

Cada evento poderá possuir um álbum compartilhado.

Regras:

- Apenas participantes podem enviar fotos.
- Limite de tamanho por imagem.
- Compressão automática.
- Exclusão apenas pelo autor ou administrador do grupo.

---

## Curtidas

Usuários poderão curtir publicações e comentários.

Cada usuário poderá registrar apenas uma curtida por item.

---

## Comentários

Comentários poderão:

- Receber respostas (futuro)
- Ser editados por tempo limitado
- Ser removidos pelo autor ou administrador

---

## Wrapped

O sistema poderá gerar retrospectivas contendo:

- Restaurantes mais visitados
- Melhor escolha do ano
- Ranking do grupo
- Total de eventos
- Quilômetros percorridos (futuro)
- Estatísticas pessoais

---

# 4. Regras de Negócio

RN-001 — Apenas membros do grupo visualizam conteúdos privados.

RN-002 — Apenas participantes do evento podem publicar fotos.

RN-003 — Conteúdos removidos permanecem registrados para auditoria quando necessário.

RN-004 — Publicações relacionadas a eventos permanecem disponíveis no histórico.

---

# 5. Modelo de Dados

## posts

Campos principais:

- id
- user_id
- event_id
- restaurant_id
- content
- visibility
- created_at

---

## post_images

- id
- post_id
- image_url
- created_at

---

## comments

- id
- post_id
- user_id
- content
- created_at

---

## likes

- id
- user_id
- post_id
- created_at

---

# 6. APIs

Feed

- GET /api/v1/feed
- GET /api/v1/feed/{id}

Publicações

- POST /api/v1/posts
- PATCH /api/v1/posts/{id}
- DELETE /api/v1/posts/{id}

Fotos

- POST /api/v1/posts/{id}/images

Comentários

- POST /api/v1/posts/{id}/comments
- DELETE /api/v1/comments/{id}

Curtidas

- POST /api/v1/posts/{id}/like
- DELETE /api/v1/posts/{id}/like

Wrapped

- GET /api/v1/users/me/wrapped

---

# 7. Segurança

- Autenticação obrigatória.
- Controle de visibilidade.
- Moderação de conteúdo.
- Auditoria de exclusões.
- Validação de uploads.

---

# 8. Performance

- Paginação do feed.
- Lazy Loading de imagens.
- Compressão de mídia.
- Cache para conteúdos populares.

---

# 9. Testes

Cobrir:

- Publicação de conteúdo
- Upload de fotos
- Curtidas
- Comentários
- Wrapped
- Controle de permissões
- Exclusão de conteúdo

---

# 10. Critérios de Aceite

- Feed atualizado corretamente.
- Fotos armazenadas.
- Comentários funcionando.
- Curtidas persistidas.
- Wrapped gerado.
- APIs documentadas.
- Testes aprovados.

---

# 11. Checklist

- Modelo de dados revisado
- APIs definidas
- Segurança validada
- Estratégia de armazenamento de mídia definida
- Casos de teste documentados
