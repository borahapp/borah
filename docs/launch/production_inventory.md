# Inventário de Produção — Sentry, PostHog, Supabase, GitHub

**Contexto:** BETA-11A. Consolida BETA-03/05/06/08B/08C/08C1/10D. Organizado por ambiente e por responsável.

---

## Supabase

| | Development | Production |
|---|---|---|
| Projeto | `borah-development` (`eagwsvafgcnhhglfgtjo`) | `borah-production` (`uscheppbwhuuwkskhfos`, região `sa-east-1`) |
| Status | ✅ Ativo, 30/30 migrations | ✅ Ativo, 30/30 migrations, paridade confirmada (BETA-05) |
| Variáveis obrigatórias | `SUPABASE_URL`, `SUPABASE_ANON_KEY` (`.env.development`, local, gitignored) | `SUPABASE_URL`, `SUPABASE_ANON_KEY` |
| Secrets do GitHub | N/A (não usado em CI de produção) | `SUPABASE_PROD_URL`, `SUPABASE_PROD_ANON_KEY` — 🔴 não cadastrados |
| Responsável | Já configurado, nenhuma ação pendente | Proprietário — copiar os 2 valores do Dashboard para o GitHub Environment `production` |

*(Nota: `borah-qa` também existe como terceiro ambiente, usado exclusivamente pelos Integration Tests do `ci.yml` — fora do escopo de "Production" pedido aqui, mas documentado em `docs/operations/CI_CD_SECRETS.md` §1.)*

## Sentry

| | Development | Production |
|---|---|---|
| Projeto | 🔴 Nunca criado — `SENTRY_DSN` vazio localmente, SDK no-opa graciosamente | 🔴 Nunca criado |
| Variáveis obrigatórias | `SENTRY_DSN` (vazio = desabilitado, comportamento intencional) | `SENTRY_DSN`, `APP_ENVIRONMENT=production` |
| Secrets do GitHub | N/A | `SENTRY_DSN_PRODUCTION` — 🔴 não cadastrado |
| Upload de símbolos (R8 mapping/dSYM) | N/A | 🟡 Android: plugin `io.sentry.android.gradle` configurado desde a OBS-01A (corrigido o achado da BETA-10D) — falta só `SENTRY_AUTH_TOKEN`. iOS (dSYM): 🔴 não configurado |
| Responsável | Proprietário — criar o projeto Sentry de Produção (guia completo: BETA-08B, nunca commitado como arquivo — resumido em `docs/release/release_infrastructure.md`) | Idem |

## PostHog

| | Development | Production |
|---|---|---|
| Projeto | 🔴 Nunca criado — Development nunca envia eventos por design (`AppAnalytics.isSendingEvents`) | 🔴 Nunca criado |
| Variáveis obrigatórias | `POSTHOG_API_KEY`/`POSTHOG_HOST` (vazios, sem efeito em Development) | `POSTHOG_API_KEY`, `POSTHOG_HOST` (**nunca pode ficar vazio uma vez que a flag é sempre passada**, achado da BETA-08C1) |
| Secrets do GitHub | N/A | `POSTHOG_API_KEY_PRODUCTION`, `POSTHOG_HOST_PRODUCTION` — 🔴 não cadastrados |
| Feature Flags | N/A — BORAH usa seu próprio sistema (Supabase `feature_flags`), não o do PostHog | N/A |
| Responsável | Proprietário — guia completo em `docs/operations/POSTHOG_PRODUCTION_SETUP.md` (decidir região US/EU antes de cadastrar o secret) | Idem |

## GitHub Actions

| Workflow | Ambiente-alvo | Status |
|---|---|---|
| `ci.yml` | QA (Integration Tests) + validações gerais (analyze/format/test/build debug) | ✅ Funcional, nunca confirmado rodando com sucesso na nuvem real (sem acesso à Actions em nenhuma sessão) |
| `release.yml` | Production | 🟡 Configurado corretamente (BETA-03/08C1/10B), mas nunca disparado de verdade — os 9 secrets de Produção não existem ainda |

## GitHub Secrets — resumo por responsável

| Secret | Categoria | Responsável pela criação da conta/projeto | Responsável pelo cadastro no GitHub |
|---|---|---|---|
| `ANDROID_KEYSTORE`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Android | Proprietário (gera a keystore) | Proprietário |
| `SUPABASE_PROD_URL`, `SUPABASE_PROD_ANON_KEY` | Supabase | Já existe | Proprietário |
| `SENTRY_DSN_PRODUCTION` | Sentry | Proprietário (cria o projeto) | Proprietário |
| `POSTHOG_API_KEY_PRODUCTION`, `POSTHOG_HOST_PRODUCTION` | PostHog | Proprietário (cria o projeto, decide região) | Proprietário |

**Todos os 12 secrets de Produção** (contagem corrigida na RC-01 — a tabela acima ainda lista só os 4 originais de Sentry/PostHog/Supabase relevantes a este documento; faltam aqui `SENTRY_ORG`/`SENTRY_PROJECT`/`SENTRY_AUTH_TOKEN`, adicionados na OBS-01A, e os 4 `ANDROID_KEYSTORE*` já listados acima — ver `docs/release/SECRETS.md` para o inventário completo e atual) **têm o mesmo responsável final: o proprietário do projeto** — nenhum pode ser delegado a uma ferramenta automatizada nesta fase, já que todos exigem posse de uma conta externa real.

## Environment `production` do GitHub

🔴 Ainda não criado (`release.yml` já referencia `environment: production` desde a BETA-03, mas o Environment em si nunca foi criado do lado do GitHub — passo manual: Settings → Environments → New environment).
