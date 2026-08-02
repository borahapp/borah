# GitHub Secrets — Revisão Completa por Categoria

**Contexto:** BETA-10D. Consolida, por categoria, todos os GitHub Secrets já documentados em rodadas anteriores (`docs/operations/CI_CD_SECRETS.md`, BETA-03/05/06/08C1) e confirma o que ainda não existe. Nenhum secret novo foi criado ou cadastrado nesta rodada — só revisão e organização.

**Nota da RC-01 (2026-08-02):** a rodada OBS-01A (posterior a esta) adicionou 3 secrets de Sentry (`SENTRY_ORG`/`SENTRY_PROJECT`/`SENTRY_AUTH_TOKEN`, upload do mapping R8) não refletidos no total desta página — a tabela/resumo abaixo ficou desatualizada. **`docs/release/SECRETS.md` é o inventário de secrets de release/CI atualizado** (12 secrets de Produção, não 9) — use aquele documento como fonte corrente; esta página permanece válida para o contexto de infraestrutura mais amplo (Google Play/Apple, histórico).

---

## Android

| Secret | Status | Consumido por |
|---|---|---|
| `ANDROID_KEYSTORE` | 🔴 Não cadastrado | `release.yml` (`build_release`) |
| `ANDROID_KEYSTORE_PASSWORD` | 🔴 Não cadastrado | `release.yml` |
| `ANDROID_KEY_ALIAS` | 🔴 Não cadastrado | `release.yml` |
| `ANDROID_KEY_PASSWORD` | 🔴 Não cadastrado | `release.yml` |

Todos os 4 já são consumidos condicionalmente (`if: secrets.ANDROID_KEYSTORE != ''`) — sem eles, o build cai para assinatura de debug (comportamento já validado na BETA-10B, build de Release Android gerada com sucesso mesmo sem estes 4 secrets).

## iOS

**Nenhum secret do GitHub é usado hoje.** O job `build_release_ios` (`release.yml`) roda com `--no-codesign` — não assina nem exporta IPA, só valida que a build compila (BETA-03/BETA-10C). Certificados/provisioning profiles são geridos localmente via Xcode (Automatic Signing), não via CI. Se uma automação futura (ex.: Fastlane match) for adotada, exigiria novos secrets (`MATCH_PASSWORD`, `APP_STORE_CONNECT_API_KEY_*`, etc.) — não implementado, fora do escopo.

## Supabase

| Secret | Status | Ambiente |
|---|---|---|
| `SUPABASE_QA_URL` | 🟡 Documentado, status de cadastro real não confirmável por este chat | QA (`ci.yml`, Integration Tests) |
| `SUPABASE_QA_ANON_KEY` | 🟡 Idem | QA |
| `SUPABASE_QA_SERVICE_ROLE_KEY` | 🟡 Idem | QA (só helpers de Integration Test) |
| `SUPABASE_QA_PROJECT_REF` | ⚠️ Não é necessário cadastrar — não consumido por nenhum workflow/código (achado da BETA-05, ver `CI_CD_SECRETS.md` §1) | — |
| `SUPABASE_PROD_URL` | 🔴 Não cadastrado | Produção (`release.yml`) |
| `SUPABASE_PROD_ANON_KEY` | 🔴 Não cadastrado | Produção |

`borah-production` já está provisionado (BETA-05, migrations aplicadas, paridade com QA/Dev confirmada) — os valores para os 2 secrets de Produção já existem e só precisam ser copiados do Dashboard do Supabase para o GitHub.

## Sentry

| Secret | Status |
|---|---|
| `SENTRY_DSN_PRODUCTION` | 🔴 Não cadastrado — depende do projeto Sentry de Produção ainda não criado (BETA-08B) |

## PostHog

| Secret | Status |
|---|---|
| `POSTHOG_API_KEY_PRODUCTION` | 🔴 Não cadastrado — depende do projeto PostHog de Produção ainda não criado (BETA-08C) |
| `POSTHOG_HOST_PRODUCTION` ⚠️ | 🔴 Não cadastrado — **obrigatório assim que o projeto existir, nunca pode ficar vazio** (BETA-08C1: a flag `--dart-define=POSTHOG_HOST` é sempre passada incondicionalmente; vazio ≠ ausente para o `defaultValue` do Dart) |

## Google Play

**Nenhum secret do GitHub é usado hoje.** Não existe automação de submissão à Play Store via CI — isso exigiria uma chave de conta de serviço (service account JSON) da Google Play Developer API, não implementada nesta fase (submissão é manual, via Play Console).

## Apple

**Nenhum secret do GitHub é usado hoje.** Mesma lógica do Google Play — automação de submissão via App Store Connect API exigiria uma API Key própria (`ASC_KEY_ID`/`ASC_ISSUER_ID`/arquivo `.p8`), não implementada; submissão é manual, via Xcode Organizer/App Store Connect.

---

## Resumo

| Categoria | Secrets aplicáveis hoje | Já cadastrados |
|---|---|---|
| Android | 4 | 0 confirmados |
| iOS | 0 | — |
| Supabase | 5 (3 QA + 2 Produção) | QA presumivelmente sim (usado desde a QA-03); Produção 0 |
| Sentry | 4 (corrigido na RC-01 — inclui os 3 do plugin Gradle) | 0 |
| PostHog | 2 | 0 |
| Google Play | 0 | — |
| Apple | 0 | — |

**Total de secrets de Produção pendentes de cadastro: 12** (4 Android + 2 Supabase + 4 Sentry + 2 PostHog — corrigido na RC-01, incluindo os 3 secrets de Sentry Gradle da OBS-01A que não existiam quando esta página foi escrita; ver `docs/release/SECRETS.md`). Todos já nomeados e consumidos corretamente pelos workflows — falta só o valor real, que depende dos projetos/contas externas serem criados primeiro (Sentry, PostHog, keystore; Supabase de Produção já está pronto, só falta copiar os valores).

Nenhum secret foi criado, alterado ou acessado nesta rodada — só auditoria e consolidação da documentação já existente.
