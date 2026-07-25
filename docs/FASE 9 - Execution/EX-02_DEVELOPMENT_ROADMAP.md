# EX-02 --- Development Roadmap

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-02_DEVELOPMENT_ROADMAP.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a sequência oficial de implementação do projeto BORAH,
garantindo que cada etapa seja construída sobre dependências já
concluídas, reduzindo retrabalho e preservando a integridade da
arquitetura.

------------------------------------------------------------------------

# 2. Princípios

-   A documentação é a **Single Source of Truth**.
-   Nenhum documento pode ser implementado antes de suas dependências.
-   Cada etapa deve ser concluída, testada e aprovada antes da próxima.
-   Não implementar funcionalidades fora do roadmap.

------------------------------------------------------------------------

# 3. Fluxo Geral

``` text
Planejamento
    ↓
Engenharia
    ↓
UX/UI
    ↓
Arquitetura
    ↓
Desenvolvimento
    ↓
QA
    ↓
Publicação
    ↓
Marketing
```

------------------------------------------------------------------------

# 4. Ordem de Implementação

## Fase 0 --- Bootstrap

1.  EX-01 --- Project Bootstrap
2.  EX-02 --- Development Roadmap
3.  EX-03 --- Claude Code Operating Manual
4.  EX-04 --- Definition of Done
5.  EX-05 --- Release Roadmap
6.  EX-06 --- AI Development Workflow
7.  EX-07 --- Master Prompt
8.  EX-08 --- Knowledge Base & ADR

------------------------------------------------------------------------

## Fase 1 --- Planejamento

Implementar todos os documentos ET-\* na ordem numérica.

**Marco de aceite:** requisitos congelados e aprovados.

------------------------------------------------------------------------

## Fase 2 --- Engenharia

Implementar todos os documentos EN-\* (ou equivalente definido no
projeto) na ordem numérica.

**Marco de aceite:** regras de negócio completas e validadas.

------------------------------------------------------------------------

## Fase 3 --- UX/UI

Implementar todos os documentos UX-\*.

**Marco de aceite:** - Design System - Protótipos - Fluxos de
navegação - Componentes aprovados

------------------------------------------------------------------------

## Fase 4 --- Arquitetura

Implementar todos os documentos AR-\*.

**Marco de aceite:** - Estrutura backend - Estrutura Flutter - Banco de
dados - APIs - Infraestrutura

------------------------------------------------------------------------

## Fase 5 --- Desenvolvimento

**Status: Concluída (2026-07-20).** Ver
`EX-09_FASE_5_COMPLETION_REPORT.md` para o relatório de encerramento
(módulos entregues, decisões arquiteturais, lacunas documentais e
dependências adiadas por infraestrutura).

Implementar todos os documentos DV-\* individualmente.

Para cada DV:

1.  Ler documentação relacionada
2.  Implementar
3.  Executar testes
4.  Atualizar documentação
5.  Gerar commit sugerido
6.  Aguardar aprovação

Nunca iniciar DV seguinte sem concluir o atual.

------------------------------------------------------------------------

## Fase 6 --- QA

**Status: Em andamento** (Tier 2 de Widget Tests **concluído** em
2026-07-21 — 5/5 itens: Detalhe do Restaurante, Detalhe da Avaliação,
Favoritar, Feed e Editar Perfil). Auditoria de Encerramento da FASE 6
realizada em 2026-07-21/22 (recomendação: executar rodadas adicionais
antes do encerramento formal — ver `EX-10_FASE_6_QA_STATUS.md` §6).
**QA-03 (Integration Testing) iniciado em 2026-07-22** para eliminar o
maior bloqueador identificado: Rodada 0 concluída — ambiente Supabase
dedicado `borah-qa` provisionado e validado estruturalmente contra o
Development (commit `60f60c8`, merge `45fda6c`). **Rodada A concluída
— infraestrutura local de Integration Tests oficialmente homologada**:
scaffolding do pacote `integration_test` implementado e smoke test
aprovado (1/1) em emulador Android real (`emulator-5554`, Android 16),
com conexão validada ponta a ponta contra o `borah-qa` (commit
`b44fb33`). Suíte de unit/widget tests sem regressão (242/242).
**Rodada B concluída — Autenticação homologada ponta a ponta**: 4/4
cenários (Cadastro, Login, Logout, Persistência) aprovados em
emulador Android real contra o `borah-qa` (commit `4b8ec67` +
estabilização). Durante a rodada, um bug real de condição de corrida
em `AuthController.signUp()` foi encontrado e corrigido (estado
indeterminístico quando "Confirm email" está desabilitado) — corrigido
de forma determinística, sem duplicar regra de negócio, funcionando
para os dois cenários de configuração. Suíte de unit/widget tests sem
regressão (243/243). Rodadas C--E liberadas para implementação;
Rodada F (CI) pendente da configuração manual de 4 GitHub Secrets. Ver
`EX-10_FASE_6_QA_STATUS.md` §7 para o progresso detalhado e
pendências (rotação de `SERVICE_ROLE_KEY`, criação de buckets de
Storage, GitHub Secrets).

**Release Candidate iniciado em 2026-07-25.** **RC-01 (Auditoria
Completa da Aplicação) concluída** — revisão somente-leitura de todos
os fluxos, Design System, Motion Design, Performance, Acessibilidade,
Código/Arquitetura e Testes, sem nenhuma alteração de código; ver
`RC-01_APPLICATION_AUDIT.md` para o levantamento completo e a
priorização de melhorias. **RC-02 (Quick Wins) concluída** —
implementados os 5 itens de alto impacto / baixo-médio esforço / baixo
risco identificados na RC-01: componente `ErrorState` reutilizável com
retry, conexão da sincronização em tempo real de Favoritos
(`FavoritesController.refresh()`/`FavoritesSyncing`, já existentes e
nunca usados), reenvio de e-mail de verificação, fluxo de logout com
confirmação/tratamento de erro/feedback visual (incluindo correção de
um redirect indevido de rotas protegidas durante falha de logout), e
upload de fotos em Reviews sem substituir a tela inteira por um
spinner. Commits `f3789e3` (implementação) e `6790179` (refinamento da
suíte de testes) — **desenvolvidos diretamente em `develop`, sem
feature branch nesta rodada**; retomar o fluxo padrão de feature
branches a partir da próxima rodada. Suíte de unit/widget tests sem
regressão (266/266).

**RC-02.5 (Production Readiness Planning) concluída em 2026-07-25** —
auditoria técnica completa do estado atual do projeto (arquitetura,
dependências, CI/CD, Supabase/RLS/Storage, segurança, documentação) e
planejamento arquitetural para a Beta Fechada, sem nenhuma alteração de
código. Produziu um backlog priorizado (RC-03A-E observabilidade,
RC-04A-E segurança, RC-05A-E build/produção, RC-06A-E distribuição da
Beta) e uma ordem de execução recomendada. Nenhum documento novo foi
criado nesta rodada (só o relatório apresentado na conversa).

**FASE 10 — Preparação para Beta iniciada em 2026-07-25.** **RC-03A
(Crash Reporting) concluída** — infraestrutura completa de captura
global de erros via Sentry (`sentry_flutter`), centralizada em
`lib/core/observability/`: captura de erros síncronos/assíncronos via
`SentryFlutter.init` (que instala `FlutterError.onError`,
`PlatformDispatcher.instance.onError` e `runZonedGuarded` quando
necessário), integração com Riverpod (`SentryProviderObserver` —
reporta qualquer provider que falhar) e com GoRouter (`errorBuilder` —
reporta erro de navegação e mostra `ErrorState` em vez da tela de erro
padrão). Sanitização de privacidade (`sentry_event_sanitizer.dart`)
redige senha/token/JWT/refresh token/e-mail completo antes de qualquer
envio — nunca `sendDefaultPii`, nunca screenshot anexado. Suporta os 4
ambientes (Development/QA/Beta/Production) via `SENTRY_DSN` +
`APP_ENVIRONMENT` (`--dart-define`); sem DSN configurado, o SDK não
envia nenhum evento (comportamento nativo do pacote, não uma flag
customizada) — por isso Development/QA ficam silenciosos por padrão
até um projeto Sentry real ser provisionado (pendência operacional
registrada em `RC-03A_CRASH_REPORTING.md` §6). Ver
`RC-03A_CRASH_REPORTING.md` para a arquitetura completa, decisões,
limitações e como configurar um novo ambiente. Suíte de unit/widget
tests sem regressão (278/278 — 12 testes novos).

**RC-03B (Logging Estruturado) concluída em 2026-07-25** — `AppLogger`
(`lib/core/logger/`) deixou de ser código morto e virou o único canal
de logging do app, com 6 níveis (TRACE/DEBUG/INFO/WARNING/ERROR/FATAL),
API uniforme (`AppLogger.trace/debug/info/warning/error/fatal`) e
comportamento por ambiente: Development vê tudo, QA/Beta a partir de
INFO, Production só WARNING+. Apenas WARNING/ERROR/FATAL são
encaminhados ao Sentry via `CrashReporting.captureLog` (novo método em
`crash_reporting.dart`, RC-03A) — TRACE/DEBUG/INFO nunca saem do
dispositivo. Nenhuma sanitização é duplicada: o mesmo `beforeSend` da
RC-03A cobre também os eventos originados do `AppLogger`. Busca em todo
o projeto por `print()`/`debugPrint()` confirmou zero ocorrências (nada
para substituir) — achado já esperado desde a RC-01. Ver
`RC-03B_STRUCTURED_LOGGING.md` para arquitetura, convenção de `tag`,
formato do log, integração com o Sentry e a convenção que evita eventos
duplicados (erro tratado vs. erro que propaga para a captura global).
Suíte de unit/widget tests sem regressão (307/307 — 29 testes novos).

**RC-03C (Product Analytics) concluída em 2026-07-25** — camada de
Analytics do BORAH (`lib/core/analytics/`) implementada com PostHog
(`posthog_flutter`, recomendação da RC-02.5, resolvido sem conflito de
dependências), seguindo o mesmo padrão arquitetural de
`CrashReporting`/`AppLogger`: interface própria (`AnalyticsService`),
fachada estática (`AppAnalytics`) e uma única classe
(`PostHogAnalyticsService`) como fronteira com o SDK — nenhuma feature
depende do PostHog diretamente. Implementados os 19 eventos mínimos
exigidos (App Open, Login Success/Failed, Signup, Logout, Restaurant
Viewed/Favorited/Unfavorited, Review Created/Updated/Deleted, Comment
Created/Deleted, Feed/Ranking Opened, Profile Viewed/Updated, Search
Performed, Notification Opened), todos com a convenção padrão de campos
(timestamp/environment/version/screen/userId/properties) e testados.
Sanitização de privacidade reaproveita a infraestrutura da RC-03A: as
primitivas de redação foram extraídas para
`core/observability/pii_redaction.dart` (refactor sem mudança de
comportamento, confirmado pelos testes existentes do Sentry) e
estendidas com redação de telefone, exigida pela política de Analytics.
Development nunca envia eventos; QA/Beta/Production enviam (pendente de
`POSTHOG_API_KEY` real, mesma situação do `SENTRY_DSN` na RC-03A).
Wiring de eventos limitado ao ciclo de vida de autenticação
(`AuthController`: identify/reset + login/signup/logout) — os outros 14
métodos de evento estão prontos e testados, mas deliberadamente não
conectados a telas de feature nesta rodada (mesma disciplina de escopo
da RC-03A/RC-03B). Ver `RC-03C_PRODUCT_ANALYTICS.md` para arquitetura
completa, lista de eventos e o que falta conectar. Suíte de unit/widget
tests sem regressão (352/352 — 45 testes novos).

**RC-03D (Feature Flags) concluída em 2026-07-25** — infraestrutura de
Feature Flags do BORAH (`lib/core/feature_flags/`) implementada com
Supabase + Riverpod (sem PostHog Feature Flags nesta primeira versão,
por decisão explícita), seguindo o mesmo padrão arquitetural de
`CrashReporting`/`AppLogger`/`AppAnalytics`: `FeatureFlag` (modelo),
`FeatureFlagRepository`/`SupabaseFeatureFlagRepository` (única fronteira
com a tabela `feature_flags`), `FeatureFlagCache` (cache local em
memória, escopo de sessão), `FeatureFlagService` (orquestra
repositório+cache, nunca lança) e duas portas de entrada — a fachada
estática `AppFeatureFlags` (checagem imperativa em qualquer lugar) e
`featureFlagsControllerProvider` (Riverpod, para telas que precisam
reconstruir reativamente). Nova migration
(`20260725100000_create_feature_flags.sql`) cria a tabela com RLS
(leitura para qualquer autenticado; escrita só `super_admin`, mesmo
critério de `user_roles`), trigger de `updated_at` e GRANT concedido já
na mesma migration (lição da correção de GRANT da FASE 5/6). Populadas
as 8 flags mínimas exigidas (`maintenance_mode`, `new_feed`,
`new_ranking`, `new_profile`, `enable_notifications`, `enable_social`,
`enable_reviews`, `enable_admin`) como infraestrutura apenas — nenhuma
tela consulta nenhuma delas nesta rodada, nenhum comportamento
existente foi alterado. Estratégia offline: se o Supabase estiver
indisponível, o serviço nunca lança — `isEnabled()` cai num
`defaultValue` seguro (`false`) na primeira falha, ou preserva o último
cache válido numa falha de `refresh()` posterior; carregamento no
bootstrap (`main.dart`) é fire-and-forget, nunca bloqueia a subida do
app. Ver `RC-03D_FEATURE_FLAGS.md` para arquitetura completa, estratégia
offline e como adicionar novas flags. Suíte de unit/widget tests sem
regressão (376/376 — 24 testes novos).

**RC-03E (Feedback In-App) concluída em 2026-07-25** — infraestrutura
completa de envio de feedback do BORAH (`lib/core/feedback/`), seguindo
o mesmo padrão arquitetural de `CrashReporting`/`AppLogger`/
`AppAnalytics`/`AppFeatureFlags`: `FeedbackModel` (modelo),
`FeedbackRepository`/`SupabaseFeedbackRepository` (única fronteira com a
tabela `feedback`), `FeedbackService` (sanitiza a mensagem e propaga
falhas — ao contrário de Feature Flags, existe uma UI real aguardando o
resultado), `FeedbackController`/`feedbackControllerProvider` (Riverpod,
estados Initial/Submitting/SubmitSuccess/SubmitError) e a fachada
estática `AppFeedback`. Nova migration
(`20260725110000_create_feedback.sql`) cria a tabela com RLS (usuário lê
e insere apenas o próprio feedback; administrador lê todos, mesmo padrão
de `comment_reports`) e GRANT concedido já na mesma migration.
Diferente da RC-03A–D (infraestrutura pura), esta rodada entrega também
um diálogo de envio real (`FeedbackDialog`, Design System) com contador
de caracteres, estados de carregando/sucesso/erro e nova tentativa —
conectado a `SettingsPage` ("Enviar feedback"), única integração de UI
desta rodada. Privacidade reaproveita `pii_redaction.dart` (RC-03A/C):
a redação de telefone, até então privada em
`analytics_property_sanitizer.dart`, foi promovida a função
compartilhada (`redactPhoneNumbers`, opt-in, sem alterar o Sentry) e
`feedback_sanitizer.dart` a reaproveita junto com `redactSensitiveText`.
Decisão arquitetural registrada nesta rodada: a versão do app não é mais
lida via `PackageInfo.fromPlatform()` a cada envio — descobriu-se que
essa chamada nunca resolve dentro de um teste de widget (`testWidgets`),
travando `pumpAndSettle()`; a leitura foi movida para
`AppFeedback.initialize()` (chamado uma única vez em `main.dart`, mesmo
padrão de `AppAnalytics.initialize()`), cacheada em memória e reutilizada
por toda instância de `FeedbackService` — ver `RC-03E_IN_APP_FEEDBACK.md`
§7 para a análise completa. Ver `RC-03E_IN_APP_FEEDBACK.md` para
arquitetura completa, banco, RLS e como reutilizar. Suíte de unit/widget
tests sem regressão (400/400 — 24 testes novos).

Com a RC-03E, a RC-03 (Observability trio + flags + feedback) está
completa: RC-03A → RC-03B → RC-03C → RC-03D → RC-03E.

Executar QA-\* em sequência.

Cada documento deve incluir:

-   Testes unitários
-   Integração
-   Performance
-   Segurança
-   Regressão

Corrigir falhas antes do próximo QA.

------------------------------------------------------------------------

## Fase 7 --- Publicação

Executar PB-\*.

Inclui:

-   Android
-   iOS
-   Stores
-   CI/CD
-   Monitoramento

------------------------------------------------------------------------

## Fase 8 --- Marketing

Executar MK-\*.

Entregas:

-   Landing Page
-   Vídeos
-   Social
-   Paid Media
-   Influenciadores
-   PR

------------------------------------------------------------------------

# 5. Regras Operacionais

Antes de cada implementação o Claude Code deve:

1.  Ler toda a documentação relevante.
2.  Identificar dependências.
3.  Criar plano de execução.
4.  Implementar somente o escopo do documento atual.
5.  Executar lint.
6.  Executar testes.
7.  Atualizar README e documentação.
8.  Sugerir mensagem de commit.
9.  Aguardar aprovação.

------------------------------------------------------------------------

# 6. Marcos do Projeto

-   M1 --- Planejamento concluído
-   M2 --- Arquitetura aprovada
-   M3 --- MVP funcional
-   M4 --- Beta fechado
-   M5 --- Beta público
-   M6 --- Publicação nas lojas
-   M7 --- Lançamento oficial

------------------------------------------------------------------------

# 7. Critérios de Aceite

O roadmap é considerado atendido quando:

-   Todas as fases foram concluídas na ordem definida.
-   Não existem dependências pendentes.
-   Todas as aprovações foram registradas.
-   A documentação permanece sincronizada com o código.

------------------------------------------------------------------------

# 8. Próximo Documento

Após aprovação deste roadmap, iniciar:

**EX-03 --- Claude Code Operating Manual**
