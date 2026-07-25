# RC-04A — Security Hardening

**Data:** 2026-07-25
**Branch:** `feature/rc-04a-security-hardening`
**Status:** Concluída — auditoria completa executada; suíte de RLS entregue pronta para execução (não validada em ambiente real, ver §4); rotação da `SERVICE_ROLE_KEY` a cargo do operador (ver §7)
**Escopo:** exclusivamente o fortalecimento da segurança da aplicação existente. Storage, LGPD, Exclusão de Conta, Política de Privacidade, Termos de Uso, Keystore, Certificados e funcionalidades de Beta são itens separados do backlog (RC-04B/C/D/E) e não foram tocados nesta rodada.

---

## 1. Objetivo

Auditar toda a superfície de segurança do BORAH antes da preparação para produção: RLS, autenticação, sessões, permissões administrativas, permissões do Supabase e segredos — sem implementar nenhuma funcionalidade nova.

---

## 2. Metodologia

Auditoria estática (leitura completa de todas as 25 migrations, todo o código de autenticação/administração, workflows de CI/CD e documentação operacional existente), seguida de uma suíte de testes de segurança:

- **Testes de RLS cross-user**: pgTAP, entregues em `supabase/tests/database/`, prontos para rodar via `supabase start` + `supabase test db --local` (ver §4 — não executados nesta rodada, conforme decisão explícita registrada abaixo).
- **Testes de permissões administrativas do cliente**: Dart/`flutter test`, cobrindo `AdminGuard` (sem nenhuma cobertura antes desta rodada) e reforçando `current_user_role_provider_test.dart`/`admin_roles_controller_test.dart` já existentes.

**Decisão registrada explicitamente pelo usuário**: nem o Docker (necessário para `supabase start`) nem o Dashboard do Supabase (necessário para rotacionar a `SERVICE_ROLE_KEY`) estavam disponíveis/acessíveis nesta sessão de implementação. Em vez de simular ou pular esses itens, foi decidido:
1. Entregar a suíte de RLS completa, correta e pronta para execução, documentando claramente que **não foi validada contra uma instância real** (mesma ressalva já aplicada a toda migration do projeto desde o início, ver AR-06/EX-01B).
2. Documentar o procedimento completo de rotação da `SERVICE_ROLE_KEY`, a ser **executado pelo operador** (o usuário), não simulado nesta sessão.

---

## 3. RLS — Auditoria completa das 17 tabelas

Toda tabela de `public` foi revisada individualmente (RLS + GRANT correspondente). Nenhuma tabela concede privilégio além do que sua própria policy permite — auditoria linha a linha confirmou que todo `GRANT` (`20260720130000_grant_authenticated_privileges.sql` + os GRANTs inline de `feature_flags`/`feedback`) espelha exatamente os comandos com policy existente, sem exceção.

| Tabela | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `profiles` | qualquer autenticado (público, por design — DV-02) | próprio | próprio | não implementado |
| `restaurants` | qualquer autenticado (público) | próprio (`created_by`) | próprio OU `can_moderate()` | não implementado (sem GRANT) |
| `reviews` | qualquer autenticado (público) | próprio | próprio OU `can_moderate()` | não implementado (soft delete via UPDATE) |
| `review_likes` | qualquer autenticado (público) | próprio | não implementado | próprio |
| `favorites` | **só o próprio dono** (privado) | próprio | não implementado | próprio |
| `followers` | qualquer autenticado (público) | próprio (`follower_id`) | não implementado | próprio |
| `comments` | qualquer autenticado (público) | próprio | próprio OU `can_moderate()` (+ janela de 15min via trigger) | não implementado |
| `comment_reports` | próprio OU `is_admin()` | próprio | não implementado | não implementado (imutável) |
| `user_roles` | qualquer `is_admin()` (inclusive `support`) | só `super_admin` | só `super_admin` | só `super_admin` |
| `audit_logs` | qualquer `is_admin()` | próprio + `is_admin()` | **não implementado, nem para super_admin** (append-only) | **idem** |
| `notifications` | **só o próprio dono** | **não implementado para o cliente** (só trigger `SECURITY DEFINER`) | próprio (marcar como lida) | não implementado |
| `notification_preferences` | **só o próprio dono** | próprio | próprio | não implementado |
| `user_progress` | qualquer autenticado (público, ranking) | **não implementado para o cliente** (só função `SECURITY DEFINER`) | idem | não implementado |
| `badges` | qualquer autenticado (catálogo público) | não implementado (catálogo fixo) | não implementado | não implementado |
| `user_badges` | qualquer autenticado (público) | **não implementado para o cliente** (só função `SECURITY DEFINER`) | não implementado | não implementado |
| `feature_flags` | qualquer autenticado (público) | só `super_admin` | só `super_admin` | só `super_admin` |
| `feedback` | próprio OU `is_admin()` | próprio | não implementado | não implementado (sem GRANT) |

### 3.1 Funções auxiliares de RBAC

`is_admin(uid)` (qualquer papel), `has_admin_role(uid, role)` (papel exato) e `can_moderate(uid)` (`super_admin`/`admin`/`moderator`, exclui `support`) são todas `SECURITY DEFINER` com `search_path` travado (`public, pg_temp`) — correção já aplicada na `20260720130030_fix_rbac_functions_security_definer.sql`, confirmada nesta auditoria como correta e ainda em vigor. Sem `SECURITY DEFINER`, a própria policy de SELECT de `user_roles` causaria recursão infinita ao chamar essas funções (bug já documentado e corrigido antes desta rodada).

**Achado de consistência (baixa severidade, não é vulnerabilidade)**: as funções mais antigas com `SECURITY DEFINER` (`handle_new_user`, `create_notification`, `notify_new_*`, `award_badge`, `award_gamification_points`, `handle_gamification_new_*`) usam `set search_path = public` (sem `pg_temp`), enquanto as corrigidas posteriormente (`recalculate_restaurant_rating`, `recalculate_review_likes_count`, `is_admin`, `has_admin_role`, `can_moderate`) usam `set search_path = public, pg_temp` — o padrão oficialmente documentado pelo Postgres para funções `SECURITY DEFINER`. A ausência de `pg_temp` não é insegura (é, se algo, mais restritiva), mas fica registrada como item de consistência para uma limpeza futura, não corrigida nesta rodada por não representar risco e por "evitar mudanças desnecessárias".

### 3.2 Suíte de testes de RLS (pgTAP)

Três arquivos em `supabase/tests/database/`, cobrindo exatamente o pedido ("Usuário A × Usuário B... leitura negada, escrita negada, update negado, delete negado quando apropriado"):

| Arquivo | Cobertura | Asserções |
|---|---|---|
| `10_rls_private_tables.test.sql` | Tabelas privadas: `favorites`, `notifications`, `notification_preferences`, `comment_reports`, `feedback`, `user_roles` (visibilidade), `audit_logs` (visibilidade) — nega leitura/escrita cruzada de B sobre dado de A; confirma que A continua acessando o próprio dado normalmente (evita falso-positivo de bloqueio geral demais) | 24 |
| `20_rls_public_read_own_write.test.sql` | Tabelas de leitura pública: `profiles`, `restaurants`, `reviews`, `comments`, `followers`, `review_likes` — confirma que B **consegue ler** o dado de A (comportamento correto, por design) mas **não consegue escrever/apagar**; confirma que A continua editando/removendo o próprio dado | 23 |
| `30_rls_admin_permissions.test.sql` | `user_roles`/`feature_flags` (escrita exige `super_admin` exato — `admin` como representante do caso negativo), `audit_logs` (append-only inclusive para `super_admin`), `can_moderate()` (moderator modera conteúdo de terceiros; `support` não, apesar de ser administrador) | 26 |

**Como executar** (requer Docker rodando):
```bash
cd supabase
supabase start
supabase test db --local supabase/tests/database
```

**Status desta suíte**: escrita e revisada estaticamente, seguindo o padrão pgTAP oficial do Supabase (simulação de usuário via `set local role authenticated; set local request.jwt.claims to '{"sub":"<uuid>","role":"authenticated"}'`, a mesma implementação de `auth.uid()` usada pelo stack local do Supabase). **Não foi executada nem validada nesta sessão** — nem Docker nem um projeto Supabase real estavam acessíveis no ambiente de implementação (decisão explícita do usuário, ver §2). A parte de maior incerteza é a fixture de `auth.users` (a lista exata de colunas `NOT NULL` sem default pode variar entre versões do schema `auth`) — se a suíte falhar na etapa de fixture, ajustar as colunas do `insert into auth.users` conforme o erro reportado por `supabase test db`.

---

## 4. Autenticação — revisão completa

| Fluxo | Revisão |
|---|---|
| **Login** | `AuthRepositoryImpl.signIn` → `GoTrueClient.signInWithPassword`, exceções traduzidas para `AuthRepositoryException` sem vazar detalhes internos do Supabase. |
| **Logout** | `AuthController.signOut()` não expressa "tentando"/"falhou" via `AuthStatus` global (ver RC-02) — evita redirect indevido de rota protegida durante uma falha transitória; sessão permanece intacta em caso de erro. |
| **Refresh Token** | Sem configuração customizada — `Supabase.initialize()` usa os padrões do `supabase_flutter` (fluxo PKCE, `autoRefreshToken` habilitado). Nenhum código do app manipula o refresh token diretamente. |
| **Persistência de sessão** | Delegada inteiramente ao `supabase_flutter` (armazenamento local padrão do pacote) — `AuthController.restoreSession()` (chamado pela Splash) consulta `currentSession`/`onAuthStateChange`, nunca lê tokens diretamente. |
| **Sessão expirada/inválida** | `onAuthStateChange` emite `session: null` quando a sessão se torna inválida (refresh falhou, revogada, etc.) — `AuthController` reflete `Unauthenticated`, e o `redirect` do GoRouter (`app_router.dart`) já bloqueia qualquer rota protegida nesse estado, redirecionando para `/login` automaticamente. Nenhum código customizado necessário — a arquitetura reativa já existente cobre este caso corretamente. |
| **Usuário bloqueado** | **Não implementado.** Nenhuma coluna/flag de bloqueio existe em `profiles`/`auth.users` nem em nenhuma tabela do projeto (confirmado por busca no schema e no código) — o Supabase Auth suporta bloqueio via Admin API (`ban_duration`), mas nenhuma infraestrutura desse tipo existe hoje no BORAH. Registrado como gap para o backlog (§8), não implementado nesta rodada (construir esse fluxo exigiria infraestrutura privilegiada — Edge Function/Admin API — fora do escopo de "hardening" e das exclusões explícitas desta etapa). |
| **Administrador** | Nenhuma autorização administrativa depende de estado local do Flutter — toda decisão é validada pela RLS (ver §5). |

**Senha — achado registrado, não corrigido nesta rodada**: `validatePassword` (`core/validators/app_validators.dart`) exige apenas 6+ caracteres no cliente — validação puramente cosmética (UX), já que a política real de senha é imposta pelo próprio Supabase Auth (GoTrue), configurável via Dashboard → Authentication → Policies, fora deste repositório. Recomenda-se confirmar/reforçar essa política no Dashboard de cada ambiente (QA/Beta/Production) antes do lançamento — registrado como recomendação operacional no backlog (§8), não uma falha de código.

---

## 5. Permissões administrativas

Confirmado por leitura de código: **nenhuma autorização depende exclusivamente do cliente.**

- `AdminGuard` (`presentation/widgets/admin_guard.dart`) é **só apresentação** — mostra carregando/erro/"acesso restrito", nunca decide o que é permitido escrever. Antes desta rodada não tinha nenhum teste; agora coberto por `test/widget/administration/admin_guard_test.dart` (8 casos: carregando, erro, sem papel, cada um dos 4 papéis, sem usuário logado).
- `AdminRoleRepositoryImpl.grantRole`/`revokeRole` chamam `upsert`/`delete` diretamente na tabela `user_roles` sem nenhuma checagem de papel no Dart — o comentário do próprio `AdminRolesController` já registra isso explicitamente: *"autorizado pela RLS de `user_roles`, não verificado aqui"*. Uma tentativa sem permissão é rejeitada pelo Postgres (`42501`), nunca pelo cliente.
- Todas as 6 páginas administrativas (`admin_dashboard_page.dart`, `admin_restaurants_page.dart`, `admin_roles_page.dart`, `admin_users_page.dart`, `audit_log_page.dart`, `moderation_page.dart`) estão envolvidas em `AdminGuard` — nenhuma ficou desprotegida (confirmado por busca).
- `/admin` e `/admin/*` estão em `_protectedRoutePrefixes` do GoRouter (exige só `Authenticated`, qualquer usuário logado) — o gate de PAPEL específico é feito pelo `AdminGuard` dentro de cada página, não pelo router. Consistente com o comentário já existente em `app_router.dart` ("o redirect... nunca consulta o Supabase diretamente").

**Achado registrado, não corrigido nesta rodada** (backlog, §8): `AdminRolesPage` exibe os controles de "Conceder papel"/"Revogar" para **qualquer** administrador (inclusive `moderator`/`support`, que não têm permissão real de escrita em `user_roles`) — a RLS bloqueia corretamente a operação (`42501` para insert/update, 0 linhas afetadas para delete, ver §3.2), mas a UI não esconde os controles de antemão para quem certamente não tem permissão. Não é uma vulnerabilidade (o dado está protegido), é uma lacuna de UX — registrada como melhoria futura, não implementada aqui para "evitar mudanças desnecessárias" fora do escopo literal de hardening de segurança.

---

## 6. Segredos

| Item | Situação |
|---|---|
| `.env.development`/`.env.qa`/`.env.staging`/`.env.production` | Todos no `.gitignore`; confirmado por `git log --all` que nenhum jamais foi commitado, em nenhum momento do histórico. |
| `SUPABASE_URL`/`SUPABASE_ANON_KEY` | Públicas por design (a chave anônima é segura para embutir em um cliente — a RLS é quem protege os dados, não o segredo da chave). |
| `SERVICE_ROLE_KEY` | **Nunca** referenciada em `lib/` (confirmado por busca em todo o código-fonte do app) — usada exclusivamente por `integration_test/helpers/*.dart` (ferramenta de QA, não distribuída com o app), sempre lida via `--dart-define` em tempo de execução, nunca hardcoded. CI (`ci.yml`) a injeta via `secrets.SUPABASE_QA_SERVICE_ROLE_KEY`, escopada ao Environment `qa`. |
| Segredo hardcoded em código | Nenhum encontrado — busca por padrão de JWT (`eyJ...`) e pelos novos formatos (`sb_secret_...`/`sb_publishable_...`) em todo o repositório só retornou fixtures de teste (strings falsas usadas para testar a redação de PII) e documentação em prosa discutindo o formato, nunca um segredo real. |
| CI/CD | Segredos lidos exclusivamente via `secrets.*` do GitHub Actions, nunca impressos em log; job `integration_test` roda sob o Environment `qa` (permite exigir aprovação manual). |

### 7. Rotação da `SERVICE_ROLE_KEY` — pendência herdada, executada pelo operador

**Origem**: durante o provisionamento do ambiente `borah-qa` (QA-03, Rodada 0, 2026-07-22), a `service_role key` foi exposta por completo em texto no terminal (`supabase projects api-keys` sem `--reveal`) — usada e descartada na sessão, nunca persistida em nenhum arquivo do repositório, mas nunca rotacionada desde então (pendência registrada em `EX-10_FASE_6_QA_STATUS.md` e `docs/operations/CI_CD_SECRETS.md`).

**Decisão desta rodada**: a rotação exige acesso ao Supabase Dashboard (credenciais da conta do projeto) — fora do alcance de qualquer ferramenta disponível nesta sessão de implementação. **O usuário executará a rotação diretamente.** Esta seção documenta o procedimento completo para referência e para a atualização dos secrets dependentes.

#### Procedimento

1. **Dashboard → projeto `borah-qa` → Project Settings → API.**
2. Localizar a seção **Service Role Key** e clicar em **"Reset service_role key"** (ou equivalente na versão atual do Dashboard).
3. **Preferir o formato novo** (`sb_secret_...`) em vez do legado (JWT, `eyJ...`), conforme já recomendado em `docs/operations/CI_CD_SECRETS.md` §1.
4. Copiar a nova chave **sem exibi-la em nenhum terminal compartilhado** (evitar repetir o incidente original — usar apenas a própria interface do Dashboard ou um gerenciador de segredos).
5. Atualizar o secret **`SUPABASE_QA_SERVICE_ROLE_KEY`** no GitHub: **Settings → Environments → `qa` → Environment secrets** (não em "Repository secrets" — ver `CI_CD_SECRETS.md` §3.1).
6. Atualizar qualquer cópia local usada para rodar `integration_test/` manualmente (variável de ambiente/`--dart-define` do desenvolvedor) — **nunca** salvar em um arquivo versionado.
7. Confirmar que nenhum workflow do GitHub Actions está em execução no momento da troca (evitar um job em andamento falhar por usar a chave antiga no meio da execução).
8. Rodar manualmente o job `integration_test` do `ci.yml` uma vez (ex.: `workflow_dispatch` ou um push trivial) para confirmar que a nova chave funciona antes de considerar a rotação concluída.
9. Registrar a data da rotação nesta seção (atualizar esta linha após a execução): **Rotação executada em: _(pendente — a preencher pelo operador após a execução)_.**

**Após a rotação**: esta pendência (aberta desde 2026-07-22) pode ser considerada encerrada. Nenhuma ação adicional de código é necessária — o app nunca referenciou a `SERVICE_ROLE_KEY` diretamente (ver §6).

---

## 8. Backlog (fora do escopo desta rodada)

Itens identificados durante a auditoria, deliberadamente não implementados aqui (para não expandir o escopo além de "Security Hardening" literal, ou por dependerem de decisão/infraestrutura fora deste repositório):

1. **`AdminRolesPage`**: ocultar os controles de "Conceder papel"/"Revogar" para administradores que não são `super_admin` (hoje visíveis a todos, a operação real já é bloqueada pela RLS — puramente uma melhoria de UX, ver §5).
2. **Consistência de `search_path`** nas funções `SECURITY DEFINER` mais antigas (adicionar `pg_temp` por padronização, sem mudança de comportamento — ver §3.1).
3. **Política de senha no Supabase Dashboard**: confirmar/reforçar a política real de senha (GoTrue) em cada ambiente antes do lançamento — configuração operacional, não código (ver §4).
4. **Usuário bloqueado**: nenhuma infraestrutura existe hoje para banir/bloquear uma conta — exigiria Admin API/Edge Function (fora do escopo desta rodada, ver §4).
5. **Sessão em `flutter_secure_storage`**: o `supabase_flutter` persiste a sessão via seu armazenamento local padrão (comportamento padrão do SDK, não uma falha introduzida pelo projeto) — trocar por um `LocalStorage` customizado baseado em `flutter_secure_storage` é uma melhoria de defesa em profundidade possível para uma rodada futura, não uma vulnerabilidade corrigida aqui.

---

## 9. Testes

| Arquivo | Cobertura |
|---|---|
| `supabase/tests/database/10_rls_private_tables.test.sql` | 24 asserções — tabelas privadas, cross-user negado, acesso próprio confirmado |
| `supabase/tests/database/20_rls_public_read_own_write.test.sql` | 23 asserções — leitura pública confirmada, escrita cruzada negada, acesso próprio confirmado |
| `supabase/tests/database/30_rls_admin_permissions.test.sql` | 26 asserções — hierarquia de papéis, `user_roles`/`feature_flags`/`audit_logs`/`can_moderate()` |
| `test/widget/administration/admin_guard_test.dart` | 8 casos — carregando, erro, sem papel, 4 papéis administrativos, sem usuário logado |

**Suíte Dart completa** (`flutter analyze` + `dart format --set-exit-if-changed .` + `flutter test`): ver relatório final — zero regressão, todos os testes novos passando.

**Suíte SQL (pgTAP)**: entregue pronta para execução, **não executada nesta sessão** (ver §3.2 e a decisão registrada em §2) — exige `supabase start` (Docker) local antes de ser considerada validada.

---

## 10. Decisões arquiteturais registradas nesta rodada

1. **Não simular a rotação da `SERVICE_ROLE_KEY` nem a execução da suíte de RLS.** Ambas dependem de acesso externo (Dashboard do Supabase; Docker local) indisponível nesta sessão — decisão explícita do usuário foi entregar os artefatos prontos (procedimento documentado; suíte de testes) em vez de fingir uma validação que não ocorreu.
2. **Manter `search_path` inconsistente entre funções `SECURITY DEFINER`** (§3.1) sem alteração — não representa risco e alterar exigiria recriar 8 funções sem nenhum ganho de segurança real, contrariando "evitar mudanças desnecessárias".
3. **Não implementar bloqueio de usuário** nesta rodada — a infraestrutura necessária (Admin API/Edge Function) está fora do escopo de hardening da superfície existente; registrado como backlog.
4. **Não alterar `AdminRolesPage`** para esconder controles de escrita de não-`super_admin` — é uma melhoria de UX, não uma correção de segurança (a RLS já protege os dados); registrado como backlog para não expandir o escopo desta rodada.
