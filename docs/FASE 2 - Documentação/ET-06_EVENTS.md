# ET-06 — Eventos

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-06_EVENTS.md

---

# 1. Objetivo

Definir a especificação técnica do módulo de Eventos do BORAH, responsável pelo planejamento, organização e acompanhamento dos encontros gastronômicos dos grupos.

---

# 2. Escopo

O módulo permitirá:

- Criar eventos
- Agendar encontros
- Selecionar restaurante
- Definir o responsável pela escolha
- Confirmar presença (RSVP)
- Realizar check-in
- Encerrar eventos
- Gerar histórico

---

# 3. Funcionalidades

## Criação de Evento

Campos obrigatórios:

- Grupo
- Restaurante
- Data
- Horário
- Responsável pela escolha

Campos opcionais:

- Descrição
- Observações
- Limite de participantes

Regras:

- Apenas membros podem criar eventos.
- Apenas um evento ativo por grupo (MVP).
- O restaurante deve existir na base do BORAH ou ser importado via Google Places.

---

## Confirmação de Presença (RSVP)

Status possíveis:

- Confirmado
- Talvez
- Recusado
- Sem resposta

Os membros poderão alterar sua resposta até o início do evento.

---

## Check-in

O check-in confirma que o participante compareceu ao encontro.

Regras:

- Disponível apenas durante a janela do evento.
- Um check-in por usuário.
- Após o check-in, o usuário poderá realizar a avaliação.

---

## Encerramento

Ao finalizar o evento:

- Bloquear novos check-ins.
- Liberar avaliações pendentes.
- Atualizar estatísticas.
- Atualizar XP.
- Atualizar rankings.

---

# 4. Regras de Negócio

RN-001 — Todo evento pertence a um grupo.

RN-002 — Apenas membros podem participar.

RN-003 — Apenas participantes confirmados podem realizar check-in.

RN-004 — Avaliações só poderão ser enviadas após o check-in.

RN-005 — Eventos encerrados não poderão ser editados.

RN-006 — O histórico permanecerá disponível para consulta.

---

# 5. Modelo de Dados

## events

Campos principais:

- id
- group_id
- restaurant_id
- organizer_id
- chooser_id
- title
- description
- scheduled_at
- status
- created_at
- updated_at

---

## attendances

Campos principais:

- id
- event_id
- user_id
- status
- checked_in_at
- created_at

---

# 6. Fluxo do Evento

1. Criar evento.
2. Convidar participantes.
3. Confirmar presença.
4. Realizar check-in.
5. Participar do encontro.
6. Avaliar restaurante.
7. Atualizar rankings e estatísticas.
8. Arquivar no histórico.

---

# 7. APIs

Eventos

- POST /api/v1/events
- GET /api/v1/events
- GET /api/v1/events/{id}
- PATCH /api/v1/events/{id}
- DELETE /api/v1/events/{id}

Presença

- POST /api/v1/events/{id}/attendance
- PATCH /api/v1/events/{id}/attendance

Check-in

- POST /api/v1/events/{id}/check-in

Histórico

- GET /api/v1/events/history

---

# 8. Segurança

- Apenas membros do grupo acessam o evento.
- Apenas usuários autenticados podem confirmar presença.
- Todas as alterações deverão ser auditadas.
- Check-in protegido contra duplicidade.

---

# 9. Testes

Cobrir:

- Criação de evento
- Alteração de evento
- Cancelamento
- RSVP
- Check-in
- Encerramento
- Histórico
- Permissões

---

# 10. Critérios de Aceite

- Evento criado corretamente.
- Convites enviados.
- RSVP funcionando.
- Check-in validado.
- Histórico persistido.
- APIs documentadas.
- Testes aprovados.

---

# 11. Checklist

- Estrutura definida
- Modelo de dados revisado
- Fluxos documentados
- APIs especificadas
- Segurança validada
- Casos de teste definidos
