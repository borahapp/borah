# ET-10 — Notificações

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-10_NOTIFICATIONS.md

---

# 1. Objetivo

Definir a especificação técnica do módulo de Notificações do BORAH, responsável por manter os usuários informados sobre eventos, convites, interações e atualizações relevantes.

---

# 2. Escopo

O módulo permitirá:

- Enviar notificações push
- Exibir central de notificações
- Configurar preferências do usuário
- Registrar histórico de notificações
- Agendar lembretes automáticos

---

# 3. Tecnologias

- Firebase Cloud Messaging (FCM)
- NestJS
- PostgreSQL
- Flutter Local Notifications (quando aplicável)

---

# 4. Tipos de Notificações

## Grupos
- Convite para grupo
- Entrada de novo membro
- Promoção para administrador
- Remoção de membro

## Eventos
- Evento criado
- Alteração de data ou horário
- Lembrete do evento
- Cancelamento
- Check-in disponível

## Avaliações
- Avaliação pendente
- Ranking atualizado
- Nova badge conquistada

## Sistema
- Atualizações importantes
- Novidades
- Avisos de manutenção

---

# 5. Preferências

Cada usuário poderá configurar:

- Receber push
- Receber e-mail (futuro)
- Lembretes de eventos
- Notificações de grupos
- Conquistas
- Marketing

---

# 6. Regras de Negócio

RN-001 — Apenas notificações autorizadas pelas preferências do usuário serão enviadas.

RN-002 — Notificações críticas não poderão ser desativadas.

RN-003 — Cada notificação deverá possuir status (não lida, lida, arquivada).

RN-004 — O histórico ficará disponível na central de notificações.

---

# 7. Modelo de Dados

## notifications

Campos:

- id
- user_id
- type
- title
- message
- payload
- is_read
- sent_at
- read_at
- created_at

---

# 8. Fluxo

1. Evento ocorre no sistema.
2. Backend identifica destinatários.
3. Preferências são verificadas.
4. Notificação é registrada.
5. Push enviado via FCM.
6. Usuário visualiza e marca como lida.

---

# 9. APIs

- GET /api/v1/notifications
- PATCH /api/v1/notifications/{id}/read
- PATCH /api/v1/notifications/read-all
- DELETE /api/v1/notifications/{id}
- PATCH /api/v1/users/me/notification-preferences

---

# 10. Segurança

- Autenticação obrigatória
- Entrega apenas ao destinatário
- Payload validado
- Auditoria de envio

---

# 11. Performance

- Envio assíncrono
- Filas para processamento
- Paginação da central
- Retentativas automáticas em caso de falha

---

# 12. Testes

Cobrir:

- Envio de push
- Preferências do usuário
- Marcar como lida
- Marcar todas como lidas
- Exclusão
- Lembretes automáticos
- Recuperação do histórico

---

# 13. Critérios de Aceite

- Push entregue corretamente
- Preferências respeitadas
- Histórico disponível
- APIs documentadas
- Testes aprovados

---

# 14. Checklist

- Modelo de dados revisado
- Integração FCM definida
- APIs documentadas
- Segurança validada
- Casos de teste definidos
