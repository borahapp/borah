# GitHub Secrets e Configuração Manual da CI/CD

**Contexto:** QA-03, Rodada F. Complementa `docs/FASE 4 - FOUNDATION/AR-05_CI_CD.md` (arquitetura/intenção) com os passos práticos de configuração que só podem ser feitos manualmente no GitHub — nenhuma ferramenta disponível nas sessões de implementação (`gh` CLI) tinha acesso para cadastrar isso automaticamente (mesma limitação já registrada na Rodada 0 do QA-03, `EX-10_FASE_6_QA_STATUS.md` §"Rodada 0").

Nenhum valor real aparece neste documento — apenas placeholders e o formato esperado.

---

## 1. Secrets necessários hoje (Integration Tests, `.github/workflows/ci.yml`)

Cadastrar em **Settings → Secrets and variables → Actions**, idealmente dentro do Environment `qa` (ver §3) em vez de "Repository secrets" diretamente.

| Secret | Finalidade | Formato esperado | Onde obter |
|---|---|---|---|
| `SUPABASE_QA_URL` | URL do projeto `borah-qa`, usada como `SUPABASE_URL` (`--dart-define`) | `https://<ref>.supabase.co` | Dashboard do Supabase → `borah-qa` → Project Settings → API |
| `SUPABASE_QA_ANON_KEY` | Chave anônima/pública do `borah-qa`, usada como `SUPABASE_ANON_KEY` | JWT legado (`eyJ...`) ou novo formato `sb_publishable_...` | Mesma página acima |
| `SUPABASE_QA_PROJECT_REF` ⚠️ | Ref do projeto `borah-qa` (`fgzokfkvccgkclkmfqui`) — **ver nota abaixo: não precisa ser cadastrado hoje** | string alfanumérica de 20 caracteres | Mesma página acima, ou a própria URL |
| `SUPABASE_QA_SERVICE_ROLE_KEY` | Usada **somente** pelos helpers de Integration Test (`QaTestUserHelper`, `QaRestaurantHelper`, `QaSocialHelper`) para criar/remover dados de teste via Admin API/PostgREST, ignorando RLS | JWT legado (`eyJ...`) ou novo formato `sb_secret_...` (preferir o novo formato — ver pendência de rotação abaixo) | Dashboard → `borah-qa` → Project Settings → API → **nunca usar `--reveal` fora de uma sessão descartável** |

**Nota sobre `SUPABASE_QA_PROJECT_REF` (achado da BETA-05):** este secret **não é consumido por nenhum workflow** (`ci.yml`/`release.yml`) nem por nenhum `--dart-define` — auditoria confirmou que o ref do ambiente QA está definido diretamente em código, hardcoded em `QaEnvironment.qaProjectRef` (`app/integration_test/helpers/qa_environment.dart:12`), não lido de variável de ambiente nenhuma. Por isso, **seu cadastro no GitHub não é necessário no estado atual do projeto** — só é mantido nesta tabela para referência do valor em si. Caso o ref do projeto QA seja externalizado no futuro (por exemplo, se `QaEnvironment` passar a ler de `--dart-define` em vez de ter o valor fixo no código), este secret volta a ser efetivamente consumido pelos workflows e passa a ser necessário cadastrá-lo.

**Nunca** usar as chaves do `borah-development` ou de produção aqui — os workflows de CI existem exclusivamente para rodar contra `borah-qa`. `QaEnvironment.assertRunningAgainstQaProject()` já aborta a suíte se a URL não apontar para o ref correto, mas isso só é uma rede de segurança, não substitui cadastrar o secret certo.

**Pendência herdada da Rodada 0:** a `SERVICE_ROLE_KEY` do `borah-qa` foi exposta uma vez em texto completo durante o provisionamento (achado de segurança já registrado em `EX-10_FASE_6_QA_STATUS.md`). Recomenda-se **rotacionar** essa chave (Dashboard → Project Settings → API → Reset service_role key, preferindo o formato novo `sb_secret_...`) antes de cadastrá-la como secret de CI, caso ainda não tenha sido feito.

---

## 2. Secrets pendentes (Release assinado)

**Atualizado na RC-04D; workflow adaptado na BETA-03.** `android/app/build.gradle.kts` já está preparado para ler uma keystore de release a partir de `android/key.properties` (nunca versionado — coberto por `android/.gitignore`), com fallback automático para a assinatura de **debug** quando o arquivo não existir (preserva `flutter run --release` local). O template `android/key.properties.example` documenta o formato esperado. **Falta apenas gerar a keystore real e preencher os valores** — nenhuma chave/senha foi gerada nesta rodada, por exigir custódia exclusiva de quem vai publicar o app.

Passo a passo para o responsável (fora deste chat, guardando o `.jks` e as senhas em um cofre seguro — nunca em texto puro):

1. `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias borah_release`
2. Copiar `android/key.properties.example` para `android/key.properties` e preencher `storePassword`/`keyPassword`/`keyAlias`/`storeFile`.
3. Para builds locais, colocar `release.jks` em `android/` (ou usar caminho absoluto em `storeFile`). Para CI, cadastrar os 4 secrets abaixo.

`.github/workflows/release.yml` **já decodifica estes secrets automaticamente** (job `build_release`, passo "Decode Android release keystore") — cadastrá-los é a única ação restante:

| Secret | Finalidade | Formato esperado |
|---|---|---|
| `ANDROID_KEYSTORE` | Arquivo `.jks`/`.keystore` de release, codificado em Base64 | string Base64 (`base64 -w0 release.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Senha da keystore | string |
| `ANDROID_KEY_ALIAS` | Alias da chave dentro da keystore | string |
| `ANDROID_KEY_PASSWORD` | Senha da chave (pode ser igual à da keystore) | string |

O passo só roda quando `ANDROID_KEYSTORE` está cadastrado (`if: secrets.ANDROID_KEYSTORE != ''`); sem ele, o job continua funcionando exatamente como antes (assinatura de debug), sem quebrar. Nenhum valor é impresso em log.

Equivalente iOS: `ios/Runner.xcodeproj` está com `CODE_SIGN_STYLE = Automatic` e sem `DEVELOPMENT_TEAM` configurado — requer uma conta Apple Developer Program real, configurada diretamente no Xcode por quem for publicar (nada a preparar em código para isso). O novo job `build_release_ios` (BETA-03) roda `flutter build ios --release --no-codesign` como portão de qualidade (confirma que a build de Release compila para iOS), mas **não gera um IPA assinado nem o envia ao TestFlight** — isso continua sendo um passo manual (Xcode Organizer → Archive → Distribute App) até que a conta Apple Developer exista e, opcionalmente, uma automação tipo Fastlane match seja adotada (não implementada nesta rodada — exigiria um repositório de certificados e chaves de API da App Store Connect, ambos segredos reais).

**Custo do runner `macos-latest`:** o GitHub Actions cobra minutos de runner macOS a uma taxa bem mais alta que Linux (aprox. 10×). Como `build_release_ios` só roda em push de tag `v*.*.*` ou disparo manual (não em todo push/PR, ao contrário do job Android), o impacto é baixo, mas vale o responsável pelo billing do repositório estar ciente antes da primeira tag real.

---

## 2.1 Secrets pendentes (variáveis de ambiente de Produção)

**Novo na BETA-03.** `.github/workflows/release.yml` agora injeta `--dart-define` nas builds de Release (Android e iOS) a partir dos secrets abaixo — hoje inexistentes, então os builds gerados por este workflow continuam **funcionalmente vazios** (sem `SUPABASE_URL` real) até que sejam cadastrados. Nenhum destes aponta para o mesmo projeto usado por Development/QA — depende de um projeto Supabase de Produção ainda não provisionado (ação do proprietário, ver `BETA-03_PRODUCTION_STORE_PREPARATION.md`).

| Secret (futuro) | Finalidade | Onde obter |
|---|---|---|
| `SUPABASE_PROD_URL` | URL do projeto Supabase de Produção, usada como `SUPABASE_URL` | Dashboard do Supabase → projeto de Produção → Project Settings → API (projeto ainda não existe) |
| `SUPABASE_PROD_ANON_KEY` | Chave anônima/pública do projeto de Produção | Mesma página acima |
| `SENTRY_DSN_PRODUCTION` | DSN do projeto Sentry de Produção (RC-03A) | Projeto Sentry dedicado, ainda não provisionado — ver §2.2 do checklist BETA-03 |
| `POSTHOG_API_KEY_PRODUCTION` | Project token do PostHog de Produção (RC-03C) | Projeto PostHog dedicado, ainda não provisionado |
| `POSTHOG_HOST_PRODUCTION` ⚠️ **obrigatório, nunca vazio** | Host de ingestão do PostHog de Produção — ver detalhamento completo em `POSTHOG_PRODUCTION_SETUP.md` | `https://us.i.posthog.com` (região US) ou `https://eu.i.posthog.com` (região EU), conforme a região escolhida na criação do projeto |
| `GOOGLE_PLACES_API_KEY_PRODUCTION` (novo, IOS-PLACES-02) | Chave da Google Places API (New), usada como `GOOGLE_PLACES_API_KEY` (`--dart-define`) — consumida por `AppEnvironment.googlePlacesApiKey` (`String.fromEnvironment`, sem `defaultValue`: ausente = string vazia) | Google Cloud Console → APIs & Services → Credentials. **Mesma chave já usada localmente em `.env.qa`** (não versionado) — nunca commitar, nunca imprimir, nunca colocar em `Info.plist`/`pubspec.yaml`/código-fonte. Confirmar `Application restrictions: None` / `API restrictions: Places API (New)` antes de cadastrar (mesma configuração já validada para o build Android) |

Mesma filosofia não-bloqueante do §1 para `SUPABASE_PROD_*`/`SENTRY_DSN_PRODUCTION`/`POSTHOG_API_KEY_PRODUCTION`: enquanto os secrets não existirem, `${{ secrets.X }}` resolve para string vazia e o `--dart-define` correspondente chega vazio — idêntico ao comportamento anterior a esta rodada (nenhum `--dart-define` era passado). Nenhuma regressão foi introduzida; a plumbing só passa a funcionar de verdade quando o proprietário cadastrar os valores reais.

**`POSTHOG_HOST_PRODUCTION` é diferente dos demais (BETA-08C1) — nunca deixar vazio uma vez que o projeto PostHog exista.** `release.yml` agora passa `--dart-define=POSTHOG_HOST=${{ secrets.POSTHOG_HOST_PRODUCTION }}` **incondicionalmente** (a flag está sempre presente na compilação, diferente dos outros secrets que só "funcionam de verdade" quando cadastrados). Isso é intencional: `AppEnvironment.postHogHost` usa `String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com')` — esse `defaultValue` só é usado quando a flag `--dart-define` está **totalmente ausente** da compilação, nunca quando está presente com valor vazio. Como `release.yml` agora sempre inclui a flag, um `POSTHOG_HOST_PRODUCTION` vazio ou nunca cadastrado chega ao app como string vazia (não como o default US), e o `PostHogAnalyticsService` engole esse erro silenciosamente (try/catch por design, RC-03C) — resultado: **Analytics de Produção completamente silencioso, sem nenhum erro visível em lugar nenhum.** Assim que o projeto PostHog de Produção for criado, cadastrar este secret imediatamente, com o valor exato correspondente à região escolhida.

**Nunca reutilizar** as chaves do `borah-development` ou `borah-qa` aqui — mesma regra do §1, agora estendida ao ambiente de Produção.

---

## 2.2 Secrets pendentes (upload do mapping do R8 ao Sentry)

**Novo na OBS-01A.** `android/app/build.gradle.kts` agora aplica o plugin oficial `io.sentry.android.gradle` (versão `6.16.0`, compatibilidade com AGP 9.0.1/Kotlin 2.3.20 confirmada empiricamente via `flutter build appbundle --release` nesta sessão) para automatizar o envio do `mapping.txt` do R8/ProGuard ao Sentry a cada build de Release Android — resolve o achado da BETA-10D (crashes de Produção chegariam com stack traces ofuscados sem isso).

| Secret (futuro) | Finalidade | Onde obter |
|---|---|---|
| `SENTRY_ORG` | Slug da organização Sentry | Projeto Sentry de Produção, ainda não provisionado — Settings → General |
| `SENTRY_PROJECT` | Slug do projeto Sentry de Produção | Mesma página acima |
| `SENTRY_AUTH_TOKEN` | Token de autenticação para upload (**segredo sensível** — nunca usar um token de escopo maior que "release" no projeto correspondente) | Sentry → Settings → Auth Tokens → criar um token com escopo `project:releases` |

**Diferente dos secrets do `--dart-define` (§2.1), estes 3 são lidos como variáveis de ambiente do sistema operacional** (`System.getenv(...)` dentro do `build.gradle.kts`), passadas via o bloco `env:` do step "Build APK/AAB" em `release.yml` — não são injetadas no bytecode Dart, são consumidas só pelo Gradle/Kotlin durante a fase de build nativo.

**Comportamento sem os secrets**: `autoUploadProguardMapping` é calculado dinamicamente (`!SENTRY_AUTH_TOKEN.isNullOrEmpty()`) — sem o token, o upload é pulado automaticamente (confirmado nesta sessão: a mensagem `> skipping upload.` aparece no log da build, e o `.aab` é gerado normalmente) — mesma filosofia não-bloqueante de todos os demais secrets deste documento.

**Nunca reutilizar** o token de um projeto Sentry de QA/Desenvolvimento aqui, caso um venha a existir no futuro — mesma regra do §1/§2.1.

---

## 3. Configuração manual recomendada no GitHub (não é código, feito pela UI)

Nenhum destes itens pode ser configurado por arquivo neste repositório — são ajustes de **Settings** do GitHub, cadastrados uma única vez por quem tem acesso administrativo.

### 3.1 Environment `qa`

**Settings → Environments → New environment → `qa`.**

- Adicionar os 4 secrets do §1 como *Environment secrets* (não *Repository secrets*) — isolam o acesso apenas aos jobs que declaram `environment: qa` (como `integration_test` em `ci.yml`).
- Opcional, recomendado quando o repositório passar a aceitar contribuições externas: marcar **"Required reviewers"** para exigir aprovação manual antes de qualquer job que use o Environment `qa` rodar em um Pull Request de fora do time.

### 3.1.1 Environment `production` (novo, BETA-03)

**Settings → Environments → New environment → `production`.**

- Adicionar os secrets do §2 (`ANDROID_KEYSTORE*`) e do §2.1 (`SUPABASE_PROD_*`, `SENTRY_DSN_PRODUCTION`, `POSTHOG_API_KEY_PRODUCTION`) como *Environment secrets*, isolados do Environment `qa`.
- **Fortemente recomendado**: marcar **"Required reviewers"** com o próprio responsável pela publicação — `release.yml` dispara em push de tag `v*.*.*`, e uma tag pode ser criada por engano; um portão de aprovação manual antes de gastar minutos de runner (principalmente `macos-latest`, mais caro) e antes de qualquer artefato assinado ser gerado é uma proteção barata.
- Diferente do Environment `qa` (usado por um job de teste, que roda em todo push/PR), `production` só é referenciado pelos jobs de `release.yml` — nenhum job de `ci.yml` deve declarar `environment: production`.

### 3.2 Branch Protection (`develop` e `main`)

**Settings → Branches → Add branch protection rule**, uma para cada branch, conforme já determinado em `AR-04_GIT_STRATEGY.md` §8:

- `develop`: exigir que os checks `Flutter Analyze`, `Flutter Test (Unit + Widget)` e `Build Android (debug)` passem antes do merge (não incluir `Integration Test` como obrigatório inicialmente, dado o tempo de execução — ver limitação abaixo; promover a obrigatório quando a suíte se mostrar estável em CI).
- `main`: mesmas exigências de `develop`, mais **"Require a pull request before merging"** e **"Require approvals" (mínimo 1)**, conforme AR-04 §8.

### 3.3 Dependabot, CODEOWNERS, Issue/PR templates (AR-04 §12)

Itens listados no AR-04 mas fora do escopo desta rodada (não fazem parte de "GitHub Actions/CI de testes", que foi o pedido do QA-03). Ficam registrados como pendência para uma rodada de governança de repositório, não de QA.

---

## 4. Limitações conhecidas desta rodada

- **Não foi possível validar a execução real dos workflows no GitHub.** A implementação foi validada localmente (sintaxe YAML, e cada comando individual já exercido nas Rodadas B–E) mas nenhuma ferramenta com acesso à nuvem de Actions (`gh` CLI ou equivalente) estava disponível na sessão de implementação. **Após o push, é necessário confirmar manualmente** que os 4 jobs de `ci.yml` e o job de `release.yml` completam com sucesso pelo menos uma vez.
- **Tempo de execução do job `integration_test`:** 23 arquivos em matriz, cada um reconstruindo e reinstalando o APK em um emulador Android novo. Mesmo com cache de Gradle/pub, esse job é o mais lento da pipeline por uma margem larga. Fica como melhoria futura decidir se todos os 23 devem rodar em todo PR ou se um subconjunto (ex.: só os 5 mais críticos) roda por padrão, com a suíte completa reservada para push em `develop`/`main` ou `workflow_dispatch`.
- **Risco de concorrência contra o mesmo ambiente `borah-qa`:** eliminado por dois mecanismos redundantes em `ci.yml` — `strategy.max-parallel: 1` (nenhum dos 23 arquivos da matriz roda simultaneamente a outro, dentro da mesma execução do workflow) e `concurrency: group: integration-tests` com grupo estático (nenhuma execução deste job, de nenhuma execução do workflow — outro PR, outro push —, roda ao mesmo tempo que outra). Resultado confirmado (Rodada F): os 23 arquivos sempre rodam um de cada vez, nunca em paralelo entre si nem entre PRs — um trade-off aceito em favor de correção sobre velocidade.
