# ET-13 — Engine de Gamificação

**Versão:** 1.0  
**Status:** Draft  
**Documento:** ET-13_GAMIFICATION_ENGINE.md

---

# 1. Objetivo

Definir a arquitetura da Engine de Gamificação do BORAH, responsável pela atribuição de XP, níveis, badges, desafios, temporadas e rankings.

---

# 2. Escopo

A Engine será responsável por:

- Calcular XP
- Evolução de níveis
- Desbloqueio de badges
- Missões e desafios
- Temporadas
- Rankings
- Estatísticas

---

# 3. Princípios

- Regras centralizadas
- Fácil balanceamento
- Histórico preservado
- Regras configuráveis
- Processamento assíncrono quando possível

---

# 4. XP

Exemplos de ações:

| Ação | XP |
|------|---:|
| Participar de evento | 50 |
| Criar evento | 100 |
| Check-in | 25 |
| Avaliar restaurante | 40 |
| Convidar membro | 75 |
| Completar desafio | Variável |

Os valores poderão ser alterados sem necessidade de migração de banco.

---

# 5. Níveis

A progressão será baseada em XP acumulado.

Exemplo:

- Nível 1: 0 XP
- Nível 2: 200 XP
- Nível 3: 500 XP
- Nível 4: 900 XP

A fórmula poderá evoluir ao longo do projeto.

---

# 6. Badges

Cada badge possuirá:

- id
- nome
- descrição
- ícone
- critérios
- raridade

Exemplos:

- Explorador
- Crítico Gastronômico
- Mestre do Hambúrguer
- Organizador do Mês

---

# 7. Desafios

Tipos:

- Diário
- Semanal
- Mensal
- Sazonal

Exemplos:

- Participar de 3 eventos
- Avaliar 5 restaurantes
- Conhecer uma nova categoria

---

# 8. Temporadas

Cada grupo poderá criar temporadas independentes.

Cada temporada armazenará:

- período
- ranking
- estatísticas
- campeão

O histórico será preservado.

---

# 9. Ranking

Critérios:

- XP
- Eventos organizados
- Participações
- Avaliações
- Desafios concluídos

Regras de desempate:

1. Maior XP
2. Maior número de eventos
3. Maior número de avaliações
4. Data de entrada no grupo

---

# 10. Eventos Internos

A Engine responderá a eventos como:

- EventCreated
- CheckInCompleted
- ReviewSubmitted
- BadgeUnlocked
- SeasonFinished

---

# 11. APIs

- GET /api/v1/gamification/profile
- GET /api/v1/gamification/ranking
- GET /api/v1/gamification/badges
- GET /api/v1/gamification/challenges

---

# 12. Testes

Cobrir:

- Cálculo de XP
- Evolução de níveis
- Desbloqueio de badges
- Atualização de ranking
- Encerramento de temporadas
- Regras de desempate

---

# 13. Critérios de Aceite

- XP calculado corretamente
- Níveis atualizados
- Badges concedidas
- Ranking consistente
- Histórico preservado

---

# 14. Checklist

- Regras documentadas
- Modelo validado
- APIs definidas
- Casos de teste criados
- Balanceamento revisado
