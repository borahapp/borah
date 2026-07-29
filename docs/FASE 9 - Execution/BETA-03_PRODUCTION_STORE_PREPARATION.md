# BETA-03 — Configuração do Ambiente de Produção e Preparação das Lojas

**Data:** 2026-07-26
**Branch:** `feature/beta-03-production-preparation`
**Status:** Implementado — auditoria, gap analysis, infraestrutura de CI/CD e checklist operacional concluídos. Nenhuma publicação realizada; nenhuma conta externa criada; nenhum segredo real gerado.
**Escopo:** exclusivamente infraestrutura para produção, Google Play, Apple App Store, TestFlight e Google Play Internal Testing. Nenhuma funcionalidade nova, nenhuma regra de negócio, nenhuma mudança de UX/navegação/gamificação.

---

## 1. Objetivo

Preparar tudo o que depende de **código e infraestrutura** para a Macroetapa 2 do roadmap ("Configurar o ambiente de produção e as lojas"), sem publicar nenhuma build e sem depender de contas externas ainda não provisionadas. Tudo o que só pode ser resolvido por quem detém as contas (Google Play Console, Apple Developer Program, Supabase, Sentry, PostHog) fica documentado como checklist operacional (§5).

---

## 2. Fase 1 — Auditoria

Auditoria conduzida por leitura direta do estado atual do projeto (configuração Android/iOS, workflows de CI/CD, variáveis de ambiente, documentação de rodadas anteriores) — nenhuma alteração feita antes desta seção.

| Item | Situação encontrada | Classificação |
|---|---|---|
| Android — `applicationId`/versionamento | `com.borah.app`, `versionCode`/`versionName` derivados de `pubspec.yaml` (`1.0.0+1`) | ✅ pronto |
| Android — shrink/minify/obfuscation | `isMinifyEnabled`/`isShrinkResources` habilitados desde a RC-04D; nunca validado com build real (sem SDK Android completo neste ambiente) | 🟡 depende de validação operacional (build real em ambiente com SDK completo) |
| Android — assinatura de release | Plumbing completo em `build.gradle.kts` (lê `android/key.properties`, cai para debug na ausência); nenhuma keystore real existe | 🟡 depende do proprietário (gerar keystore, guardar em cofre) |
| iOS — bundle ID/versionamento | `com.borah.app` consistente em todos os targets; `CFBundleShortVersionString`/`CFBundleVersion` corretamente ligados a `FLUTTER_BUILD_NAME`/`FLUTTER_BUILD_NUMBER` | ✅ pronto |
| iOS — `DEVELOPMENT_TEAM` | Ausente do `project.pbxproj` — nenhuma linha, nem vazia | 🔴 requer conta Apple Developer Program real (não é alteração de código: é preencher no Xcode) |
| iOS — `CODE_SIGN_STYLE` | `Automatic` em todos os targets — correto para quando uma conta real for anexada | ✅ pronto |
| iOS — capabilities | Nenhuma habilitada hoje (Push, Sign in with Apple, etc.) — consistente, pois o app não usa nenhuma | ✅ pronto (nada a fazer) |
| Deep link de recuperação de senha (`borah://password-recovery`) | Registrado em `AndroidManifest.xml` e `Info.plist` desde a RC-04E | ✅ pronto no app |
| Redirect URLs no Supabase Dashboard | Pendência já registrada na RC-04E (`Authentication → URL Configuration`) — nunca cadastrada, porque nenhum projeto de Produção existe ainda | 🔴 requer conta/projeto Supabase de Produção |
| Supabase — projeto de Produção | **Não existe.** Só `borah-development` e `borah-qa` estão provisionados | 🔴 requer conta Supabase (ação do proprietário) |
| Supabase — schema/RLS/Storage buckets | 100% migration-driven (31 migrations em `supabase/migrations/`, incluindo buckets `avatars`/`restaurants`/`review-photos` com RLS completa) — replicável em qualquer projeto novo via `supabase db push` | ✅ pronto no código — 🟡 depende de execução operacional contra o projeto novo |
| Variáveis de ambiente (`AppEnvironment`) | `String.fromEnvironment` com defaults seguros; `.env.development`/`.env.qa` existem localmente (gitignorados, nunca commitados — confirmado por `git log --all`); `.env.staging`/`.env.production` não existem ainda (esperado — não há projeto para apontar) | ✅ pronto no código — 🔴 falta o projeto Supabase/Sentry/PostHog de Produção para os valores reais |
| CI/CD — workflow de Release | `flutter build apk/appbundle --release` sem nenhum `--dart-define` (build "vazio" de fato); nenhuma decodificação de keystore; nenhum job iOS | 🔴 requer alteração no projeto — **corrigido nesta rodada** (ver §4) |
| CI/CD — GitHub Secrets | 4 secrets de keystore documentados desde a RC-04D, nunca cadastrados; nenhum secret de Produção existia | 🔴 requer conta GitHub (Settings → Secrets) — nomes já documentados (ver §4/§5) |
| Bundle IDs / package names | Únicos, consistentes, sem caracteres reservados, batem entre `pubspec.yaml`/Android/iOS | ✅ pronto |
| Ícone/splash | Oficiais aplicados (IV-02/IV-03) | ✅ pronto |
| Ícone Google Play 512px | Copiado do pacote oficial (IV-09) | ✅ pronto |
| Screenshots de loja / feature graphic | Inexistentes — não há arte oficial pronta nem build instalável em dispositivo real neste ambiente | 🔴 requer dispositivo/emulador real + build de release funcional |
| Google Play — Data Safety / App Store — App Privacy | Nunca preenchido; inventário de dados coletados nunca consolidado | 🟡 depende apenas de preenchimento no Console/Connect — **inventário pronto nesta rodada** (ver §5.3) |
| Política de Privacidade / Termos de Uso | **Não existe nenhum documento, nem em texto nem hospedado** — confirmado por busca em todo o repositório e na documentação de rodadas anteriores (RC-04C explicitamente excluiu este item do escopo) | 🔴 **bloqueador obrigatório para as duas lojas** — depende do proprietário (conteúdo legal/jurídico, nome da empresa, contato de DPO) |
| Certificados/Provisioning Profiles Apple | Nenhum existe — depende de conta Apple Developer Program | 🔴 requer conta Apple Developer |
| Requisitos de Content Rating / Target Audience (Google Play) | Nunca preenchido — app tem conteúdo gerado por usuário (avaliações, fotos, comentários) | 🟡 depende de preenchimento no Console — informação já levantada nesta rodada (§5.3) |
| `.fvm`/versão do Flutter fixada | `3.44.6`, usada de forma consistente em `ci.yml`/`release.yml` via `flutter-version-file` | ✅ pronto |
| Fastlane / automação de submissão | Não existe | 🟡 melhoria futura opcional — não bloqueia a Beta/primeira publicação manual |

---

## 3. Fase 2 — Gap Analysis

| Item | Estado atual | Impacto | Ação necessária | Responsável |
|---|---|---|---|---|
| Keystore Android real | Inexistente | Bloqueia qualquer build assinada para a Play Store | Gerar com `keytool`, guardar em cofre, cadastrar 4 secrets no GitHub | Proprietário |
| Conta Apple Developer Program | Inexistente | Bloqueia assinatura iOS, TestFlight e App Store | Inscrever-se (Apple, taxa anual), configurar `DEVELOPMENT_TEAM` no Xcode | Proprietário |
| Projeto Supabase de Produção | Inexistente | Bloqueia qualquer build de Produção funcional (sem backend real) | Criar projeto no Dashboard, `supabase link` + `supabase db push` (replica as 31 migrations), configurar Storage (automático via migration), cadastrar Redirect URL `borah://password-recovery` | Proprietário (conta Supabase) |
| Secrets `SUPABASE_PROD_*`/`SENTRY_DSN_PRODUCTION`/`POSTHOG_API_KEY_PRODUCTION` no GitHub | Não cadastrados (workflow já sabe consumi-los, ver §4) | Builds de Release continuam "vazias" até serem cadastrados | Cadastrar em Settings → Environments → `production` | Proprietário |
| Projeto Sentry de Produção | Inexistente (só a infraestrutura de código, RC-03A) | Sem captura de crash em Produção | Criar projeto Sentry, obter DSN | Proprietário (conta Sentry) |
| Projeto PostHog de Produção | Inexistente (só a infraestrutura de código, RC-03C) | Sem analytics em Produção | Criar projeto PostHog, obter token | Proprietário (conta PostHog) |
| Política de Privacidade / Termos de Uso | Inexistente | **Bloqueador de submissão nas duas lojas** — Google Play e App Store exigem URL pública ativa | Redigir conteúdo (jurídico/legal — nome da empresa, contato de DPO, base legal LGPD) e hospedar publicamente | Proprietário (decisão de negócio/jurídica — fora do escopo de código) |
| Screenshots de loja / feature graphic | Inexistentes | Bloqueia publicação (obrigatório nos dois consoles) | Capturar em dispositivo/emulador real, a partir de uma build de Produção funcional | Proprietário/QA, após backend de Produção existir |
| Data Safety (Google Play) / App Privacy (App Store) | Nunca preenchido | Bloqueia submissão | Preencher os formulários usando o inventário já levantado (§5.3) | Proprietário (posse das contas de loja) |
| Content Rating / Target Audience | Nunca preenchido | Bloqueia submissão (Google Play) | Preencher questionário (app tem UGC — avaliações, fotos, comentários) | Proprietário |
| Workflow de Release sem `--dart-define`/keystore/job iOS | Corrigido nesta rodada | — | — | Concluído (BETA-03) |
| `DEVELOPMENT_TEAM` iOS | Ausente | Bloqueia qualquer assinatura/arquivamento real no Xcode | Preencher no Xcode assim que a conta existir | Proprietário |
| Suítes pgTAP de RLS (RC-04A/RC-04B) | Nunca executadas (falta Docker) | Sem validação automatizada de RLS antes de ir para Produção | Rodar `supabase test db --local` num ambiente com Docker | Proprietário/Engenharia (infraestrutura local) |
| Fastlane / submissão automatizada | Inexistente | Submissão manual via Console/Connect (aceitável para a primeira publicação) | Opcional, rodada futura | Engenharia (decisão de investimento) |

---

## 4. Fase 3 — Implementação

Alterações restritas a infraestrutura que **não depende de contas externas, não publica nada e não usa nenhum segredo real** — todas testadas localmente por sintaxe/leitura, já que nenhuma ferramenta com acesso à nuvem de Actions está disponível nesta sessão (mesma limitação já registrada desde a QA-03).

### 4.1 `.github/workflows/release.yml`

- **Decodificação da keystore Android**: novo passo "Decode Android release keystore" no job `build_release`, condicional (`if: secrets.ANDROID_KEYSTORE != ''`) — decodifica o Base64 para `android/release.jks` e escreve `android/key.properties`, nunca imprimindo valores em log. Sem o secret cadastrado, o passo é pulado e o comportamento permanece idêntico ao anterior (assinatura de debug, via o fallback já existente em `build.gradle.kts`).
- **Injeção de variáveis de Produção**: `flutter build apk --release`/`flutter build appbundle --release` agora recebem `--dart-define=SUPABASE_URL`/`SUPABASE_ANON_KEY`/`SENTRY_DSN`/`POSTHOG_API_KEY`/`APP_ENVIRONMENT=production`, lidos dos novos secrets `SUPABASE_PROD_URL`/`SUPABASE_PROD_ANON_KEY`/`SENTRY_DSN_PRODUCTION`/`POSTHOG_API_KEY_PRODUCTION`. Sem os secrets cadastrados, cada `--dart-define` chega vazio — mesmo efeito de não passar nenhum (comportamento anterior a esta rodada), portanto **nenhuma regressão**.
- **Novo job `build_release_ios`** (`runs-on: macos-latest`): `flutter analyze` + `flutter test` + `flutter build ios --release --no-codesign` com os mesmos `--dart-define`. É um portão de qualidade (confirma que a build de Release compila para iOS) — **não gera IPA assinado nem publica no TestFlight**, já que isso exige certificados/`DEVELOPMENT_TEAM` reais (fora do escopo desta rodada, "não inventar certificados"). Custo de runner macOS documentado em `CI_CD_SECRETS.md` §2 (roda só em tag/disparo manual, não em todo push).
- **`environment: production`** adicionado aos dois jobs — isola os secrets de Produção do Environment `qa` já existente, e permite (opcional, recomendado) exigir aprovação manual antes de qualquer execução.

### 4.2 `docs/operations/CI_CD_SECRETS.md`

- §2 atualizada: a decodificação da keystore, antes pendente, agora está implementada — só falta cadastrar os 4 secrets já documentados.
- **Nova §2.1**: secrets de ambiente de Produção (`SUPABASE_PROD_URL`, `SUPABASE_PROD_ANON_KEY`, `SENTRY_DSN_PRODUCTION`, `POSTHOG_API_KEY_PRODUCTION`), mesmo formato das tabelas já existentes.
- **Nova §3.1.1**: instruções para criar o Environment `production` no GitHub (Settings → Environments), com "Required reviewers" recomendado.

### 4.3 O que foi deliberadamente **não** implementado nesta rodada

- Nenhuma keystore, certificado ou credencial foi gerada, simulada ou inventada.
- Nenhum projeto Supabase/Sentry/PostHog de Produção foi criado (sem acesso a essas contas).
- Nenhuma automação Fastlane — exigiria um Match/API key da App Store Connect (segredos reais), fora do escopo "sem segredos reais".
- Nenhuma mudança em `.env.example` — o arquivo já documenta todas as variáveis necessárias para qualquer ambiente, inclusive Produção; não há necessidade de um `.env.production.example` separado.

---

## 5. Fase 4 — Checklist Operacional

Passo a passo para o proprietário concluir a configuração fora deste chat. Cada bloco é independente — pode ser executado em qualquer ordem, exceto onde indicado.

### 5.1 Google Play Console

1. Criar a conta de desenvolvedor (taxa única) em [play.google.com/console](https://play.google.com/console), se ainda não existir.
2. Criar o app com `applicationId` = `com.borah.app` (já configurado no projeto).
3. Preencher a ficha da loja: nome, descrição curta/completa, categoria, ícone (usar `app/assets/borah/platform/android/google_play/BORAH_google_play_512.png`, já preparado na IV-09), screenshots (pendente — ver §2, precisa de build de Produção funcional).
4. Preencher **Data Safety** usando o inventário da §5.3 abaixo.
5. Preencher **Content Rating** (questionário da IARC) — app tem conteúdo gerado por usuário (avaliações, fotos, comentários), sem chat privado nem compras.
6. Informar a **URL da Política de Privacidade** (bloqueador — ver §5.5).
7. Gerar a keystore de release e cadastrar os 4 secrets `ANDROID_KEYSTORE*` no GitHub (ver `CI_CD_SECRETS.md` §2).
8. Criar uma faixa de **Internal Testing**, adicionar testadores por e-mail, fazer upload do `.aab` gerado por `release.yml` (após os secrets acima existirem).

### 5.2 Apple Developer Program + App Store Connect

1. Inscrever-se no Apple Developer Program (taxa anual).
2. Configurar `DEVELOPMENT_TEAM` em `ios/Runner.xcodeproj` (via Xcode, `Signing & Capabilities`) com o Team ID da conta.
3. Criar o app em App Store Connect com bundle ID `com.borah.app`.
4. Preencher **App Privacy** usando o inventário da §5.3.
5. Informar a **URL da Política de Privacidade** (bloqueador — ver §5.5) e Termos de Uso (EULA), se aplicável.
6. Gerar o certificado de distribuição e o provisioning profile (via Xcode ou App Store Connect).
7. Arquivar e exportar o build assinado no Xcode Organizer (`Product → Archive → Distribute App → App Store Connect`) — o job `build_release_ios` do CI só valida que a build compila, não substitui este passo manual.
8. Enviar o build ao **TestFlight**, adicionar testadores internos/externos.

### 5.3 Inventário de dados coletados (para os formulários acima)

Levantado a partir do código real (não é suposição):

| Dado | Onde é coletado | Finalidade | Compartilhado com terceiros? |
|---|---|---|---|
| E-mail e senha | Supabase Auth (cadastro/login) | Autenticação | Não (fica no Supabase, backend próprio) |
| Nome, foto de perfil | `image_picker` (galeria) + Supabase Storage (`avatars`) | Funcionalidade do perfil | Não |
| Avaliações, fotos de avaliação, comentários | Formulários do app + Supabase Storage (`review-photos`) | Conteúdo principal do produto (UGC) | Não |
| Identificador técnico (UUID) do usuário | `PostHog.identify()` | Analytics de produto | Sim — PostHog (processador, não terceiro para fins de anúncio; nenhum dado de identificação pessoal é enviado, ver RC-03C) |
| Eventos de uso (nomes de tela/ação, nunca texto livre) | `AppAnalytics` (PostHog) | Analytics de produto | Sim — PostHog |
| Relatórios de erro/crash (com e-mail/token/JWT redigidos) | Sentry (`SentryEventSanitizer`) | Estabilidade/observabilidade | Sim — Sentry |
| Localização | **Não coletada** — nenhum uso de geolocalização no código | — | — |
| Câmera | **Não usada** — só seleção de galeria | — | — |
| Contatos/telefone | **Não coletados** | — | — |

Nenhum dado é vendido ou compartilhado para fins de publicidade — Sentry e PostHog são processadores de dados (infraestrutura própria do produto), não terceiros de anúncio.

### 5.4 Supabase de Produção

1. Criar um novo projeto no Dashboard do Supabase (ex.: `borah-prod`), região apropriada.
2. `supabase link --project-ref <ref-do-projeto-prod>` e `supabase db push` — replica as 31 migrations (schema, RLS, os 3 buckets de Storage com suas policies) automaticamente. **Nunca rodar `supabase db seed`** neste projeto — os seeds existentes são dados fictícios de desenvolvimento.
3. Cadastrar `borah://password-recovery` em **Authentication → URL Configuration → Redirect URLs** (pendência já registrada desde a RC-04E).
4. Obter `SUPABASE_URL`/`anon key` em **Project Settings → API** e cadastrar como `SUPABASE_PROD_URL`/`SUPABASE_PROD_ANON_KEY` no GitHub (Environment `production`).
5. Rodar as suítes pgTAP (`supabase/tests/database/`) localmente contra o projeto (requer Docker) antes de considerar o ambiente validado — mesma suíte já preparada na RC-04A/RC-04B, nunca executada por falta de Docker neste ambiente.

### 5.5 Política de Privacidade e Termos de Uso (bloqueador)

**Nenhum documento existe hoje.** É pré-requisito obrigatório para a submissão em ambas as lojas (URL pública ativa). Como envolve decisões jurídicas (razão social, jurisdição, contato de DPO/encarregado LGPD, prazos de retenção), este documento não foi redigido nesta rodada — é uma decisão de conteúdo/negócio do proprietário, não uma tarefa de infraestrutura de código. O inventário de dados da §5.3 pode servir de insumo direto para o conteúdo. Posso ajudar a redigir o texto numa rodada futura, mediante essas informações.

### 5.6 Sentry (Produção)

1. Criar um novo projeto Sentry (plataforma Flutter), separado do que eventualmente for usado por QA.
2. Obter o DSN e cadastrar como `SENTRY_DSN_PRODUCTION` no GitHub (Environment `production`).
3. Nenhuma mudança de código necessária — `AppEnvironment.sentryDsn` já lê de `--dart-define` (RC-03A).

### 5.7 PostHog (Produção)

1. Criar um novo projeto PostHog, separado de QA/Development.
2. Obter o Project API Key e cadastrar como `POSTHOG_API_KEY_PRODUCTION` no GitHub (Environment `production`).
3. Nenhuma mudança de código necessária — `AppEnvironment.postHogApiKey` já lê de `--dart-define` (RC-03C).

### 5.8 GitHub (resumo dos secrets a cadastrar)

Ver `CI_CD_SECRETS.md` §2/§2.1/§3.1.1 para o detalhamento completo: 4 secrets de keystore Android + 4 secrets de ambiente de Produção, todos no Environment `production` (novo).

---

## 6. Validação

- `flutter analyze`: sem nenhum problema.
- `dart format --set-exit-if-changed .`: sem alterações.
- `flutter test`: **503/503** — nenhuma regressão (nenhum código de app foi alterado nesta rodada, só workflows/documentação).

---

## 7. Arquivos criados

- `docs/FASE 9 - Execution/BETA-03_PRODUCTION_STORE_PREPARATION.md` (este documento)

## 8. Arquivos modificados

- `.github/workflows/release.yml` — decodificação de keystore Android (condicional), `--dart-define` de Produção nas builds Android, novo job `build_release_ios` (compile-check, sem assinatura), `environment: production` em ambos os jobs.
- `docs/operations/CI_CD_SECRETS.md` — nova §2.1 (secrets de Produção), nova §3.1.1 (Environment `production`), §2 atualizada (decodificação implementada).

## 9. Pendências restantes (todas operacionais, nenhuma de código)

Consolidadas em detalhe na §3 (Gap Analysis) e §5 (Checklist): keystore Android real, conta Apple Developer + `DEVELOPMENT_TEAM`, projeto Supabase de Produção, projetos Sentry/PostHog de Produção, os 8 secrets do GitHub (Environment `production`), screenshots/feature graphic (dependem de build de Produção funcional), Data Safety/App Privacy/Content Rating (inventário já pronto, só falta preencher), e — o único item classificado como bloqueador direto de submissão — **Política de Privacidade e Termos de Uso**, ainda inexistentes.
