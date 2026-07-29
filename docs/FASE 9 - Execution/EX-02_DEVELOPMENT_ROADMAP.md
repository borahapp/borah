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

**FASE 11 iniciada em 2026-07-25.** **RC-04A (Security Hardening)
concluída** — auditoria completa da superfície de segurança do BORAH,
sem nenhuma funcionalidade nova (Storage/LGPD/Exclusão de Conta/
Termos/Keystore/Certificados/Beta ficam para RC-04B-E). Todas as 17
tabelas de `public` foram auditadas individualmente (RLS + GRANT
correspondente) — nenhuma concede privilégio além do que a própria
policy permite. Confirmado por leitura de código que nenhuma
autorização administrativa depende do cliente: `AdminGuard` é só
apresentação, toda concessão/revogação de papel e toda leitura
administrativa é decidida pela RLS (`is_admin`/`has_admin_role`/
`can_moderate`, todas `SECURITY DEFINER` desde a correção da FASE 5/6).
Entregue uma suíte pgTAP de RLS cross-user (`supabase/tests/database/`,
73 asserções em 3 arquivos: tabelas privadas, tabelas de leitura
pública/escrita própria, permissões administrativas) — escrita e
revisada estaticamente, **não executada nesta rodada** por decisão
explícita do usuário (Docker indisponível na sessão de implementação;
suíte pronta para rodar via `supabase start` + `supabase test db
--local` quando o ambiente estiver disponível). Auditoria de segredos
confirmou zero segredo versionado em toda a história do git e zero
referência à `SERVICE_ROLE_KEY` em `lib/` (usada só por
`integration_test/`, sempre via `--dart-define`). A rotação pendente da
`SERVICE_ROLE_KEY` do `borah-qa` (exposta em texto durante o
provisionamento, QA-03 Rodada 0) teve o procedimento completo
documentado em `RC-04A_SECURITY_HARDENING.md` §7, a ser **executada
pelo próprio operador** (fora do alcance de qualquer ferramenta
disponível nesta sessão). `AdminGuard` ganhou sua primeira suíte de
testes (8 casos, nunca coberto antes). Achados registrados como
backlog, não corrigidos nesta rodada (nenhum é uma vulnerabilidade
ativa): `AdminRolesPage` exibe controles de concessão/revogação a
qualquer administrador (a RLS já bloqueia a operação real); política de
senha do cliente é só cosmética (a real está no Supabase Dashboard);
"usuário bloqueado" não tem nenhuma infraestrutura ainda. Ver
`RC-04A_SECURITY_HARDENING.md` para a auditoria completa, tabela de RLS
por tabela e as decisões arquiteturais registradas. Suíte de unit/widget
tests sem regressão (408/408 — 8 testes novos).

**RC-04B (Storage & Upload Security) concluída em 2026-07-25** —
infraestrutura completa de armazenamento seguro do BORAH
(`lib/core/storage/`), seguindo o mesmo padrão arquitetural de
`CrashReporting`/`AppLogger`/`AppAnalytics`/`AppFeatureFlags`/
`AppFeedback`: `StorageException` (única exceção da camada),
`StorageRepository`/`SupabaseStorageService` (única fronteira com o SDK
de Storage), `StorageService` (valida tamanho/MIME/extensão, gera nomes
seguros, nunca reaproveita o nome enviado pelo usuário), providers
Riverpod e a fachada estática `AppStorage`. Achado de arquitetura
registrado no início da rodada: 3 datasources de feature já acessavam o
Storage diretamente (`UserRemoteDatasource`/`RestaurantRemoteDatasource`/
`ReviewRemoteDatasource`) — mantidos intocados por instrução explícita
("não implementar upload em telas específicas nesta etapa"), migração
registrada como backlog. Nova migration
(`20260725120000_create_storage_buckets.sql`) cria os 3 buckets
efetivamente usados pelo código existente (`avatars` privado 5MB,
`restaurants` público 10MB, `review-photos` público 10MB — nome
padronizado nesta rodada em vez do genérico `reviews` inicialmente
sugerido, para casar com o código já existente), com limite de
tamanho/MIME aplicado já no próprio bucket (camada redundante à
validação do cliente) e RLS completa: leitura pública/qualquer
autenticado conforme o caso, escrita restrita ao dono ou a
administrador/moderador (`can_moderate()`, mesmo critério da RC-04A).
Geração de nome via timestamp + sufixo aleatório (`Random.secure()`,
sem nova dependência) — nunca o nome original, evitando path
traversal/sobrescrita acidental. Suíte pgTAP de RLS de Storage entregue
(`supabase/tests/database/40_rls_storage.test.sql`, 18 asserções),
escrita e revisada estaticamente, **não executada nesta rodada** pela
mesma limitação de ambiente já registrada na RC-04A (sem Docker local
disponível). Ver `RC-04B_STORAGE_SECURITY.md` para arquitetura
completa, buckets, políticas e decisões arquiteturais. Suíte de
unit/widget tests sem regressão (444/444 — 36 testes novos).

**RC-04B1 (Storage Hardening) concluída em 2026-07-25** — rodada de
hardening (não uma nova RC) para eliminar as 5 ressalvas de uma
auditoria técnica independente sobre a RC-04B. Removido código morto
(`StorageRepository.update()`/`SupabaseStorageService.update()`, zero
consumidores confirmados). Adicionada observabilidade a
`StorageService.replace()` via `AppLogger.warning` para o cleanup
best-effort do arquivo antigo (primeira chamada real a `AppLogger` em
código de feature/`core` do projeto). Nova migration
(`20260725130000_reconcile_storage_bucket_limits.sql`) reconcilia
`file_size_limit`/`allowed_mime_types` dos 3 buckets sem editar a
migration original (disciplina do projeto) e sem nunca tocar a coluna
`public` (mudança de público/privado exige sua própria migration,
nunca um efeito colateral). Investigação confirmou, com fontes do
próprio repositório `supabase/storage` (issues #576 e #639, fechadas
como "not planned"), que o Supabase Storage valida `allowed_mime_types`
só pelo Content-Type declarado pelo cliente, nunca pelo conteúdo real —
corrigido com uma checagem de assinatura binária (magic bytes) para
JPEG/PNG/WebP em `StorageService`, sem dependência nova, documentada
com o limite honesto de que não substitui validação de servidor.
Suítes pgTAP (RC-04A e RC-04B) permanecem não executadas — Docker
indisponível nesta sessão, bloqueio documentado, não simulado. Ver
`RC-04B_STORAGE_SECURITY.md` §14 para a análise completa dos 5 itens.
Suíte de unit/widget tests sem regressão (459/459 — 15 testes novos).

**RC-04C (LGPD & Account Deletion) concluída em 2026-07-25** — ciclo
completo de exclusão de conta (RN-003/ET-04; PB-04 §7/§10). Interrompida
duas vezes antes de qualquer código, conforme instruído: (1) nenhum
método client-side do Supabase apaga a própria linha de `auth.users`
(`deleteUser()` só existe em `auth.admin`, exige `SERVICE_ROLE_KEY`) —
resolvido com uma função Postgres `SECURITY DEFINER`
(`public.delete_own_account()`, RPC travada em `auth.uid()`); (2)
auditoria de todas as referências a `auth.users` encontrou 5 relações
(`reviews.user_id`, `comments.user_id`, `comment_reports.reported_by`,
`audit_logs.actor_id`, `restaurants.created_by`) que bloqueiam a
exclusão de qualquer usuário que já escreveu conteúdo — resolvido, por
decisão aprovada explicitamente, reatribuindo esse conteúdo a uma conta
de sistema fixa "Usuário removido" em vez de apagá-lo (preserva
interações de outros usuários); consequência mecânica necessária
encontrada durante o desenho: duas constraints `UNIQUE`
(`reviews`/`comment_reports`) trocadas por índices únicos parciais para
não colidir na reatribuição em massa. Fluxo completo implementado:
confirmação explícita → reautenticação (senha) → limpeza do avatar no
Storage (best-effort) → exclusão via RPC → logout local (best-effort) →
retorno ao Login. Camadas Presentation → Application → Repository →
Supabase, mesmo padrão de `AuthController`/`UserProfileController`
(sem uma camada de Service própria, diferente de `core/`). Conectado à
`SettingsPage` ("Excluir conta"). Ver
`RC-04C_LGPD_ACCOUNT_DELETION.md` para a auditoria completa de dados,
decisões e limitações. Suíte de unit/widget tests sem regressão
(479/479 — 20 testes novos).

**RC-04D (Release Readiness & Store Preparation) concluída em
2026-07-26** — preparativos técnicos para publicação, sem publicar,
sem criar release e sem alterar regras de negócio. Auditoria inicial
completa (versão, IDs, permissões, assinatura, ambientes, dependências,
TODOs/prints/asserts, observabilidade em Release) encontrou: nome do
app ainda como placeholder "App" (corrigido para "BORAH" em ambas as
plataformas); zero permissões declaradas (adicionada só `INTERNET` no
Android e `NSPhotoLibraryUsageDescription` no iOS — únicas realmente
usadas, câmera/localização/notificações confirmadas não utilizadas em
todo o código); `release` do Android ainda assinado com a chave de
debug (já registrado desde o QA-03); ícone/splash ainda são o padrão
do template Flutter, sem nenhum asset de logo BORAH no repositório.
Decisões que exigiam segredos/ativos do responsável pela publicação
foram resolvidas via `AskUserQuestion` (preparar infraestrutura sem
gerar segredo/arte, em ambos os casos): `build.gradle.kts` passou a
ler uma keystore real de `android/key.properties` (nunca versionado)
quando presente, com fallback para debug signing na ausência —
procedimento de geração documentado em `CI_CD_SECRETS.md` §2, nenhuma
chave gerada nesta rodada; `minifyEnabled`/`shrinkResources`/ProGuard
habilitados (não validados com build real — sem SDK Android completo
nesta sessão); `flutter_launcher_icons`/`flutter_native_splash`
adicionados como dev-dependencies com configuração pronta apontando
para um asset ainda inexistente, para gerar ícone/splash assim que o
design fornecer o logo. Ver `RC-04D_RELEASE_READINESS.md` para o
checklist completo de release e as pendências restantes antes da
publicação (keystore real, Apple Developer Team, asset de logo,
validação de build real). Suíte de unit/widget tests sem regressão
(479/479 — nenhum teste novo, rodada tocou apenas configuração de
build/manifesto/plist e documentação).

**RC-04E (Closed Beta Preparation) concluída em 2026-07-26** — auditoria
completa de UX/estabilidade/navegação pensando exclusivamente no Beta
Fechado, com dois achados arquiteturais interrompidos e resolvidos por
decisão explícita do usuário antes de qualquer implementação: (1)
`/home` era um placeholder de desenvolvedor (`_BootstrapPlaceholderPage`)
— substituído por `RestaurantsSearchPage` (não o Feed, que mostraria
estado vazio para testers sem seguidores) dentro de um novo
`HomeShellPage`, que finalmente conecta o `AppBottomNavigation` (já
implementado desde o UI-02, nunca usado) às abas
Restaurantes/Feed/Favoritos/Perfil — consequência mecânica encontrada
durante a implementação (remover o placeholder deixava 7 telas prontas
sem nenhum caminho de navegação) resolvida com o mesmo componente,
também por decisão explícita; (2) recuperação de senha era um beco sem
saída completo (sem `redirectTo`, sem rota de callback, sem tela de
nova senha, sem deep link) — completado de ponta a ponta: evento
`passwordRecovery` do Supabase tratado como estado próprio
(`PasswordRecoveryInProgress`, distinto de um login normal), deep link
`borah://password-recovery` configurado em Android/iOS, nova tela
`NewPasswordPage`, erros do stream de sessão agora tratados (antes
descartados silenciosamente por `whenData`). Criado também um tradutor
centralizado de mensagens de erro do Supabase
(`SupabaseErrorTranslator`), aplicado obrigatoriamente em
login/cadastro/recuperação-redefinição de senha/exclusão de conta
(demais ~8 repositórios documentados como backlog priorizado, não
expandidos nesta rodada, por decisão explícita de escopo). Melhorias
mecânicas de qualidade sem decisão de negócio: `ErrorState` com retry
conectado em 19 telas que ainda mostravam erro sem nenhuma ação;
`ConfirmationDialog` conectado em "Excluir avaliação"/"Excluir
comentário" (disparavam direto antes); denúncia de comentário com
validação de motivo vazio e feedback de sucesso; upload de capa de
restaurante com loading inline (regressão vs. o padrão já usado para
fotos de avaliação); seleção de imagem com tratamento de falha de
plataforma; `ProfileAvatar` sem mais recriar a URL assinada a cada
rebuild; `ErrorWidget.builder` customizado; `locale` pt_BR explícito
(`flutter_localizations`, pacote do próprio SDK do Flutter). Ver
`RC-04E_CLOSED_BETA.md` para a auditoria completa, o backlog detalhado
(paginação nunca acionada em rankings/notificações, assimetria de
denúncia entre avaliações e comentários, tradução de erros incompleta)
e a recomendação final: **pronto para Beta Fechado, com ressalvas
documentadas que não bloqueiam um grupo pequeno e controlado de
testadores**. Suíte de unit/widget tests sem regressão (503/503 — 24
testes novos).

**Product Readiness Review e BETA-01/BETA-02 (planejamento estratégico,
2026-07-26)** — revisão executiva completa do produto (sem código) e
plano operacional do Beta Fechado, entregues como artefatos fora do
repositório, a pedido explícito. Aprovado o início da fase operacional
pré-Beta com a integração da identidade visual oficial como primeira
etapa.

**IV-01 a IV-05 (Integração da Identidade Visual Oficial) concluída em
2026-07-26** — substituição da identidade provisória pela identidade
oficial (`identidade visual-borah/BORAH_Pacote_Implementacao_Claude`,
única fonte de verdade), em 5 fases validadas sequencialmente: IV-01
(assets oficiais copiados para `assets/borah/`, dependência nova
`flutter_svg` aprovada explicitamente e documentada), IV-02 (ícone do
launcher substituído em Android/iOS via `flutter_launcher_icons` a
partir da matriz oficial 1024px), IV-03 (splash nativo substituído em
Android/iOS via `flutter_native_splash`, símbolo oficial sobre fundo
branco), IV-04 (logo oficial em `LoginPage`, substituindo o texto
"BORAH" estilizado — usada a versão branca monocromática, não a
colorida "dark"/"light", por perda de contraste contra o gradiente
roxo já usado no cabeçalho, decisão registrada e justificada), IV-05
(gradiente roxo reconciliado com o valor exato do manifesto oficial,
substituindo o valor de 2 tons obtido por amostragem de pixel na FASE
7A/UI-01). Cores e tipografia já estavam corretas desde a FASE 7A,
confirmado na auditoria prévia. IV-06 a IV-09 (símbolo/expressões em
estados vazios, ranking/gamificação, validação Dark Mode, assets de
loja) explicitamente fora de escopo desta rodada. Ver
`IV-01_A_05_BRAND_IDENTITY_INTEGRATION.md` para o detalhamento
completo. Suíte de unit/widget tests sem regressão (503/503 — mesma
contagem da RC-04E, testes existentes atualizados, nenhum novo
necessário).

**IV-06 a IV-09 (Conclusão da Identidade Visual Oficial) concluída em
2026-07-26** — medalhas oficiais (`medal_1/2/3.svg`) aplicadas ao pódio
do `RankingCard`, compartilhado pelas telas de Ranking de restaurantes
e de usuários; expressões oficiais do símbolo (`symbol_smiling`,
`symbol_surprised`) aplicadas em `EmptyState` (14 telas) e `ErrorState`
(19 telas). **Achado crítico durante a implementação**: os 4 SVGs de
expressão continham um elemento `<svg>` aninhado (técnica de
crop/transform da ferramenta de exportação) incompatível com o
compilador do `flutter_svg` 2.x, fazendo a ilustração renderizar em
branco sem nenhum erro em rede/console/testes de widget — só detectado
por verificação visual real (`flutter build web` + preview em
navegador, na ausência de emulador Android). Corrigido achatando o
`<svg>` aninhado em um `<g transform>` matematicamente equivalente,
apenas nas cópias de execução do projeto — os arquivos-fonte do pacote
oficial permanecem intocados, conforme a própria regra do material
("não modificar os originais; documentar a derivação"). Padronização de
gamificação/rankings (IV-07) confirmada sem inconsistências adicionais
a corrigir. Auditoria de Dark Mode (IV-08) validou visualmente Login e
o novo `ErrorState` (rota 404) em Light/Dark — demais telas autenticadas
ficam pendentes de verificação por falta de emulador/backend de teste
neste ambiente. Preparação de assets de loja (IV-09): ícone Google Play
512px, já pronto no pacote oficial, copiado ao projeto pela primeira
vez; screenshots e feature graphic seguem ausentes no próprio pacote
oficial (documentado, nenhuma arte nova criada). Diversos assets
decorativos e selos de grupo/destaque foram deliberadamente **não**
aplicados por falta de um ponto de uso real na tela ou de dado que os
justifique (ex.: ausência de entidade "Grupo" no modelo de dados,
já registrada desde a RC-04E) — cada caso com a razão documentada em
`IV-06_A_09_BRAND_IDENTITY_COMPLETION.md`. Com isso, a Etapa 1
("Finalizar a identidade visual") do roadmap operacional pré-Beta está
concluída. Suíte de unit/widget tests sem regressão (503/503).

**BETA-03 (Configuração do Ambiente de Produção e Preparação das
Lojas) concluída em 2026-07-26** — auditoria completa (Android/iOS
release, assinatura, `DEVELOPMENT_TEAM`, Google Play, TestFlight,
redirect URLs, Supabase de Produção, variáveis de ambiente, CI/CD,
bundle IDs, keystore, certificados) seguida de gap analysis e
implementação restrita ao que não depende de contas externas nem de
segredos reais: `release.yml` passou a decodificar a keystore Android
condicionalmente (secret ausente → mesmo comportamento de antes,
assinatura de debug), injetar `--dart-define` de Produção nas builds
Android (vazio até os secrets existirem, sem regressão) e ganhou um
novo job `build_release_ios` (`macos-latest`, `--no-codesign`) como
portão de qualidade equivalente ao Android, sem gerar IPA assinado.
`CI_CD_SECRETS.md` documentado com os novos secrets de Produção e o
Environment `production` recomendado. Achado crítico registrado sem
tentar contornar: **nenhuma Política de Privacidade ou Termos de Uso
existe** — bloqueador direto de submissão nas duas lojas, decisão de
conteúdo jurídico do proprietário, não implementado nesta rodada.
Checklist operacional completo entregue em
`BETA-03_PRODUCTION_STORE_PREPARATION.md`, incluindo inventário de
dados coletados (Data Safety/App Privacy) já pronto para preenchimento
nos consoles. Suíte de unit/widget tests sem regressão (503/503) — só
workflows/documentação alterados, nenhum código de app.

**BETA-04 (Plano Operacional de Provisionamento) concluída em
2026-07-27** — auditoria dos 22+ itens externos necessários para
publicação (Google Play, Apple Developer, App Store Connect,
TestFlight, Supabase/Sentry/PostHog de Produção, GitHub Secrets,
keystore, certificados, provisioning profiles, bundle IDs, redirect
URLs, OAuth, política de privacidade, termos de uso, página/e-mail de
suporte, ícones, feature graphic, screenshots, classificação
indicativa, Data Safety/App Privacy), com ordem recomendada de
execução, tempo estimado, custo e responsável por item. Verificação de
políticas atuais das lojas (não assumidas de memória) revelou um risco
de cronograma relevante: contas pessoais do Google Play criadas após
13/11/2023 exigem um ciclo de Closed Testing com 12 testadores por 14
dias corridos antes do acesso à Produção (não bloqueia o Internal
Testing da Etapa 3B, mas atrasa qualquer plano de Produção depois);
Apple Developer Program como Organização exige D-U-N-S Number e leva
1–2 semanas, contra 24–48h para conta Individual — decisão registrada
como pendente do proprietário, não resolvida nesta rodada. Documento
único (`BETA-04_PROVISIONING_OPERATIONAL_PLAN.md`) com checklist final
de autorização para a Etapa 3B. Nenhum código, workflow ou secret
alterado — commit de documentação direto em `develop`, sem feature
branch, conforme protocolo desta rodada.

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
