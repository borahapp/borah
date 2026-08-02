# Infraestrutura de Release — BORAH

**Contexto:** BETA-10D. Documenta a infraestrutura externa necessária para a publicação (domínio, Sentry, PostHog), complementando o que já existe em `docs/operations/` (CI/CD) e `docs/legal/` (jurídico). Nenhuma conta foi criada, nenhum serviço externo foi acessado — só documentação.

---

## 1. Domínio oficial

`https://www.appborah.com.br` — auditado nesta rodada, sem nenhuma estrutura de hospedagem prevista no repositório até agora. A arquitetura proposta e a escolha de hospedagem estão detalhadas em `docs/release/hosting.md`.

### URLs oficiais planejadas

| URL | Conteúdo | Status do conteúdo-fonte |
|---|---|---|
| `https://www.appborah.com.br/` | Página inicial institucional | 🔴 Não redigida |
| `https://www.appborah.com.br/privacidade` | Política de Privacidade | ✅ Pronto (`docs/legal/privacy_policy.md`) |
| `https://www.appborah.com.br/termos` | Termos de Uso | ✅ Pronto (`docs/legal/terms_of_use.md`) |
| `https://www.appborah.com.br/suporte` | Central de Ajuda | ✅ Pronto (`docs/legal/support.md`) |
| `https://www.appborah.com.br/contato` | Contato | 🔴 Não redigida |

---

## 2. Sentry (Produção)

Complementa `docs/legal/README.md` e o guia operacional já apresentado na BETA-08B (nunca registrado como arquivo — consolidado aqui pela primeira vez).

### Projeto de Produção
- Ainda não criado. Nome sugerido: `borah-production` (mesma convenção já usada para Supabase/PostHog).
- Plataforma: Flutter (ou "Dart", conforme disponibilidade no onboarding do Sentry).

### DSN
- Obtido em Project Settings → Client Keys (DSN), após a criação do projeto.
- Cadastrado como `SENTRY_DSN_PRODUCTION` (Environment `production` do GitHub, ver `github_secrets.md`).

### Environment
- `AppEnvironment.environmentName` já tagueia todo evento com `production` via `--dart-define=APP_ENVIRONMENT=production` (já configurado em `release.yml` desde a BETA-03) — nenhuma configuração adicional necessária no lado do Sentry além de garantir que o filtro de Environment no dashboard use esse valor.

### Release
- `sentry_flutter` já detecta automaticamente a versão/build do app (formato padrão `<bundle-id>@<version>+<build>`) sem nenhuma configuração explícita de `options.release`/`options.dist` em `crash_reporting.dart` — confirmado por leitura do código (nenhuma dessas opções é setada manualmente). Isso é suficiente para associar cada evento à versão correta do app automaticamente.

### Source Maps / Símbolos de depuração — **resolvido na OBS-01A, posterior a esta auditoria**
- O achado original desta seção (nenhum plugin Sentry Gradle configurado) foi corrigido na rodada OBS-01A: `android/app/build.gradle.kts` agora aplica `io.sentry.android.gradle` (versão `6.16.0`, compatibilidade com AGP 9.0.1/Kotlin 2.3.20 confirmada empiricamente) e automatiza o upload do `mapping.txt` do R8 a cada build de Release, condicionado à presença do secret `SENTRY_AUTH_TOKEN` (sem ele, o upload é pulado sem quebrar o build). Detalhe completo e os 3 secrets envolvidos (`SENTRY_ORG`/`SENTRY_PROJECT`/`SENTRY_AUTH_TOKEN`) em `docs/release/ANDROID_RELEASE.md` e `docs/release/SECRETS.md` (documentação oficial de release a partir da RC-01).
- Para iOS, o equivalente seria o upload dos arquivos `dSYM` — ainda não configurado, e só verificável num ambiente macOS real (mesma limitação registrada em `docs/release/IOS_RELEASE.md`).

### Alertas
- Não configurados ainda (dependem do projeto existir). Recomendação: pelo menos um alerta para "novo tipo de erro" (issue nunca vista antes) e um para "spike de volume" (mesmo erro ocorrendo acima de um limiar em curto período) — ambos configuráveis diretamente no dashboard do Sentry, sem nenhuma mudança de código.

---

## 3. PostHog (Produção)

O guia principal já existe e é completo: `docs/operations/POSTHOG_PRODUCTION_SETUP.md` (BETA-08C1) — cobre criação do projeto, região, API Key, Host, cadastro dos secrets, validação, dashboards e métricas recomendadas. Esta seção só acrescenta dois tópicos não cobertos lá.

### Feature Flags
- **BORAH não usa o produto de Feature Flags do PostHog.** O app já tem seu próprio sistema de feature flags, apoiado numa tabela própria do Supabase (`feature_flags`, RC-03D) e consumido via `AppFeatureFlags` — nenhuma configuração de Feature Flags é necessária no PostHog. Registrado aqui explicitamente para evitar que uma rodada futura tente configurar isso por engano, duplicando um sistema que já existe.

### Retention (retenção de dados brutos no próprio PostHog)
- Configuração de projeto (Project Settings → Data management), separada da política de retenção do BORAH descrita na Política de Privacidade (180 dias para logs técnicos/auditoria).
- **Recomendação**: alinhar a retenção do PostHog a um período razoável e documentado (o padrão do PostHog costuma ser mais longo que 180 dias) — decisão do proprietário, não decidida nesta rodada, já que envolve trade-off entre valor analítico de longo prazo e minimização de dados (princípio já seguido na Política de Privacidade).

---

## 4. Referências cruzadas

- Secrets do GitHub por categoria: `docs/release/github_secrets.md`
- Arquitetura de hospedagem do domínio: `docs/release/hosting.md`
- Checklist consolidado: `docs/release/release_checklist.md`
- Guia PostHog completo: `docs/operations/POSTHOG_PRODUCTION_SETUP.md`
- Secrets técnicos (CI/CD): `docs/operations/CI_CD_SECRETS.md`
- Documentação jurídica: `docs/legal/`
