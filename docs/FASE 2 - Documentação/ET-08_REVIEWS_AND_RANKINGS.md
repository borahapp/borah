# ET-08 — Avaliações e Rankings

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-08_REVIEWS_AND_RANKINGS.md

---

# 1. Objetivo

Definir a especificação técnica do módulo de Avaliações e Rankings do BORAH, responsável por registrar experiências gastronômicas, calcular pontuações e incentivar a participação por meio de gamificação.

---

# 2. Escopo

O módulo permitirá:

- Avaliar restaurantes após um evento
- Calcular a nota média dos restaurantes
- Gerar rankings de participantes
- Distribuir XP
- Registrar conquistas (badges)
- Exibir estatísticas individuais e do grupo

---

# 3. Avaliações

Cada participante poderá avaliar um restaurante apenas uma vez por evento.

## Critérios

- Qualidade da comida
- Bebidas
- Atendimento
- Ambiente
- Música
- Tempo de espera
- Custo-benefício
- Limpeza
- Voltaria ao restaurante? (Sim/Não)
- Comentário opcional

Escala sugerida:

- 1 a 5 estrelas

---

# 4. Regras de Negócio

RN-001 — Apenas participantes com check-in poderão avaliar.

RN-002 — Apenas uma avaliação por usuário por evento.

RN-003 — Avaliações encerradas não poderão ser alteradas após o prazo definido.

RN-004 — A nota geral do restaurante será calculada pela média ponderada dos critérios.

RN-005 — Comentários poderão ser moderados pelo administrador da plataforma.

---

# 5. Rankings

O sistema manterá rankings por grupo e temporada.

Tipos:

- Melhor escolha de restaurante
- Maior XP
- Mais eventos organizados
- Mais participações
- Melhor avaliador (consistência)

As regras de pontuação poderão evoluir sem alterar o histórico.

---

# 6. XP e Gamificação

Exemplos de ações que geram XP:

- Participar de evento
- Criar evento
- Realizar check-in
- Enviar avaliação
- Convidar novos membros
- Concluir desafios

A tabela oficial de XP será mantida em documento específico de gamificação.

---

# 7. Badges

Exemplos:

- Explorador Gastronômico
- Mestre do Churrasco
- Rei da Pizza
- Organizador do Mês
- Crítico Gastronômico

Cada badge possuirá critérios de desbloqueio.

---

# 8. Modelo de Dados

## reviews

Campos principais:

- id
- event_id
- restaurant_id
- user_id
- food_score
- drinks_score
- service_score
- ambience_score
- music_score
- waiting_time_score
- cost_benefit_score
- cleanliness_score
- would_return
- comment
- created_at

---

## rankings

Campos principais:

- id
- group_id
- season_id
- user_id
- points
- position
- updated_at

---

## badges

- id
- name
- description
- icon
- created_at

---

## user_badges

- id
- user_id
- badge_id
- unlocked_at

---

# 9. APIs

Avaliações

- POST /api/v1/reviews
- GET /api/v1/reviews/{id}
- GET /api/v1/events/{id}/reviews

Rankings

- GET /api/v1/groups/{id}/ranking
- GET /api/v1/users/{id}/ranking

Badges

- GET /api/v1/users/{id}/badges

---

# 10. Segurança

- Apenas participantes autorizados podem avaliar.
- Proteção contra avaliações duplicadas.
- Auditoria de alterações.
- Moderação de conteúdo inadequado.

---

# 11. Performance

- Atualização assíncrona dos rankings.
- Cache para consultas frequentes.
- Recalcular apenas dados afetados por novas avaliações.

---

# 12. Testes

Cobrir:

- Envio de avaliação
- Avaliação duplicada
- Cálculo da média
- Atualização do ranking
- Concessão de XP
- Desbloqueio de badges
- Permissões

---

# 13. Critérios de Aceite

- Avaliações registradas corretamente.
- Ranking atualizado.
- XP atribuído.
- Badges desbloqueadas.
- APIs documentadas.
- Testes aprovados.

---

# 14. Checklist

- Modelo de dados revisado
- Regras de negócio documentadas
- APIs definidas
- Segurança validada
- Performance analisada
- Casos de teste definidos
