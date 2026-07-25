# RC-03C — Product Analytics

**Data:** 2026-07-25
**Branch:** `feature/rc-03c-product-analytics`
**Status:** Implementado — infraestrutura completa; wiring de eventos limitado ao ciclo de vida de autenticação (ver §9)
**Escopo:** exclusivamente a camada de Product Analytics (PostHog). Crash Reporting (RC-03A), Logging (RC-03B), Feature Flags, Feedback In-App e Segurança são itens separados do backlog e não foram tocados nesta rodada.

---

## 1. Objetivo

Dar ao BORAH uma camada de métricas de uso de produto (funis, retenção, eventos-chave), com uma interface própria que isola completamente o app do SDK de terceiros escolhido — mesma filosofia arquitetural de `CrashReporting` (RC-03A) e `AppLogger` (RC-03B).

---

## 2. Tecnologia

**PostHog** (`posthog_flutter ^5.33.0`), conforme recomendado na RC-02.5. Resolvido sem conflito de dependências (verificado via `flutter pub add --dry-run` antes de iniciar a implementação) — nenhum impedimento técnico encontrado.

---

## 3. Arquitetura

```
lib/core/analytics/
├── analytics_service.dart            # interface AnalyticsService (setup/track/identify/reset)
├── analytics_event.dart              # modelo canônico AnalyticsEvent
├── analytics_property_sanitizer.dart # sanitização de properties (reaproveita RC-03A + telefone)
├── posthog_analytics_service.dart    # único arquivo que importa package:posthog_flutter
└── app_analytics.dart                # fachada estática AppAnalytics (API pública)

lib/core/observability/
└── pii_redaction.dart                # NOVO (extraído do sanitizador do Sentry) — primitivas
                                       # de redação compartilhadas entre Sentry e Analytics
```

Nenhuma feature importa `analytics_service.dart`, `posthog_analytics_service.dart` nem `package:posthog_flutter` diretamente — tudo passa por `AppAnalytics`, uma fachada estática (`abstract final class`) que segue exatamente o mesmo padrão de `AppLogger`/`CrashReporting`:

```
Feature (ex.: AuthController)
    ↓ chama
AppAnalytics.trackLoginSuccess()          ← única API pública
    ↓ constrói
AnalyticsEvent (já sanitizado, com todos os campos padrão)
    ↓ delega para
AnalyticsService (interface)
    ↓ implementado por
PostHogAnalyticsService                   ← única fronteira com o SDK
    ↓ chama
Posthog().capture(...)
```

Trocar de provedor de Analytics no futuro significa escrever uma nova classe `implements AnalyticsService` e trocar uma linha em `AppAnalytics._defaultService` — nenhuma feature precisa mudar.

### 3.1 Reaproveitamento da infraestrutura de sanitização (RC-03A)

As primitivas de redação (padrão de JWT, e-mail, nomes de chave sensíveis) que antes viviam só dentro de `sentry_event_sanitizer.dart` foram extraídas para `lib/core/observability/pii_redaction.dart` — um arquivo novo, mas **sem nenhuma mudança de comportamento** no sanitizador do Sentry (os 7 testes existentes de `sentry_event_sanitizer_test.dart` continuam passando sem alteração, comprovando que a extração foi puramente um refactor).

`analytics_property_sanitizer.dart` importa essas primitivas e adiciona uma regra própria (redação de telefone), já que a política de privacidade de Analytics desta rodada inclui telefone e a do Sentry (RC-03A) não incluía — a extensão fica isolada no consumidor que precisa dela, sem alterar o comportamento do Sentry.

---

## 4. Eventos padronizados

Convenção de nomenclatura: `snake_case`, formato `substantivo_verbo` (ex.: `restaurant_viewed`, `review_created`).

| Método | Evento | Properties |
|---|---|---|
| `trackAppOpen()` | `app_open` | — |
| `trackLoginSuccess()` | `login_success` | — |
| `trackLoginFailed({reason})` | `login_failed` | `reason` (opcional) |
| `trackSignup()` | `signup` | — |
| `trackLogout()` | `logout` | — |
| `trackRestaurantViewed(id)` | `restaurant_viewed` | `restaurant_id` |
| `trackRestaurantFavorited(id)` | `restaurant_favorited` | `restaurant_id` |
| `trackRestaurantUnfavorited(id)` | `restaurant_unfavorited` | `restaurant_id` |
| `trackReviewCreated(id, {rating})` | `review_created` | `review_id`, `rating` (opcional) |
| `trackReviewUpdated(id)` | `review_updated` | `review_id` |
| `trackReviewDeleted(id)` | `review_deleted` | `review_id` |
| `trackCommentCreated(reviewId)` | `comment_created` | `review_id` |
| `trackCommentDeleted(id)` | `comment_deleted` | `comment_id` |
| `trackFeedOpened()` | `feed_opened` | — (`screen: feed`) |
| `trackRankingOpened()` | `ranking_opened` | — (`screen: rankings`) |
| `trackProfileViewed(profileUserId)` | `profile_viewed` | `profile_user_id` |
| `trackProfileUpdated()` | `profile_updated` | — |
| `trackSearchPerformed(query, {resultCount})` | `search_performed` | `query_length`, `result_count` (opcional) — **nunca o texto da busca** |
| `trackNotificationOpened(type)` | `notification_opened` | `notification_type` |

`track(eventName, {screen, properties})` também está disponível para casos sem método dedicado ainda — mas prefira sempre criar um método nomeado (ver §7).

---

## 5. Convenção de campos (padronização)

Todo `AnalyticsEvent` carrega:

| Campo | Origem |
|---|---|
| `name` | Passado pelo método `trackXxx()` |
| `timestamp` | `DateTime.now().toUtc()`, automático |
| `environment` | `AppEnvironment.environmentName` |
| `appVersion` | `PackageInfo.fromPlatform()`, lido uma vez em `AppAnalytics.initialize()` |
| `screen` | Passado explicitamente por alguns `trackXxx()` (ex.: `feed_opened` → `feed`) |
| `userId` | O último valor passado para `AppAnalytics.identify()`, `null` após `reset()` ou antes do primeiro `identify()` |
| `properties` | Específico de cada evento, já sanitizado |

---

## 6. Privacidade

`sanitizeAnalyticsProperties()` (aplicado em `AppAnalytics.track()`, antes de construir o `AnalyticsEvent`) garante que nenhuma `properties` carregue:

- Senha, JWT, refresh token, chave de API — qualquer valor cuja **chave** contenha esses termos vira `[REDACTED]`, não importa o conteúdo.
- E-mail completo, JWT ou telefone dentro de qualquer valor de texto livre — redigidos via regex.

Além disso, por design, nenhum método `trackXxx()` aceita ou envia o texto de busca do usuário (`trackSearchPerformed` só manda o **tamanho** da string), e `sendDefaultPii`-equivalente nunca é habilitado no PostHog (`Posthog().setup()` não usa nenhuma opção de coleta automática de PII).

---

## 7. Ambientes

| Ambiente | Envia eventos? |
|---|---|
| Development | **Não** — fica só o log local implícito (nenhum evento é construído/enviado; `AppAnalytics.isSendingEvents` retorna `false`) |
| QA | Sim (quando `POSTHOG_API_KEY` de QA for provisionado — hoje vazio, mesma situação do Sentry na RC-03A) |
| Beta | Sim |
| Production | Sim |

Implementado em `AppAnalytics.isSendingEvents` (`AppEnvironment.environmentName != 'development'`). Diferente do Logging (RC-03B), aqui não há uma escala de "quais eventos passam" por ambiente — é um corte binário (Development nunca envia; os demais sempre tentam enviar, mas `Posthog().setup()`/`.capture()` no-opam graciosamente sem um `POSTHOG_API_KEY` real configurado).

---

## 8. Boas práticas / como adicionar um novo evento

1. Escolha um nome em `snake_case`, formato `substantivo_verbo` (evite `verbo_substantivo`).
2. Adicione um método `trackXxx()` em `AppAnalytics` chamando `track('nome_do_evento', screen: ..., properties: {...})`.
3. Nunca inclua na `properties`: texto livre digitado pelo usuário (buscas, comentários, bio), e-mail, telefone, qualquer identificador que não seja um ID técnico (UUID) do próprio domínio.
4. Adicione um teste em `app_analytics_test.dart` seguindo o padrão já existente (usa `AppAnalytics.debugServiceOverride` com um `_RecordingAnalyticsService`).
5. Atualize a tabela da seção 4 deste documento.
6. Wire o novo `trackXxx()` no controller/página relevante — só depois de decidir onde ele realmente precisa disparar (não adicione instrumentação "especulativa").

---

## 9. O que foi (e o que não foi) instrumentado nesta rodada

Mesma disciplina de escopo já usada na RC-03A/RC-03B (construir a infraestrutura completa, testada, e só o wiring mínimo necessário para provar o padrão — não instrumentar o app inteiro numa única rodada de infraestrutura):

**Wired (ativo em código hoje):**
- `main.dart`: `AppAnalytics.initialize()` (lê a versão do app) + `trackAppOpen()`, no bootstrap.
- `AuthController.restoreSession()`: `identify(userId)` quando há sessão salva — é o caminho mais comum de abertura do app, e sem isso a maioria dos eventos ficaria sem `userId`.
- `AuthController.signUp()`: `identify(userId)` (quando a conta já nasce confirmada) + `trackSignup()`.
- `AuthController.signIn()`: `identify(userId)` + `trackLoginSuccess()` no sucesso; `trackLoginFailed(reason: ...)` nos dois ramos de falha.
- `AuthController.signOut()`: `trackLogout()` (antes) + `reset()` (depois, para o evento ainda carregar o `userId` de quem saiu).

**Prontos e testados, mas não conectados a nenhuma tela ainda:** os 14 métodos restantes (`trackRestaurantViewed`, `trackRestaurantFavorited/Unfavorited`, `trackReviewCreated/Updated/Deleted`, `trackCommentCreated/Deleted`, `trackFeedOpened`, `trackRankingOpened`, `trackProfileViewed/Updated`, `trackSearchPerformed`, `trackNotificationOpened`). Conectá-los exigiria tocar ~12+ arquivos de feature espalhados pelo app (cada tela/controller correspondente) — um escopo de "instrumentar o produto inteiro" bem maior que "construir a infraestrutura de Analytics", e que a RC-03A/RC-03B deliberadamente também não fizeram para seus respectivos domínios (nenhuma tela ganhou chamadas manuais de `AppLogger`/`CrashReporting.captureException` fora dos pontos de integração globais). Fica registrado aqui como trabalho de wiring pendente, a ser decidido como rodada própria se desejado.

Todos os 19 métodos, incluindo os 14 não conectados, estão implementados, com API estável e cobertos por teste — ativá-los depois é só adicionar a chamada no ponto certo do código, sem nenhuma mudança de arquitetura.

---

## 10. Testes

| Arquivo | Cobertura |
|---|---|
| `test/unit/core/analytics/analytics_event_test.dart` | Criação, `toMap()`, timestamp automático em UTC, imutabilidade de `properties` |
| `test/unit/core/analytics/analytics_property_sanitizer_test.dart` | Redação de JWT/e-mail/telefone/chaves sensíveis; valores normais preservados |
| `test/unit/core/analytics/app_analytics_test.dart` | Os 19 eventos produzem o nome/propriedades esperados; gating por ambiente; `identify`/`reset`; sanitização aplicada antes do envio |
| `test/unit/core/analytics/posthog_analytics_service_test.dart` | Função pura `flattenAnalyticsEventForPostHog` (achatamento para o formato de `properties` do PostHog) |

**Limitação de teste conhecida:** `Posthog()` lança `MissingPluginException` em ambiente de teste sem canal de plataforma registrado — diferente do `Hub` do Sentry (RC-03A), que é um no-op puro em Dart antes de `Sentry.init`. Por isso `PostHogAnalyticsService.setup/track/identify/reset` não são exercitados diretamente por teste unitário (só a função de achatamento, que é pura); a integração completa é validada via `AppAnalytics.debugServiceOverride`. Como resiliência adicional (não só para viabilizar teste, mas como boa prática de produção), toda chamada dentro de `PostHogAnalyticsService` está protegida por `try/catch` — uma falha do SDK de Analytics nunca deve derrubar nem atrasar o app.

---

## 11. Validação (checklist)

| Ambiente | Envia eventos? |
|---|---|
| Development | Não |
| QA | Sim (pendente de `POSTHOG_API_KEY` real) |
| Beta | Sim (pendente de `POSTHOG_API_KEY` real) |
| Production | Sim (pendente de `POSTHOG_API_KEY` real) |

Confirmado por teste automatizado (`app_analytics_test.dart`, grupo "comportamento por ambiente"): com `debugSendsEventsOverride = false`, nenhum evento/identify/reset chega ao serviço; com `= true`, todos chegam.

---

## 12. Limitações desta rodada

- Nenhum projeto PostHog real foi criado — `POSTHOG_API_KEY` vazio em todos os ambientes hoje (mesma situação do `SENTRY_DSN` na RC-03A). `Posthog().setup()` no-opa graciosamente até isso ser provisionado.
- 14 dos 19 eventos estão prontos mas não conectados a nenhuma tela (ver §9) — decisão deliberada de escopo, não uma lacuna técnica.
- Autocaptura nativa do PostHog (lifecycle events, error tracking, session replay, surveys) foi explicitamente desabilitada em `PostHogAnalyticsService.setup()` para não haver ambiguidade sobre qual sistema está de fato instrumentando o quê (Analytics só via `AppAnalytics`; crash reporting só via Sentry/RC-03A).
- Nenhuma tela de consentimento/opt-out de Analytics foi criada — fora do escopo desta rodada (item de LGPD/Privacidade, RC-04).
