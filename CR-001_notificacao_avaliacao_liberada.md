# CR-001 — Notificação automática de avaliação liberada

**Status:** Aberto — aguardando decisão do usuário, conforme processo de Change Request definido em `BORAH_PRODUCT_BASELINE_v2.0.md §6/§8`.
**Origem:** descoberto durante a implementação da Sprint 0 (`RC03_IMPLEMENTATION_PLAN.md`), ao tentar implementar F41 (item Core do `RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md §4`).
**Nenhuma solução foi implementada.** Este documento só analisa opções.

---

## Problema

O BORAH 2.0 precisa notificar automaticamente cada participante confirmado de um rolê, assim que a avaliação coletiva daquele rolê se torna elegível para ser enviada — fechando o loop comportamental "o rolê aconteceu → avalie agora" (achado confirmado de forma independente em `RC03_UX_AUDIT.md §2.6`, `RC03_PRODUCT_AUDIT.md §2.13` e `RC03_FEATURE_GAP.md`, e já era uma promessa da ficha de loja atual).

## Motivo técnico

A elegibilidade para avaliar (`public.can_review_event(uid, eid)`, `supabase/migrations/20260801100000_create_event_reviews.sql:74-90`) depende de uma condição baseada em tempo:

```sql
ea.status = 'confirmed' and e.status = 'scheduled' and e.scheduled_at <= now()
```

Um trigger Postgres só reage a um evento real de INSERT/UPDATE/DELETE em uma linha — nunca à passagem do relógio até um valor. Não existe nenhum INSERT/UPDATE que aconteça exatamente no instante em que `scheduled_at` passa a estar no passado; nenhuma linha muda sozinha nesse momento. Confirmado meio código, não hipótese: `20260801130000_add_group_event_notifications.sql:9-17` já documentava esse exato bloqueio desde 1/ago/2026, ao decidir deliberadamente não implementar esta notificação junto com as outras 3 da mesma migration — "dependeria de um evento que não existe no Postgres... nenhuma extensão `pg_cron` instalada, nenhuma infraestrutura de scheduler". Esta investigação (Sprint 0) confirma, de forma independente, que o diagnóstico de 1/ago continua correto hoje.

## Opções possíveis

### Opção A — `pg_cron` (ou Edge Function agendada) verificando periodicamente
Um job agendado (ex.: a cada 15-30 min) varre `event_attendances` confirmadas cujo rolê passou de `scheduled_at` e ainda não geraram a notificação, chamando `create_notification()` para cada uma.

**Vantagens:** solução "correta" e completa — cobre 100% dos casos, incluindo quem confirmou presença muito antes do rolê acontecer. Não depende de nenhuma ação do usuário no app para disparar. Consistente com o padrão de automação server-side já usado em todo o projeto (backend decide, não o cliente).

**Desvantagens:** requer decidir e instalar uma peça de infraestrutura que nunca existiu neste projeto (`pg_cron` como extensão Postgres, ou uma Edge Function com agendamento externo). Precisa de uma coluna/mecanismo para marcar "já notificado" (idempotência), o que não existe hoje em `event_attendances`/`event_reviews`. Introduz uma superfície operacional nova (jobs agendados podem falhar silenciosamente, exigem monitoramento).

### Opção B — verificação lazy client-invocada
Quando o app abre a tela de detalhe do rolê (ou a lista de rolês do grupo), o Flutter chama uma função/RPC que checa `can_review_event()` para o usuário atual e, se verdadeiro e ainda não notificado, dispara `create_notification()` naquele momento.

**Vantagens:** não exige nenhuma infraestrutura de scheduler nova — reaproveita 100% o padrão de RPC já usado em todo o app. Menor superfície de risco operacional (não há job rodando em segundo plano).

**Desvantagens:** só dispara se o usuário efetivamente abrir o app/a tela depois que a janela de avaliação já abriu — quem não abre o app não é notificado (o que enfraquece justamente o objetivo original: trazer de volta quem esqueceu). Exige mudança em arquivos Flutter (`EventDetailController`, possivelmente `EventsListController`) que não estavam no escopo aprovado da Sprint 0. Precisa da mesma marca de idempotência da Opção A para não notificar 2x.

### Opção C — não implementar; manter como decisão de escopo consciente
Registrar oficialmente que esta notificação específica fica fora do BORAH 2.0 por ora (mesmo tratamento já dado a Push/FCM, Futuro no PRD), sem instalar nenhuma infraestrutura nova.

**Vantagens:** zero risco, zero esforço, zero mudança de arquitetura.

**Desvantagens:** um item **Core** do PRD fica sem entrega — precisaria de reclassificação formal (Core → Futuro) para não ficar "pendente silenciosamente", o que o próprio Baseline proíbe (§9 do `RC03_IMPLEMENTATION_PLAN.md`: "não é aceitável que fiquem esquecidos sem decisão explícita").

## Impacto arquitetural

- **Opção A**: adiciona uma peça de infraestrutura nova (scheduler) — o único das 3 opções que toca a arquitetura congelada (`BORAH_PRODUCT_BASELINE_v2.0.md §2`). Exigiria aprovação explícita adicional, específica sobre essa mudança estrutural, antes de prosseguir (mesma regra já registrada no `RC03_IMPLEMENTATION_PLAN.md §1`).
- **Opção B**: não toca a arquitetura (RPC chamada por controller já é o padrão existente), mas expande o escopo de arquivos Flutter aprovado para a sprint que a implementar.
- **Opção C**: nenhum impacto arquitetural.

## Impacto operacional

- **Opção A**: exige decidir entre `pg_cron` (extensão nativa do Postgres/Supabase, roda dentro do banco) ou Edge Function com agendamento externo (roda fora, precisa de configuração de deploy/cron na plataforma Supabase); requer monitoramento de falha do job; frequência do job é um trade-off direto entre "atraso máximo até notificar" e "custo de execução".
- **Opção B**: nenhuma peça operacional nova; o "custo" vira parte do carregamento normal da tela (latência adicional pequena, 1 RPC a mais).
- **Opção C**: nenhum impacto operacional.

## Recomendação técnica

**Opção B, como ponte de curto prazo, com reavaliação para Opção A se os dados de uso mostrarem que muitos usuários não voltam ao app espontaneamente.** Justificativa: a Opção B entrega valor real imediatamente (fecha o loop para quem volta ao app por qualquer motivo, que é provavelmente a maioria — o app já tem outros ganchos de retorno, como o próprio badge/XP), sem adicionar uma peça de infraestrutura nova a um projeto cuja arquitetura está deliberadamente congelada nesta fase. A Opção A é objetivamente mais completa e é o destino correto de longo prazo, mas instalar `pg_cron` "só para isso" é desproporcional ao problema enquanto não há evidência de que a Opção B seja insuficiente na prática. A Opção C não é recomendada — deixaria um item Core do PRD sem solução e sem prazo, o que o processo desta sessão já rejeitou explicitamente ao classificar F41 como Core.

Esta é uma recomendação, não uma decisão — aguardando escolha explícita do usuário antes de qualquer implementação.
