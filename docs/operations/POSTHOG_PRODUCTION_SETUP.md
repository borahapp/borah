# PostHog de Produção — Guia de Configuração

**Contexto:** BETA-08C/BETA-08C1. Complementa `docs/operations/CI_CD_SECRETS.md` §2.1 com o passo a passo operacional completo para provisionar o PostHog de Produção do BORAH. Nenhum valor real aparece neste documento — apenas placeholders e o formato esperado.

---

## 1. Criação do projeto

1. Acessar [posthog.com](https://posthog.com) → **New project**.
2. Nome sugerido: `borah-production` (para distinguir de um eventual projeto de QA/Beta futuro).
3. Plataforma: **Flutter/Mobile** (o SDK usado pelo app é `posthog_flutter`).

---

## 2. Escolha da região (US vs. EU)

| | US (recomendado, salvo exigência específica) | EU |
|---|---|---|
| Host de ingestão | `https://us.i.posthog.com` | `https://eu.i.posthog.com` |
| Compatibilidade com o código atual | É o `defaultValue` já hardcoded em `AppEnvironment.postHogHost` — nenhuma surpresa se o secret for preenchido corretamente | Requer que `POSTHOG_HOST_PRODUCTION` seja cadastrado com o valor EU (ver §5) |
| Quando escolher | Ausência de exigência específica de residência de dados | Só se houver uma exigência de negócio/compliance de processar analytics dentro da UE — **não é uma exigência da LGPD em si** |

BORAH é um app brasileiro (Supabase já hospedado em `sa-east-1`, São Paulo) — nem US nem EU ficam fisicamente perto do Brasil, então a diferença de latência entre as duas regiões do PostHog é marginal. A escolha é mais sobre preferência de residência de dados do que performance.

**Qualquer que seja a região escolhida, ela deve ser refletida corretamente no secret `POSTHOG_HOST_PRODUCTION` (§5) — nunca deixar esse valor vazio ou desatualizado (ver §5 para o motivo técnico).**

---

## 3. Obtenção da Project API Key

1. Dentro do projeto criado → **Project Settings → Project API Key**.
2. Copiar o valor — este é o `POSTHOG_API_KEY_PRODUCTION`.

---

## 4. Obtenção do Host

Determinado diretamente pela região escolhida no §2:
- US → `https://us.i.posthog.com`
- EU → `https://eu.i.posthog.com`

Não há uma página separada para "obter" esse valor — ele é fixo por região, não uma credencial gerada pelo PostHog.

---

## 5. Cadastro dos Environment Secrets no GitHub

**Settings → Environments → `production`** (criado na BETA-06) → **Add environment secret**, duas entradas:

| Secret | Valor |
|---|---|
| `POSTHOG_API_KEY_PRODUCTION` | A Project API Key do §3 |
| `POSTHOG_HOST_PRODUCTION` | `https://us.i.posthog.com` ou `https://eu.i.posthog.com`, conforme a região escolhida no §2 |

### Por que `POSTHOG_HOST_PRODUCTION` nunca pode ficar vazio

Diferente dos demais secrets de Produção (`SUPABASE_PROD_*`, `SENTRY_DSN_PRODUCTION`, `POSTHOG_API_KEY_PRODUCTION` — todos "seguros vazios", o app só fica sem aquela função até serem cadastrados), `release.yml` desde a BETA-08C1 passa `--dart-define=POSTHOG_HOST=${{ secrets.POSTHOG_HOST_PRODUCTION }}` **incondicionalmente**. Isso significa que a flag `--dart-define` está sempre presente na compilação — e o `defaultValue: 'https://us.i.posthog.com'` de `AppEnvironment.postHogHost` só é usado pelo Dart quando a flag está **ausente**, nunca quando está presente com valor vazio. Um `POSTHOG_HOST_PRODUCTION` nunca cadastrado (ou cadastrado vazio por engano) faz o app receber uma string vazia como host — e como o `PostHogAnalyticsService` engole todo erro silenciosamente por design (RC-03C), essa falha **nunca aparece em nenhum log**, resultando em analytics de Produção completamente silencioso sem nenhum sintoma visível além de um dashboard vazio.

**Regra prática: assim que o projeto PostHog de Produção existir, cadastrar `POSTHOG_HOST_PRODUCTION` no mesmo momento que `POSTHOG_API_KEY_PRODUCTION` — nunca um sem o outro.**

---

## 6. Validação da integração

1. Disparar `release.yml` manualmente (`workflow_dispatch`) e confirmar que os dois jobs (`build_release`, `build_release_ios`) concluem sem erro — a compilação sozinha não prova que os valores chegaram certos, já que são lidos só em runtime.
2. Validação real, sem impactar usuários reais (mesmo princípio já usado para validar o Sentry, BETA-08B): rodar localmente, num dispositivo pessoal, nunca distribuído:
   ```bash
   flutter run --release \
     --dart-define=POSTHOG_API_KEY=<Project API Key real> \
     --dart-define=POSTHOG_HOST=<host correspondente à região escolhida> \
     --dart-define=APP_ENVIRONMENT=production \
     --dart-define=SUPABASE_URL=<URL de Produção> \
     --dart-define=SUPABASE_ANON_KEY=<chave de Produção>
   ```
3. Usar o app normalmente por alguns instantes (abrir a tela inicial já dispara `app_open`; fazer login/cadastro dispara os eventos já conectados).
4. No dashboard do PostHog (**Activity** ou **Live events**), confirmar que os eventos chegam, com `environment: production` nas propriedades.

---

## 7. Dashboards recomendados

1. **Funil de Ativação** — `signup` → `app_open` → `review_created`. Mede se um novo usuário chega a criar a primeira avaliação, o núcleo da proposta de valor do BORAH.
2. **Retenção D1/D7** — baseada em `app_open` recorrente por usuário identificado.
3. **Taxa de sucesso de upload** — `photo_uploaded`, com `success` como *breakdown* (avatar vs. review, sucesso vs. falha).
4. **Monitor de exclusão de conta** — `account_deleted` ao longo do tempo, com alerta configurado para picos incomuns (sinal de churn ou de um problema mais sério).

---

## 8. Métricas recomendadas para os primeiros dias do Beta

- **Diárias**: `app_open` (DAU), `signup` vs. `login_success` (novos vs. recorrentes), `login_failed` (taxa de erro de autenticação), `account_deleted` (qualquer volume num Beta Fechado pequeno merece investigação individual imediata).
- **Sinal de problema de adoção**: `app_open` sem `review_created`/`restaurant_favorited` correspondente (usuários abrindo o app sem interagir); `search_performed` sem `restaurant_viewed` na sequência.
- **Sinal de problema técnico**: `login_failed` com volume anormal; `photo_uploaded` com `success: false` em proporção alta; ausência total de eventos de uma versão/dispositivo específico (cruzar com o Sentry).

---

## 9. Checklist pós-configuração

- [ ] Projeto PostHog de Produção criado, região decidida e documentada.
- [ ] `POSTHOG_API_KEY_PRODUCTION` cadastrado no Environment `production`.
- [ ] `POSTHOG_HOST_PRODUCTION` cadastrado **no mesmo momento**, com o host exato da região escolhida — nunca vazio.
- [ ] `release.yml` disparado manualmente pelo menos uma vez após o cadastro, sem erros.
- [ ] Validação local (§6) confirmada — eventos aparecem no dashboard **Activity**/**Live events** com `environment: production`.
- [ ] Os 4 dashboards recomendados (§7) criados no PostHog.
- [ ] Time responsável pelo Beta ciente das métricas diárias e dos sinais de alerta (§8).
