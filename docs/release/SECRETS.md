# Secrets — BORAH

Inventário de todos os GitHub Secrets consumidos por `.github/workflows/ci.yml`/`release.yml`, com o estado de cadastro no momento desta rodada (RC-01). Para o passo a passo de como obter/gerar cada valor, ver `docs/operations/CI_CD_SECRETS.md` (mantém-se como a referência operacional detalhada); este documento é o inventário de estado, não o tutorial.

**Nenhum valor real aparece aqui — só nomes, consumidores e status.**

## Environment `qa` (usado por `ci.yml`, job `integration_test`)

| Secret | Consumido por | Status |
|---|---|---|
| `SUPABASE_QA_URL` | `ci.yml` → `integration_test` | 🟡 Presumivelmente cadastrado (em uso desde a QA-03) — não confirmável por esta sessão |
| `SUPABASE_QA_ANON_KEY` | idem | 🟡 idem |
| `SUPABASE_QA_SERVICE_ROLE_KEY` | idem (só os helpers de Integration Test, nunca o app em si) | 🟡 idem — **pendência de rotação herdada**: foi exposta uma vez em texto completo durante o provisionamento; recomenda-se rotacionar antes de recadastrar, se ainda não foi feito |

`SUPABASE_QA_PROJECT_REF` **não precisa ser cadastrado** — não é consumido por nenhum workflow nem `--dart-define` (o ref vive hardcoded em `QaEnvironment.qaProjectRef`, `app/integration_test/helpers/qa_environment.dart`).

## Environment `production` (usado por `release.yml`, jobs `build_release`/`build_release_ios`)

### `--dart-define` (bytecode Dart)

| Secret | Consumido por | Status |
|---|---|---|
| `SUPABASE_PROD_URL` | `build_release`, `build_release_ios` | 🔴 Não cadastrado |
| `SUPABASE_PROD_ANON_KEY` | idem | 🔴 Não cadastrado |
| `SENTRY_DSN_PRODUCTION` | idem | 🔴 Não cadastrado — depende do projeto Sentry de Produção existir |
| `POSTHOG_API_KEY_PRODUCTION` | idem | 🔴 Não cadastrado — depende do projeto PostHog de Produção existir |
| `POSTHOG_HOST_PRODUCTION` ⚠️ | idem | 🔴 Não cadastrado — **nunca pode ficar vazio uma vez cadastrado**: a flag `--dart-define=POSTHOG_HOST` é sempre enviada incondicionalmente por `release.yml`, então um valor vazio chega ao app como string vazia (não como o `defaultValue` de `AppEnvironment.postHogHost`), silenciando todo o Analytics de Produção sem nenhum erro visível (`PostHogAnalyticsService` engole falhas por design) |

### Variáveis de ambiente do sistema (build nativo Gradle/Kotlin, não bytecode Dart)

| Secret | Consumido por | Status |
|---|---|---|
| `SENTRY_ORG` | `build_release` (plugin `io.sentry.android.gradle`, via `System.getenv`) | 🔴 Não cadastrado — depende do projeto Sentry de Produção |
| `SENTRY_PROJECT` | idem | 🔴 Não cadastrado |
| `SENTRY_AUTH_TOKEN` | idem | 🔴 Não cadastrado — **segredo sensível**, escopo mínimo `project:releases`, nunca um token de organização inteira |

Sem `SENTRY_AUTH_TOKEN`, o upload do `mapping.txt` do R8 é pulado automaticamente — não bloqueia o build (ver `ANDROID_RELEASE.md`).

### Assinatura Android

| Secret | Consumido por | Status |
|---|---|---|
| `ANDROID_KEYSTORE` | `build_release` (decodificado de Base64 → `android/release.jks`) | 🔴 Não cadastrado |
| `ANDROID_KEYSTORE_PASSWORD` | idem | 🔴 Não cadastrado |
| `ANDROID_KEY_ALIAS` | idem | 🔴 Não cadastrado |
| `ANDROID_KEY_PASSWORD` | idem | 🔴 Não cadastrado |

Sem os 4, o Gradle cai para assinatura de debug — o job nunca quebra por falta deles (ver `ANDROID_RELEASE.md`).

### iOS

**Nenhum secret do GitHub é usado pelo job `build_release_ios` hoje** — `--no-codesign` não precisa de credencial nenhuma. Assinatura real (quando existir) é gerida localmente via Xcode (`CODE_SIGN_STYLE = Automatic`), não via CI. Uma automação futura (Fastlane match ou equivalente) exigiria novos secrets (`MATCH_PASSWORD`, `APP_STORE_CONNECT_API_KEY_*`) — não implementada, fora do escopo desta rodada.

## Resumo

| Categoria | Secrets aplicáveis | Cadastrados |
|---|---|---|
| QA (Integration Tests) | 3 | Presumivelmente sim (não confirmável) |
| Produção — Supabase | 2 | 0 |
| Produção — Sentry (`--dart-define` + Gradle) | 4 (1 DSN + 3 org/project/token) | 0 |
| Produção — PostHog | 2 | 0 |
| Produção — Android (keystore) | 4 | 0 |
| Produção — iOS | 0 | — |

**Total de secrets de Produção pendentes: 12.** Todos já nomeados e consumidos corretamente pelos workflows (nenhum código a escrever) — falta só o valor real, que depende de contas/projetos externos (Sentry, PostHog, keystore) serem criados primeiro. `borah-production` (Supabase) já está provisionado — os 2 secrets de Supabase só precisam ser copiados do Dashboard.

## Onde cadastrar

**Settings → Environments** do repositório no GitHub — dois Environments distintos, nunca misturados:
- `qa`: os 3 secrets de QA. Considerar "Required reviewers" se o repositório passar a aceitar contribuições externas.
- `production`: os 12 secrets acima. **Fortemente recomendado "Required reviewers"** com o responsável pela publicação — `release.yml` dispara em push de tag, e uma tag pode ser criada por engano; um portão manual antes de gastar minutos de runner `macos-latest` (o mais caro) e antes de qualquer artefato assinado ser gerado é uma proteção barata.

Ver também: `docs/operations/CI_CD_SECRETS.md` (passo a passo de obtenção de cada valor), `docs/release/github_secrets.md` (visão mais ampla de infraestrutura, incluindo itens que não são secrets de CI, como contas de loja).
