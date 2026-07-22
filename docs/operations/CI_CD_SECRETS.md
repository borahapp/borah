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
| `SUPABASE_QA_PROJECT_REF` | Ref do projeto `borah-qa` (`fgzokfkvccgkclkmfqui` — não é segredo em si, mas mantido como secret por consistência com os demais) | string alfanumérica de 20 caracteres | Mesma página acima, ou a própria URL |
| `SUPABASE_QA_SERVICE_ROLE_KEY` | Usada **somente** pelos helpers de Integration Test (`QaTestUserHelper`, `QaRestaurantHelper`, `QaSocialHelper`) para criar/remover dados de teste via Admin API/PostgREST, ignorando RLS | JWT legado (`eyJ...`) ou novo formato `sb_secret_...` (preferir o novo formato — ver pendência de rotação abaixo) | Dashboard → `borah-qa` → Project Settings → API → **nunca usar `--reveal` fora de uma sessão descartável** |

**Nunca** usar as chaves do `borah-development` ou de produção aqui — os workflows de CI existem exclusivamente para rodar contra `borah-qa`. `QaEnvironment.assertRunningAgainstQaProject()` já aborta a suíte se a URL não apontar para o ref correto, mas isso só é uma rede de segurança, não substitui cadastrar o secret certo.

**Pendência herdada da Rodada 0:** a `SERVICE_ROLE_KEY` do `borah-qa` foi exposta uma vez em texto completo durante o provisionamento (achado de segurança já registrado em `EX-10_FASE_6_QA_STATUS.md`). Recomenda-se **rotacionar** essa chave (Dashboard → Project Settings → API → Reset service_role key, preferindo o formato novo `sb_secret_...`) antes de cadastrá-la como secret de CI, caso ainda não tenha sido feito.

---

## 2. Secrets pendentes (Release assinado - fora do escopo desta rodada)

`android/app/build.gradle.kts` assina o `buildType.release` com a chave de **debug** (TODO original do template Flutter, nunca resolvido — achado da Rodada F). O workflow `.github/workflows/release.yml` já existe e gera artefatos, mas **não estão aptos para a Play Store** até que uma keystore de release seja configurada. Quando essa decisão for autorizada (fora do escopo desta rodada — exige alterar `build.gradle.kts`, código do aplicativo):

| Secret (futuro) | Finalidade | Formato esperado |
|---|---|---|
| `ANDROID_KEYSTORE` | Arquivo `.jks`/`.keystore` de release, codificado em Base64 | string Base64 (`base64 -w0 release.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | Senha da keystore | string |
| `ANDROID_KEY_ALIAS` | Alias da chave dentro da keystore | string |
| `ANDROID_KEY_PASSWORD` | Senha da chave (pode ser igual à da keystore) | string |

Uso típico: decodificar o Base64 em um arquivo temporário no início do job de release, apontar `signingConfigs.create("release")` para ele via `key.properties` gerado em tempo de execução (nunca versionado), e nunca imprimir nenhum desses valores em log.

---

## 3. Configuração manual recomendada no GitHub (não é código, feito pela UI)

Nenhum destes itens pode ser configurado por arquivo neste repositório — são ajustes de **Settings** do GitHub, cadastrados uma única vez por quem tem acesso administrativo.

### 3.1 Environment `qa`

**Settings → Environments → New environment → `qa`.**

- Adicionar os 4 secrets do §1 como *Environment secrets* (não *Repository secrets*) — isolam o acesso apenas aos jobs que declaram `environment: qa` (como `integration_test` em `ci.yml`).
- Opcional, recomendado quando o repositório passar a aceitar contribuições externas: marcar **"Required reviewers"** para exigir aprovação manual antes de qualquer job que use o Environment `qa` rodar em um Pull Request de fora do time.

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
