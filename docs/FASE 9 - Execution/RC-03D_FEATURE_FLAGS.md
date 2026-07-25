# RC-03D — Feature Flags

**Data:** 2026-07-25
**Branch:** `feature/rc-03d-feature-flags`
**Status:** Implementado — infraestrutura completa; nenhuma tela consome flags nesta rodada (ver §9)
**Escopo:** exclusivamente o gerenciamento centralizado de Feature Flags via Supabase. Analytics (RC-03C), Crash Reporting (RC-03A), Logging (RC-03B), Feedback In-App e Segurança são itens separados do backlog e não foram tocados nesta rodada.

---

## 1. Objetivo

Dar ao BORAH uma infraestrutura de Feature Flags simples, própria (sem depender do PostHog Feature Flags nesta primeira versão, por decisão explícita), armazenada no Supabase e acessível de forma desacoplada por toda feature — mesmo padrão arquitetural de `CrashReporting`/`AppLogger`/`AppAnalytics` (RC-03A/B/C).

---

## 2. Arquitetura

```
lib/core/feature_flags/
├── feature_flag.dart                    # modelo de domínio FeatureFlag
├── feature_flag_repository.dart         # interface FeatureFlagRepository
├── supabase_feature_flag_repository.dart# única classe que consulta a tabela feature_flags
├── feature_flag_cache.dart              # cache local em memória, escopo de sessão
├── feature_flag_service.dart            # orquestra repository + cache, nunca lança
├── feature_flag_providers.dart          # Providers Riverpod + FeatureFlagsController (reativo)
└── app_feature_flags.dart               # fachada estática AppFeatureFlags (API pública)
```

Nenhuma feature acessa a tabela `feature_flags` nem `FeatureFlagRepository` diretamente:

```
Feature (futura, ainda não conectada nesta rodada)
    ↓ chama
AppFeatureFlags.isEnabled('new_feed')      ← API pública imperativa
    ou
ref.watch(featureFlagsControllerProvider)  ← API pública reativa (Riverpod)
    ↓ delega para
FeatureFlagService                          ← orquestra cache + repositório, nunca lança
    ↓ usa
FeatureFlagCache (em memória) + FeatureFlagRepository (interface)
    ↓ implementado por
SupabaseFeatureFlagRepository                ← única fronteira com a tabela `feature_flags`
```

### 2.1 Duas portas de entrada, mesmo backend

- **`AppFeatureFlags`** (fachada estática) — para checagem imperativa em qualquer lugar do código (`if (AppFeatureFlags.isEnabled('new_feed')) { ... }`), sem precisar de `WidgetRef`. Mesma convenção de `AppLogger`/`CrashReporting`/`AppAnalytics`.
- **`featureFlagsControllerProvider`** (Riverpod) — para telas que precisam *reconstruir* quando o estado das flags muda (`FeatureFlagsStatus`: `Initial`/`Loading`/`Loaded(flags, degraded)`), mesmo padrão sealed-class + `Notifier` usado em toda feature do app (ex. `FavoritesStatus`).

As duas mantêm instâncias **independentes** de `FeatureFlagService`/`FeatureFlagCache` nesta rodada — ambas consultam a mesma tabela via RLS, mas cada uma cacheia separadamente. Como nenhuma tela consome nenhuma das duas ainda (ver §9), isso não causa nenhum problema prático hoje; unificar as duas instâncias (ex.: fazer `AppFeatureFlags` delegar para o container do Riverpod, ou vice-versa) fica para quando houver um consumidor real e ficar claro qual padrão de acesso predomina.

---

## 3. Tecnologia

**Supabase + Riverpod**, conforme decisão explícita desta rodada — **sem** PostHog Feature Flags (disponível no SDK já instalado desde a RC-03C, mas deliberadamente não usado aqui). Nenhuma dependência nova foi adicionada.

---

## 4. Banco de dados

Migration `supabase/migrations/20260725100000_create_feature_flags.sql`:

```sql
create table public.feature_flags (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  enabled boolean not null default false,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

- **RLS SELECT**: qualquer usuário autenticado — o app inteiro (não só administradores) precisa poder consultar o estado das flags.
- **RLS INSERT/UPDATE/DELETE**: somente `super_admin` (`has_admin_role(auth.uid(), 'super_admin')`) — mesmo critério de "menor privilégio" já usado em `public.user_roles`. Uma flag como `maintenance_mode` afeta o app inteiro, então fica no nível mais restrito de administração, não em `can_moderate()`/`is_admin()` (que incluem `admin`/`moderator`/`support`).
- **GRANT**: concedido já nesta mesma migration (`grant select, insert, update, delete on public.feature_flags to authenticated;`) — não deixado para uma correção posterior, lição já registrada da migration `20260720130000_grant_authenticated_privileges.sql` (sem GRANT de tabela, toda policy de RLS é inalcançável).
- **Trigger `updated_at`**: reaproveita `public.set_updated_at()`, já existente desde a `profiles`.
- **Estrutura pensada para expansão futura**: `key`/`enabled`/`description` cobrem hoje um booleano simples; rollout percentual, segmentação por usuário ou payload JSON ficam para quando houver um consumidor real — a tabela não foi desenhada só para as flags da Beta.

### 4.1 Flags iniciais

| Key | `enabled` inicial | Motivo do valor |
|---|---|---|
| `maintenance_mode` | `false` | App não está em manutenção |
| `new_feed` | `false` | Redesenho ainda não construído |
| `new_ranking` | `false` | Redesenho ainda não construído |
| `new_profile` | `false` | Redesenho ainda não construído |
| `enable_notifications` | `true` | Módulo já existe e está ativo hoje |
| `enable_social` | `true` | Módulo já existe e está ativo hoje |
| `enable_reviews` | `true` | Módulo já existe e está ativo hoje |
| `enable_admin` | `true` | Módulo já existe e está ativo hoje |

Nenhum valor altera comportamento algum nesta rodada — nenhuma tela lê nenhuma destas flags ainda (ver §9).

---

## 5. Cache local

`FeatureFlagCache` é **em memória, escopo de sessão** — não persiste em disco. Decisão deliberada de simplicidade: o app já carrega as flags no bootstrap (`AppFeatureFlags.initialize()`, chamado em `main.dart`), então persistência em disco só economizaria a primeira leitura de uma sessão, ao custo de mais uma dependência (ex. `shared_preferences`, não usada no projeto) e mais uma fonte de dado potencialmente desatualizado.

Estratégia (conforme pedido):
- **Carregar na inicialização**: `main.dart` chama `AppFeatureFlags.initialize()` depois de `initializeSupabase()`, sem bloquear a subida do app (`unawaited` — ver §7).
- **Atualizar sob demanda**: `AppFeatureFlags.refresh()`/`FeatureFlagsController.refresh()`, chamável a qualquer momento.
- **Sem polling automático**: nenhum refresh periódico foi implementado — mantém a rodada simples; pode ser adicionado depois se um caso de uso real precisar.

---

## 6. Providers (Riverpod)

| Provider | Tipo | Papel |
|---|---|---|
| `featureFlagRepositoryProvider` | `Provider<FeatureFlagRepository>` | Constrói `SupabaseFeatureFlagRepository` a partir de `supabaseClientProvider` |
| `featureFlagServiceProvider` | `Provider<FeatureFlagService>` | Constrói o serviço com uma `FeatureFlagCache` própria |
| `featureFlagsControllerProvider` | `NotifierProvider<FeatureFlagsController, FeatureFlagsStatus>` | Estado reativo (`Initial`/`Loading`/`Loaded`) para telas que precisam reconstruir quando as flags mudam |

Nenhuma tela consulta o Supabase diretamente — toda comunicação passa por estes Providers (ou por `AppFeatureFlags`, que não usa Riverpod, ver §2.1).

---

## 7. Estratégia offline / Supabase indisponível

**Garantia central desta rodada: nada relacionado a Feature Flags pode impedir o app de subir ou funcionar.**

- `FeatureFlagService.load()`/`.refresh()` **nunca lançam** — qualquer exceção do repositório (rede, Supabase fora do ar, RLS, timeout) é capturada e o método retorna `false` em vez de propagar.
- Em caso de falha:
  - Se nunca houve uma carga bem-sucedida, o cache permanece vazio e `isEnabled(key)` retorna o `defaultValue` (padrão `false`) para qualquer chave — comportamento conservador e uniforme, **sem exceção por flag** (nem mesmo `maintenance_mode`).
  - Se já houve uma carga bem-sucedida antes, o cache **preserva o último valor conhecido** — uma falha de `refresh()` não apaga dados válidos anteriores.
- `main.dart` chama `AppFeatureFlags.initialize()` com `unawaited(...)` — mesmo que a primeira carga demore ou falhe, a UI sobe imediatamente, sem esperar.
- `FeatureFlagsController` (Riverpod) reflete isso via `FeatureFlagsLoaded(flags, degraded: true)` — nunca um estado de erro que bloqueie a tela, só um sinal informativo de que a última tentativa não teve sucesso.

---

## 8. Ambientes

| Ambiente | Onde as flags ficam armazenadas | Quando são carregadas | Quando são atualizadas |
|---|---|---|---|
| Development | Tabela `feature_flags` do projeto Supabase de Development | Bootstrap do app (`main.dart`) | Só via `refresh()` manual (nenhum polling) |
| QA | Tabela `feature_flags` do projeto `borah-qa` | Idem | Idem |
| Beta | Tabela `feature_flags` do projeto de Beta (a ser provisionado — ver RC-02.5) | Idem | Idem |
| Production | Tabela `feature_flags` do projeto de Production (a ser provisionado) | Idem | Idem |

Não há diferença de comportamento por ambiente além da própria conexão Supabase de cada um (diferente de `AppLogger`, que tem gating por nível por ambiente) — todas as flags são lidas da mesma forma em todo lugar; a diferença está em qual projeto Supabase cada ambiente aponta (já resolvido pelo `SUPABASE_URL`/`SUPABASE_ANON_KEY` existentes desde a Fase 5).

---

## 9. O que foi (e o que não foi) integrado nesta rodada

Mesma disciplina de escopo já usada na RC-03A/B/C: construir a infraestrutura completa e testada, sem instrumentar telas.

**Feito nesta rodada:**
- Toda a estrutura de código listada em §2.
- Migration com tabela, RLS, trigger, GRANT e as 8 flags iniciais.
- `main.dart`: `AppFeatureFlags.initialize()` (fire-and-forget, não bloqueia o bootstrap).

**Não feito nesta rodada (explicitamente fora de escopo):**
- Nenhuma tela consulta `AppFeatureFlags.isEnabled()`/`featureFlagsControllerProvider` — `maintenance_mode` não bloqueia nada, `new_feed`/`new_ranking`/`new_profile` não trocam nenhuma UI, `enable_*` não escondem nenhum módulo. As 8 flags existem só como infraestrutura, exatamente como pedido.
- Nenhuma tela de administração para editar flags pela UI do app — hoje a única forma de alterar uma flag é diretamente no Supabase (Dashboard/SQL), como `super_admin`.
- Nenhuma reconciliação entre a instância de `AppFeatureFlags` e a de `featureFlagsControllerProvider` (ver §2.1).

---

## 10. Boas práticas / como adicionar uma nova flag

1. Adicionar uma migration nova (nunca editar a `20260725100000_create_feature_flags.sql` já commitada) com `insert into public.feature_flags (key, enabled, description) values (...) on conflict (key) do nothing;`.
2. Escolher um valor de `enabled` inicial consciente do que ele representa (feature já existente → provavelmente `true`; feature nova/experimental → `false`).
3. Nenhuma mudança de código Dart é necessária só para adicionar uma flag — `AppFeatureFlags.isEnabled('minha_nova_flag')` já funciona assim que a linha existir no banco e o cache for recarregado.
4. Ao decidir *conectar* uma flag a uma tela de verdade, prefira `featureFlagsControllerProvider` se a tela precisa reconstruir quando o valor mudar; use `AppFeatureFlags.isEnabled()` para uma checagem pontual (ex.: dentro de um método de um controller).
5. Nunca assuma que uma flag existe — sempre trate o caso "flag não encontrada" (comportamento já embutido: cai no `defaultValue`).

---

## 11. Testes

| Arquivo | Cobertura |
|---|---|
| `test/unit/core/feature_flags/feature_flag_test.dart` | `FeatureFlag.fromMap` — parsing de linha completa e com `description` nula |
| `test/unit/core/feature_flags/feature_flag_cache_test.dart` | `hasLoaded`, `update()`, substituição de conteúdo, imutabilidade de `flags` |
| `test/unit/core/feature_flags/feature_flag_service_test.dart` | Caminho feliz; falha do repositório nunca lança; fallback para `defaultValue` na primeira falha; cache preservado numa falha de refresh após sucesso anterior; `isEnabled`/`get`/`all` |
| `test/unit/core/feature_flags/feature_flag_providers_test.dart` | `FeatureFlagsController`: estado inicial, `load()` sucesso/falha (`degraded`), `refresh()` preservando dado anterior, `isEnabled()` |
| `test/unit/core/feature_flags/app_feature_flags_test.dart` | Fachada estática: `isEnabled()` antes de `initialize()`, `initialize()`/`refresh()` com sucesso e falha, `get()`/`all` |

**Nota de teste**: `SupabaseFeatureFlagRepository` não é testado diretamente contra um `SupabaseClient` real (mesma decisão já tomada para `PostHogAnalyticsService` na RC-03C) — os testes de `FeatureFlagService`/`FeatureFlagsController`/`AppFeatureFlags` usam um `FeatureFlagRepository` mockado via `mocktail`, o mesmo padrão já usado em toda a suíte do projeto (`MockFavoriteRepository`, `MockAuthRepository` etc.).

---

## 12. Limitações desta rodada

- Nenhuma tela consome nenhuma flag ainda (ver §9) — puramente infraestrutura, como pedido.
- Cache é só em memória (escopo de sessão) — decisão deliberada de simplicidade, não uma limitação técnica.
- Sem refresh automático/periódico — só manual, por decisão de simplicidade.
- `AppFeatureFlags` e `featureFlagsControllerProvider` mantêm instâncias de cache independentes (ver §2.1) — sem impacto prático hoje, mas a ser reconciliado quando houver consumidor real.
- Nenhuma tela de administração para editar flags via o app — gerenciamento hoje é manual, direto no Supabase.
