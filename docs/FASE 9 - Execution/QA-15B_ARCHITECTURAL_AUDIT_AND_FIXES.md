# QA-15B — Auditoria Arquitetural Completa + Correções (2026-08-01)

**Papel:** QA Lead / Staff Software Engineer / Arquiteto de Software.
**Branch:** `claude/turnstile-secret-diagnosis-0g0p82`.
**Escopo:** nova rodada de auditoria arquitetural do BORAH (app Flutter, 312
arquivos/~22k linhas em `app/lib`, e backend Supabase, 46 migrations),
desta vez com mandato de **corrigir** os problemas reais encontrados, não
só documentá-los — complementa QA-15 (rodada anterior, só auditoria).

Método: revisão direta de código + 3 auditorias especializadas em paralelo
(dead code em `core/`/`design_system/`; segurança e RLS em todo o
`supabase/`; lifecycle de providers Riverpod e consistência de padrões em
`features/`), cada achado confirmado por evidência de arquivo:linha antes
de entrar nesta lista. Toda correção foi validada com `flutter analyze`
(0 issues), `dart format --set-exit-if-changed .` (0 arquivos alterados) e
`flutter test` (574/574) rodando de verdade nesta sessão (Flutter 3.44.6,
mesma versão fixada em `.fvm/fvm_config.json` e usada pela CI). A correção
de RLS foi validada isoladamente contra Postgres 16 real (ver §2.1).

---

## 1. Resumo executivo

| Categoria | Resultado |
|---|---|
| Vulnerabilidade real de RLS corrigida | **1** (Alta severidade) |
| Bugs de código corrigidos | **2** (1 observabilidade, 1 lint introduzido pela própria correção de formatação) |
| Débito de dead code removido | **9 arquivos** (6 widgets + 1 token + 2 cadeias de providers Riverpod) |
| Débito de formatação (`dart format`) corrigido | **18 arquivos** já fora do padrão antes desta rodada — quebraria a CI hoje |
| Achado de severidade Média, não corrigido (motivo documentado) | **1** (funções `SECURITY DEFINER` de leitura sem `REVOKE`/`GRANT` explícito) |
| `flutter analyze` | 0 issues (antes e depois) |
| `flutter test` | 574/574 (era 583 — 9 testes removidos junto com o dead code que testavam) |
| Migrations | 46 (45 + 1 nova desta rodada) |

O achado mais importante desta rodada é de **segurança**: a policy de
UPDATE de `event_attendances` permitia a um usuário sequestrar a própria
linha de presença para apontar para o evento de **qualquer outro grupo**
e, a partir daí, inserir uma avaliação coletiva fabricada nesse grupo
alheio — quebra direta do modelo de "grupo fechado". Corrigido nesta
rodada (§2.1), sem alterar nenhum comportamento hoje exercitado pelo app.

---

## 2. Correções aplicadas

### 2.1 [Segurança/Alta] `event_attendances` permitia sequestrar a própria presença para outro grupo

**Achado:** a policy `event_attendances_update_own`
(`20260731092000_create_events_and_attendances.sql`, endurecida em
`20260801140000_restrict_attendance_update_to_scheduled_events.sql`) só
verificava `auth.uid() = user_id` — nunca que `event_id` permanecesse o
mesmo. Como a condição extra ("evento ainda `scheduled`") é avaliada
contra o **novo** `event_id` da linha, um usuário autenticado podia
executar:

```sql
update event_attendances
set event_id = '<evento-de-outro-grupo>', status = 'confirmed'
where id = '<minha-propria-linha>';
```

passando as duas checagens (a linha continua sendo dele; o evento alvo
está `scheduled`), sem nunca ter sido membro do grupo alvo. Essa presença
"confirmed" fabricada satisfaz `can_review_event()` (BLOCO 4 — só olha
`status`/`scheduled_at`/`scheduled`, nunca membership), abrindo caminho
para inserir uma avaliação real em `event_reviews` visível aos membros
verdadeiros do grupo alheio e capaz de distorcer
`events.average_rating`/`total_reviews`.

**Correção:** `supabase/migrations/20260801150000_lock_event_attendance_identity_columns.sql`
— trigger `BEFORE UPDATE` que bloqueia qualquer alteração de `event_id`
ou `user_id` na própria linha (`prevent_event_attendance_reassignment`).
RLS não permite comparar OLD/NEW da mesma coluna dentro de uma única
`with check`, por isso a correção é via trigger, não via policy.

**Por que não altera comportamento:** `EventRemoteDatasource.
updateAttendanceStatus` — a única chamada de UPDATE em
`event_attendances` em todo o app — envia sempre e só `{'status':
status}` (`event_remote_datasource.dart:96-101`). A trigger só rejeita
alterações que o app nunca faz.

**Validação:** migration testada isoladamente contra Postgres 16 real
(cluster local desta sessão, schema minimalista reproduzindo `events`/
`event_attendances`): (1) UPDATE só de `status` — passa, idêntico ao
comportamento anterior; (2) UPDATE trocando `event_id` para o evento de
outro grupo — bloqueado pela trigger com a mensagem de erro esperada.
Os dois cenários confirmados via script SQL, não apenas leitura estática.

### 2.2 [Observabilidade] Falha ao encerrar sessão local após excluir conta era engolida em silêncio

**Achado:** `account_deletion_controller.dart:93-99` — `catch (_) {}` vazio,
sem log, ao contrário do bloco de limpeza do Storage 30 linhas acima no
mesmo arquivo (também best-effort, mas com `AppLogger.warning(...)`). Se
o `signOut()` local falhar depois que a conta já foi excluída no
servidor, nenhum sinal de telemetria indicava um dispositivo preso numa
sessão local obsoleta.

**Correção:** adicionado `AppLogger.warning(...)` no mesmo padrão do
bloco de limpeza do Storage. Comportamento inalterado — a falha continua
sendo best-effort e não bloqueia a tela de sucesso; só passou a ser
observável.

### 2.3 [Formatação] 18 arquivos fora do padrão do `dart format` da própria CI

**Achado:** `dart format --set-exit-if-changed .` — exatamente o comando
que `ci.yml`/`release.yml` executam antes de `flutter analyze` —
reformatou 18 arquivos preexistentes (nenhum deles tocado por nenhuma
rodada de QA anterior desta sessão) usando a mesma versão do Dart SDK
fixada em `.fvm/fvm_config.json` (3.44.6, a mesma que a CI usa via
`flutter-version-file`). Ou seja: **a CI falharia hoje**, antes mesmo do
`flutter analyze`, num branch que os relatórios anteriores descreviam
como "0 issues, pronto para abrir PR".

**Correção:** todos os 18 arquivos reformatados nesta rodada
(`dart format .`, sem `--output=none`). Mudança puramente sintática —
quebra de linha/trailing comma — o formatter nunca altera semântica.
`dart format --set-exit-if-changed .` roda limpo (0 arquivos) após a
correção.

### 2.4 [Lint] Formatação introduziu uma violação de `curly_braces_in_flow_control_structures`

**Achado:** ao reformatar `group_detail_page.dart`, o novo quebra-de-linha
do `if (value == 'stats') context.push(...)` (linha 148-149) passou a
violar o lint que exige chaves quando o corpo do `if` fica em linha
própria — os três `if` vizinhos no mesmo `onSelected` já usavam chaves;
só este ficou inconsistente.

**Correção:** chaves adicionadas, igualando ao padrão dos `if` vizinhos.
`flutter analyze` voltou a 0 issues.

### 2.5 [Dead code] 6 widgets + 1 token do design system sem nenhum uso em tela

Confirmado por grep exaustivo no repo inteiro (produção + testes): nenhum
dos itens abaixo tinha uma única referência fora de sua própria definição
e do barrel file.

| Item | Arquivo removido |
|---|---|
| `AppSecondaryButton` | `design_system/components/buttons/app_secondary_button.dart` |
| `AppFab` | `design_system/components/buttons/app_fab.dart` |
| `SkeletonLoader` | `design_system/components/feedback/skeleton_loader.dart` |
| `AppBottomSheet` | `design_system/components/bottom_sheets/app_bottom_sheet.dart` |
| `AppChip` | `design_system/components/feedback/app_chip.dart` |
| `ReviewCard` | `design_system/components/cards/review_card.dart` |
| `AppShadows` (token) | `design_system/tokens/app_shadows.dart` |

Exports correspondentes removidos de `components/components.dart` e
`design_system/design_system.dart`. Comentários que citavam esses nomes
(`app_card.dart`, `app_elevation.dart`, `core/theme/app_theme.dart`)
atualizados para não referenciar código que não existe mais.
`_chipTheme`/`ChipThemeData` em `app_theme.dart` **não** foram removidos:
continuam ativamente conectados a `ThemeData.chipTheme` (afetam qualquer
`Chip` nativo do Material que venha a aparecer via widget de terceiros) —
não são "dead code" no mesmo sentido, são configuração de tema sempre
ativa.

### 2.6 [Dead code] 2 cadeias inteiras de infraestrutura Riverpod nunca conectadas a nenhuma tela

`core/feature_flags/feature_flag_providers.dart` e
`core/storage/storage_providers.dart` — cada um expunha uma via
Riverpod-based alternativa às fachadas estáticas `AppFeatureFlags`/
`AppStorage`, que são as que o app realmente usa em produção
(`main.dart:40`, `account_deletion_controller.dart:62`, etc.). Confirmado
que **nenhum outro arquivo** (produção ou teste, fora dos dois arquivos
de teste dedicados a eles) referenciava esses providers. As classes que
eles envolvem (`FeatureFlagService`, `FeatureFlagCache`,
`SupabaseFeatureFlagRepository`, `StorageService`,
`SupabaseStorageService`) **não** foram tocadas — são consumidas de
verdade pelas fachadas estáticas.

Removidos junto: `test/unit/core/feature_flags/feature_flag_providers_test.dart`
e `test/unit/core/storage/storage_providers_test.dart` (só testavam o
código removido; os testes das fachadas estáticas e dos serviços
continuam intactos).

---

## 3. Achado real, não corrigido nesta rodada (motivo documentado)

### 3.1 [Médio, precisa de verificação no projeto real] Funções `SECURITY DEFINER` de leitura sem `GRANT`/`REVOKE` explícito

`is_group_member`, `is_group_admin`, `is_group_owner`,
`is_event_group_member`, `can_review_event`, `is_admin`,
`has_admin_role`, `can_moderate` — todas `SECURITY DEFINER`, usadas
dentro de policies RLS, **sem** `REVOKE EXECUTE FROM PUBLIC` explícito
(ao contrário de `create_group`/`join_group_by_invite_code`/
`regenerate_group_invite_code`/`create_event`/`delete_own_account`, que
revogam explicitamente). Como recebem `uid`/`gid`/`eid` como parâmetros
explícitos (não implícitos via `auth.uid()`), se forem alcançáveis
como RPC direto por `authenticated`, um usuário poderia sondar pares
arbitrários `(uid, gid)` para descobrir se outra pessoa é membro de um
grupo fechado sem nunca ter sido membro — um oráculo de 1 bit que
contorna o modelo de "grupo fechado".

**Por que não foi corrigido automaticamente:** a correção correta
(mover essas funções para um schema não exposto pela API, ex. `private.*`,
via `ALTER FUNCTION ... SET SCHEMA`) preserva o `OID` da função e por
isso não quebra as policies existentes — mas **exige** revogar/conceder
`EXECUTE` com precisão cirúrgica: qualquer engano bloqueia `authenticated`
de usar a própria função dentro da RLS (toda invocação de função dentro
de uma expressão de policy exige `EXECUTE` do papel que está consultando,
mesmo sendo `SECURITY DEFINER` — isso só afeta o contexto de execução
*dentro* da função, não a autorização para chamá-la). Esse é exatamente
o tipo de mudança que **não** pode ser validada com confiança nesta
sessão: não há um projeto Supabase real disponível para confirmar
empiricamente o comportamento efetivo de `GRANT`/`REVOKE` em funções
(o próprio `config.toml` documenta que o "novo default de nuvem" já
revoga automaticamente acesso de API a objetos novos sem `GRANT`
explícito — o que, se verdade também para funções, já mitigaria o risco
sem nenhuma mudança de código; mas isso nunca foi validado contra uma
instância real neste projeto, só documentado como suposição). Uma
correção malfeita aqui quebraria toda consulta a `groups`/`events` para
todo usuário autenticado — risco desproporcional ao benefício de uma
correção "às cegas".

**Recomendação:** antes do Beta, rodar contra o projeto Supabase real
(`\df+ is_group_member` ou uma chamada `rpc('is_group_member', {...})`
autenticada de fora do time) para confirmar se essas funções são de
fato alcançáveis via API. Se forem, aplicar `ALTER FUNCTION ... SET
SCHEMA private` com testes de regressão completos antes de mesclar.

---

## 4. Confirmações desta rodada (sem achado novo)

- **Nenhum outro provider "global" (sem parâmetro) carrega dado
  por-usuário fora dos 7 já invalidados no sign-out**
  (`app_router.dart:117-125`) — mapeados todos os ~63 providers do app;
  os únicos não-invalidados são "de detalhe" (grupo/evento/avaliação/
  restaurante específico por id), que exigem navegação até um item que só
  existiria na sessão anterior — mesmo risco já classificado como
  aceitável na rodada QA-14.
- **Nenhum vazamento de recurso** (`Timer`/`Stream.periodic`/subscrição
  não descartada) em `application/`/`data/`.
- **13 de 15 controllers amostrados** seguem o mesmo padrão de erro
  (exceção tipada → estado de erro dedicado; genérica → mensagem
  localizada). O único desvio real (`account_deletion_controller.dart`)
  foi corrigido em §2.2; o outro desvio (`feature_flag_providers.dart`)
  desapareceu junto com a remoção do arquivo em §2.6.
- **`GroupStatsPage` de fato reconsulta dados que telas irmãs já
  carregaram segundos antes** (`eventsListControllerProvider`/
  `groupRankingControllerProvider`, ambos providers globais sem chave por
  `groupId` no estado) — confirmado, mas não corrigido: os dois
  controllers não guardam qual `groupId` está carregado no estado atual,
  então uma guarda "não recarregar se já carregado" exigiria adicionar
  esse campo ao estado em dois controllers compartilhados por outras
  telas — risco real de exibir dados do grupo errado ao navegar entre
  dois grupos diferentes em sequência, para economizar uma consulta que
  já é rápida. Mantido como débito de performance de baixa severidade,
  mesma decisão já registrada na rodada anterior.
- **`regenerate_group_invite_code`** confirmado órfão (zero chamadas em
  `app/lib`) — a própria função é segura (verifica `is_group_owner`
  internamente), só não tem UI. Gap de produto, não bug.
- **Nenhum segredo hardcoded** em nenhum lugar do repositório
  (`.env.example` só tem placeholders vazios; `SUPABASE_QA_SERVICE_ROLE_KEY`
  só existe via `--dart-define` em `integration_test/`, nunca em `app/lib`,
  sempre lida de secret do GitHub Environment `qa`, nunca logada).
- **Turnstile** (`supabase/functions/website-form-submit`): secret lido
  via `Deno.env.get`, falha fechado se ausente, nunca ecoado/logado — nada
  a corrigir.
- **RLS cobre 100% das tabelas consultadas pelo app** com policy para
  cada operação CRUD de fato exercitada — nenhuma tabela com RLS habilitada
  e sem policy correspondente à operação usada, nenhuma tabela sem RLS
  sendo consultada pelo cliente `anon`/`authenticated`.

---

## 5. O que muda no estado geral do projeto

Nenhuma funcionalidade foi adicionada ou alterada. `flutter analyze`
continua em 0 issues; `flutter test` passou de 583 para 574 (queda
esperada — só os testes do dead code removido saíram, nenhum teste de
funcionalidade real foi tocado); `dart format --set-exit-if-changed .`
passou de "18 arquivos precisariam mudar" para 0. Uma vulnerabilidade real
de integridade de dados entre grupos foi eliminada. O item de §3.1 fica
registrado como ação operacional pendente antes do Beta (verificação
contra o projeto Supabase real), não como bug de código não resolvido.
