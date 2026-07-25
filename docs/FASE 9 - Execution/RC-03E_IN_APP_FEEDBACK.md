# RC-03E — Feedback In-App

**Data:** 2026-07-25
**Branch:** `feature/rc-03e-in-app-feedback`
**Status:** Implementado — infraestrutura completa + integração mínima de UI (ver §9)
**Escopo:** exclusivamente o sistema de envio de feedback dentro do app. Analytics (RC-03C), Crash Reporting (RC-03A), Logging (RC-03B), Feature Flags (RC-03D) e Segurança são itens separados do backlog e não foram tocados nesta rodada (com exceção de um refactor pontual e sem mudança de comportamento em `pii_redaction.dart`/`analytics_property_sanitizer.dart`, ver §5).

Com esta rodada, a **RC-03 (Observability trio + flags + feedback)** está completa: RC-03A (Crash Reporting) → RC-03B (Structured Logging) → RC-03C (Product Analytics) → RC-03D (Feature Flags) → RC-03E (Feedback In-App).

---

## 1. Objetivo

Dar ao BORAH uma infraestrutura completa de envio de feedback dentro do app — mesmo padrão arquitetural de `CrashReporting`/`AppLogger`/`AppAnalytics`/`AppFeatureFlags` (RC-03A/B/C/D): desacoplada, nenhuma tela toca o Supabase diretamente, e testável sem depender do SDK/plugin real.

---

## 2. Arquitetura

```
lib/core/feedback/
├── feedback_model.dart              # modelo de domínio FeedbackModel
├── feedback_repository.dart         # interface FeedbackRepository + FeedbackRepositoryException
├── supabase_feedback_repository.dart# única classe que consulta a tabela `feedback`
├── feedback_sanitizer.dart          # sanitizeFeedbackMessage() — reaproveita pii_redaction.dart
├── feedback_service.dart            # orquestra repository + sanitização + versão do app cacheada
├── feedback_providers.dart          # Providers Riverpod + FeedbackController (reativo)
├── app_feedback.dart                # fachada estática AppFeedback (API pública fora do Riverpod)
└── feedback_dialog.dart             # diálogo de envio (Design System), consumido pelas telas
```

```
Feature (SettingsPage, "Enviar feedback")
    ↓ abre
FeedbackDialog.show(context, userId: ..., screenContext: ...)
    ↓ usa (dentro do próprio diálogo)
FeedbackController (Riverpod)               ← estado: Initial/Submitting/SubmitSuccess/SubmitError
    ↓ delega para
FeedbackService                              ← sanitiza a mensagem, propaga exceções
    ↓ usa
FeedbackRepository (interface)
    ↓ implementado por
SupabaseFeedbackRepository                   ← única fronteira com a tabela `feedback`
```

### 2.1 Duas portas de entrada, mesmo backend

- **`FeedbackController`/`feedbackControllerProvider`** (Riverpod) — caminho recomendado dentro de widgets: expõe o ciclo completo de estados (`FeedbackInitial`/`FeedbackSubmitting`/`FeedbackSubmitSuccess`/`FeedbackSubmitError`) que o `FeedbackDialog` consome.
- **`AppFeedback`** (fachada estática) — mesma convenção de `AppLogger`/`CrashReporting`/`AppAnalytics`/`AppFeatureFlags`, para o raro caso de envio fora de uma árvore de widgets/`ProviderScope`. Ao contrário de `AppFeatureFlags` (cujos métodos nunca lançam), `AppFeedback.submit()` propaga `FeedbackRepositoryException` — quem chama por este caminho é responsável por tratar a falha.

### 2.2 Diferença deliberada de filosofia de erro em relação a Feature Flags (RC-03D)

`FeatureFlagService.load()`/`.refresh()` **nunca lançam**, porque carregar flags acontece em background, sem nenhuma UI aguardando o resultado de forma síncrona. `FeedbackService.submit()` faz o oposto: **deixa a exceção se propagar**. Existe sempre um diálogo real aguardando o resultado com estados de carregando/sucesso/erro (ver §6) — silenciar a falha tornaria "estados de erro" e "permitir nova tentativa" (exigidos nesta rodada) impossíveis de atender. Só a camada Riverpod (`FeedbackController`) captura a exceção e a traduz para `FeedbackSubmitError`, exatamente como `AuthController` já faz para login/cadastro/logout.

---

## 3. Banco de dados

Migration `supabase/migrations/20260725110000_create_feedback.sql`:

```sql
create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  message text not null,
  screen_context text,
  app_version text,
  environment text,
  status text not null default 'new' check (status in ('new', 'reviewed', 'resolved')),
  created_at timestamptz not null default now()
);
```

- **RLS SELECT**: o próprio autor (`feedback_select_own`, `auth.uid() = user_id`) **ou** um administrador (`feedback_select_admin`, `public.is_admin(auth.uid())`) — as duas policies são permissivas e se somam (mesmo padrão de `comment_reports_select_own`/`comment_reports_select_admin`). Nenhum usuário comum enxerga feedback de outro usuário.
- **RLS INSERT**: somente o próprio usuário, e só em nome de si mesmo (`feedback_insert_own`, `with check (auth.uid() = user_id)`).
- **UPDATE/DELETE**: não implementados nesta rodada — registro imutável, mesma decisão já usada em `comment_reports` antes de existir um painel de triagem. Uma policy de `UPDATE` para administradores (mudar `status`) fica para quando houver um painel real.
- **GRANT**: concedido já nesta mesma migration (`grant select, insert on public.feedback to authenticated;`) — não deixado para uma correção posterior, lição já registrada da migration `20260720130000_grant_authenticated_privileges.sql`.
- **Estrutura pensada para expansão futura**: `status` já existe (default `'new'`) para permitir um fluxo de triagem futuro sem migration adicional; `screen_context`/`app_version`/`environment` dão contexto técnico sem precisar de uma tabela separada.

---

## 4. Interface

Infraestrutura mínima de envio, conforme pedido — sem painel administrativo, sem listagem de feedbacks:

- **`FeedbackDialog`** (`lib/core/feedback/feedback_dialog.dart`): campo de texto multilinha (`AppTextField` estendido, ver §5.1) com contador de caracteres (limite de 500), botão "Enviar", botão "Cancelar", indicador de carregamento (substitui o botão "Enviar" durante o envio) e mensagem de erro inline com possibilidade de nova tentativa (basta tocar "Enviar" novamente).
- Construído inteiramente com componentes do Design System (`AppDialog`, `AppTextField`, `AppTextButton`) — nenhum `Material`/`TextFormField` cru.
- `FeedbackDialog.show(context, {required userId, screenContext})` é a API pública — `userId` é sempre fornecido por quem chama (ver §4.1).

### 4.1 `userId` como parâmetro explícito (layering)

`core/` nunca importa `features/` — e `currentUserIdProvider` vive em `features/authentication/`. Por isso `FeedbackDialog`/`FeedbackController.submit()`/`AppFeedback.submit()` recebem `userId` como parâmetro obrigatório, em vez de resolvê-lo sozinhos. Quem abre o diálogo (`SettingsPage`, ver §9) é responsável por ler `currentUserIdProvider` e repassar o valor.

---

## 5. Privacidade

`sanitizeFeedbackMessage()` (`lib/core/feedback/feedback_sanitizer.dart`) roda sobre a mensagem antes de qualquer envio ao Supabase, redigindo JWT, e-mail e telefone. Nunca envia senha, refresh token ou qualquer outro dado sensível.

### 5.1 Reaproveitamento da infraestrutura de sanitização existente

Em vez de duplicar as regras de redação uma terceira vez, a rodada promoveu a redação de telefone (até então privada em `analytics_property_sanitizer.dart`, RC-03C) para o módulo compartilhado `lib/core/observability/pii_redaction.dart`, como uma função separada e opt-in:

```dart
// pii_redaction.dart — RC-03A (JWT/e-mail) + RC-03E (telefone, extraído)
String redactSensitiveText(String input) { ... }        // JWT + e-mail — usado por Sentry, Analytics e Feedback
String redactPhoneNumbers(String input) { ... }          // opt-in — usado por Analytics e Feedback, NÃO pelo Sentry
```

`redactPhoneNumbers` é deliberadamente **separada** de `redactSensitiveText` (não foi fundida) para não alterar o comportamento já publicado do sanitizador do Sentry (RC-03A), que nunca aplicou essa regra. `analytics_property_sanitizer.dart` foi refatorado para delegar a esta função compartilhada em vez de manter sua própria cópia privada — comportamento externo idêntico, verificado reexecutando os 6 testes existentes de `analytics_property_sanitizer_test.dart` sem nenhuma alteração de expectativa. `feedback_sanitizer.dart` (novo, RC-03E) encadeia as duas funções compartilhadas; por operar sobre uma mensagem de texto livre único (não um mapa de propriedades), não precisa de nenhuma verificação de chave sensível.

### 5.2 Extensão do Design System

`AppTextField` (`lib/design_system/components/inputs/app_text_field.dart`) ganhou dois parâmetros opcionais e retrocompatíveis: `maxLines` (padrão `1`, preserva o comportamento anterior) e `maxLength` (padrão `null`, sem contador). Único componente do Design System alterado nesta rodada — necessário porque não existia nenhum campo multilinha com contador antes da RC-03E.

---

## 6. Estados (Riverpod)

| Estado | Quando |
|---|---|
| `FeedbackInitial` | Estado inicial e após `reset()` |
| `FeedbackSubmitting` | Enquanto o envio está em andamento |
| `FeedbackSubmitSuccess(feedback)` | Envio concluído com sucesso |
| `FeedbackSubmitError(message)` | Falha — mensagem amigável, permite nova tentativa |

`FeedbackDialog` chama `reset()` a cada abertura (via `addPostFrameCallback` no `initState`), garantindo que nunca reaproveita um estado de sucesso/erro de um envio anterior no mesmo app.

---

## 7. Decisão arquitetural: versão do app resolvida uma única vez no bootstrap

Esta é a única decisão arquitetural desta rodada que exigiu pausa e aprovação explícita antes de prosseguir.

**Desenho original (descartado):** `FeedbackService.submit()` chamava `PackageInfo.fromPlatform()` a cada envio, para anexar a versão do app ao feedback.

**Problema encontrado:** ao escrever o teste de widget do `FeedbackDialog`, o envio bem-sucedido travava indefinidamente em `pumpAndSettle()`. Isolando a causa com um teste de depuração dedicado (chamando só `PackageInfo.fromPlatform()` dentro de um `testWidgets()`), confirmou-se que a chamada **nunca resolve nem lança** nesse contexto — diferente de uma chamada dentro de um `test()` puro (onde falha rápido e é capturada) e diferente do comportamento do PostHog (RC-03C), que lança `MissingPluginException` prontamente em qualquer contexto de teste. `AppAnalytics` nunca esbarrou nisso porque `_readAppVersion()` só roda dentro de `initialize()`, e nenhum teste (unitário ou de widget) chama `AppAnalytics.initialize()` — os testes de `AppAnalytics` exercitam só `trackXxx()`, que lê um campo já em cache.

**Correção aplicada:** a leitura da versão do app foi movida para fora do caminho de envio, replicando exatamente o padrão já usado por `AppAnalytics`/`AppFeatureFlags`:

- `FeedbackService.initializeAppVersion()` (estático) chama `PackageInfo.fromPlatform()` **uma única vez** e cacheia o resultado num campo estático (`_appVersion`), compartilhado por toda instância de `FeedbackService` — tanto a criada pelo Riverpod (`feedbackServiceProvider`) quanto a da fachada estática (`AppFeedback`). Diferente de Feature Flags (onde cada porta de entrada mantém seu próprio cache, porque flags podem legitimamente divergir em atualidade), a versão do app é um valor único e imutável para todo o processo — compartilhar o cache é estritamente mais correto, não uma simplificação.
- `AppFeedback.initialize()` chama `FeedbackService.initializeAppVersion()` e é invocado uma única vez em `main.dart`, ao lado de `AppAnalytics.initialize()`/`AppFeatureFlags.initialize()` (`unawaited`, não bloqueia o boot — nenhum feedback pode ser enviado antes da primeira tela carregar).
- `FeedbackService.submit()` nunca mais toca `PackageInfo` — apenas lê o campo estático já resolvido.

**Benefícios:**
- **Testabilidade**: nenhum teste (unitário ou de widget) precisa mais tocar o plugin `package_info_plus`; o travamento de `pumpAndSettle()` desaparece pela raiz, não por um workaround de teste.
- **Desempenho**: elimina uma consulta ao plugin de plataforma a cada envio de feedback em produção — a versão do app não muda durante a execução do processo, então lê-la repetidamente nunca trouxe benefício algum.
- **Isolamento de dependências**: `FeedbackService.submit()` (o caminho exercitado por toda UI/teste de integração) fica livre de qualquer chamada a plugin de plataforma; o único ponto de contato com `PackageInfo` é `initializeAppVersion()`, chamado uma única vez, fora do caminho crítico da interação do usuário.

Nenhuma outra parte da estrutura aprovada (`FeedbackModel`, `FeedbackRepository`, `SupabaseFeedbackRepository`, providers/controller, `AppFeedback`, RLS, sanitização, diálogo) foi alterada por esta correção — apenas onde e quando a versão do app é lida.

---

## 8. Offline / Supabase indisponível

- `SupabaseFeedbackRepository.submit()` traduz qualquer `PostgrestException` (rede, Supabase fora do ar, RLS) em `FeedbackRepositoryException`.
- `FeedbackService.submit()` deixa essa exceção se propagar (ver §2.2) — `FeedbackController` a captura e expõe `FeedbackSubmitError` com uma mensagem amigável.
- `FeedbackDialog` nunca trava o app: mostra a mensagem de erro inline e permite nova tentativa a qualquer momento (basta tocar "Enviar" de novo) — exatamente como pedido.

---

## 9. O que foi (e o que não foi) integrado nesta rodada

**Feito nesta rodada:**
- Toda a estrutura de código listada em §2, incluindo o diálogo de envio (diferente de RC-03A–D, que foram infraestrutura pura sem nenhuma tela tocada).
- Migration com tabela, RLS (própria + admin), GRANT.
- `main.dart`: `AppFeedback.initialize()` (fire-and-forget, não bloqueia o bootstrap).
- **Integração mínima de UI** (decisão de escopo, não pedida literalmente): um item "Enviar feedback" foi adicionado a `SettingsPage`, entre "Editar perfil" e "Sair", abrindo `FeedbackDialog` com o `userId` lido de `currentUserIdProvider` e `screenContext: 'settings'`. Diferente das RC-03A–D (infraestrutura pura), a RC-03E pede explicitamente uma UI funcional com estados reais de carregando/sucesso/erro — um diálogo que nenhuma tela jamais abre não constitui um "sistema" de feedback. Esta é a única decisão de escopo desta rodada que vai além de "só infraestrutura"; nenhuma outra tela foi tocada.

**Não feito nesta rodada (explicitamente fora de escopo):**
- Nenhum painel administrativo de feedback.
- Nenhuma listagem de feedbacks (nem para o próprio usuário, nem para administradores).
- Nenhuma policy de `UPDATE`/`DELETE` (ex.: mudar `status` para `reviewed`/`resolved`) — fica para quando houver um painel de triagem real.
- Nenhuma alteração de Analytics, Crash Reporting, Feature Flags ou Segurança, além do refactor de sanitização compartilhada descrito em §5.1 (sem mudança de comportamento, coberto por teste de regressão).

---

## 10. Testes

| Arquivo | Cobertura |
|---|---|
| `test/unit/core/feedback/feedback_model_test.dart` | `FeedbackModel.fromMap` — linha completa e campos opcionais nulos |
| `test/unit/core/feedback/feedback_sanitizer_test.dart` | JWT, e-mail, telefone redigidos; mensagem sem dado sensível inalterada |
| `test/unit/core/feedback/feedback_service_test.dart` | Sanitização repassada ao repositório; `userId`/`screenContext` inalterados; `appVersion` nulo antes de `initializeAppVersion()`; `initializeAppVersion()` nunca lança; propagação de `FeedbackRepositoryException` |
| `test/unit/core/feedback/feedback_providers_test.dart` | `FeedbackController`: estado inicial, `submit()` sucesso/falha (exceção tipada e genérica), `reset()` |
| `test/unit/core/feedback/app_feedback_test.dart` | Fachada estática: `initialize()` nunca lança, `submit()` delega e propaga exceção |
| `test/widget/feedback/feedback_dialog_test.dart` | Campo/contador visíveis; envio com mensagem vazia não chama o repositório; envio bem-sucedido (carregando → fecha o diálogo → snackbar); falha mantém o diálogo aberto e permite nova tentativa; cancelar não chama o repositório |

**Nota de teste**: `SupabaseFeedbackRepository` não é testado diretamente contra um `SupabaseClient` real (mesma decisão já tomada para `PostHogAnalyticsService`/`SupabaseFeatureFlagRepository`) — os testes de `FeedbackService`/`FeedbackController`/`AppFeedback` usam um `FeedbackRepository` mockado via `mocktail`. A cobertura de RLS é validada estaticamente pela migration (`feedback_select_own`/`feedback_select_admin`/`feedback_insert_own`, ver §3) e pelo mesmo padrão já usado em `comment_reports`, não por um teste de integração contra um Supabase real (ver AR-06/EX-01B — sem tooling de integração disponível neste ambiente).

Suíte completa do projeto (`flutter test`): **400/400**, zero regressão (baseline anterior: 376/376 + 24 novos testes desta rodada).

---

## 11. Limitações desta rodada

- Nenhuma listagem/painel de feedback — só envio, como pedido.
- Único ponto de integração de UI é `SettingsPage` (ver §9) — nenhuma outra tela oferece o atalho para enviar feedback.
- Sem policy de `UPDATE`/`DELETE` — registro imutável nesta rodada.
- `SupabaseFeedbackRepository` não validado contra uma instância real do Supabase/Postgres (mesma limitação já registrada em todas as migrations do projeto, ver AR-06/EX-01B).
