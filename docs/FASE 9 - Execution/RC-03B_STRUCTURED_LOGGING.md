# RC-03B — Logging Estruturado

**Data:** 2026-07-25
**Branch:** `feature/rc-03b-structured-logging`
**Status:** Implementado
**Escopo:** exclusivamente o sistema de logging (`AppLogger`) e sua integração com o Crash Reporting já existente (RC-03A). Analytics, Feature Flags, Feedback In-App e Segurança são itens separados do backlog e não foram tocados nesta rodada.

---

## 1. Objetivo

Transformar o `AppLogger` — até aqui um wrapper fino e nunca usado sobre `dart:developer.log` — no único canal de logging do app, com 6 níveis de severidade, comportamento diferente por ambiente, e encaminhamento automático dos níveis mais graves ao Sentry (RC-03A), sem duplicar eventos.

---

## 2. Arquitetura

```
lib/core/logger/
├── app_log_level.dart   # enum AppLogLevel + regra de nível mínimo por ambiente
└── app_logger.dart       # API pública, formatação, gating, encaminhamento

lib/core/observability/
└── crash_reporting.dart  # ganhou CrashReporting.captureLog (chamado só pelo AppLogger)
```

`core/logger/` continua sem nenhuma dependência de terceiros além de `package:meta` (só a anotação `@visibleForTesting`) — o acoplamento ao Sentry fica inteiramente em `core/observability/`, que `app_logger.dart` importa. Nenhum outro arquivo do app deve chamar `CrashReporting.captureLog` diretamente; só o `AppLogger` faz isso.

### 2.1 API

```dart
AppLogger.trace('Detalhe de execução', tag: 'reviews/ReviewDetailController.load');
AppLogger.debug('Estado intermediário', tag: 'favorites/FavoritesController');
AppLogger.info('Avaliação publicada', tag: 'reviews/ReviewDetailController.create', userId: userId);
AppLogger.warning('Retry após falha transitória', tag: 'restaurants/RestaurantRepositoryImpl.upload');
AppLogger.error('Falha ao carregar perfil', error: e, stackTrace: st, tag: 'users/ProfilePage');
AppLogger.fatal('Estado inconsistente do carrinho de favoritos', tag: 'favorites/FavoritesController');
```

Os 6 métodos têm a mesma assinatura (`message` obrigatório; `tag`, `userId` opcionais; `warning`/`error`/`fatal` também aceitam `error`/`stackTrace` opcionais) — API deliberadamente uniforme, sem casos especiais por nível.

### 2.2 Convenção de `tag`

`tag` é uma única string no formato `feature/Classe.metodo` (ex.: `reviews/ReviewDetailController.addPhoto`), em vez de três parâmetros separados (feature/classe/método) — mesma técnica já usada em `CrashReporting.captureException(..., {required String origin})` (RC-03A) para identificar a origem de um evento sem inflar a assinatura da função. `tag` é opcional; logs sem contexto de código específico (raro, mas possível) podem omiti-lo.

### 2.3 Formato do log local

```
[NÍVEL] <timestamp ISO-8601 UTC> <tag> user=<userId> — <mensagem>
```

Exemplo real:
```
[ERROR] 2026-07-25T18:42:03.912Z auth/AuthController.signIn user=8f3c1e2a — Não foi possível entrar. Verifique suas credenciais.
```

`tag` e `user=` só aparecem quando informados. `StackTrace`/`error`, quando presentes, são passados para `developer.log(error:, stackTrace:)` separadamente (não embutidos na string formatada) — aparecem estruturados no DevTools/console, não como texto solto.

---

## 3. Níveis e comportamento por ambiente

| Nível | Development | QA | Beta | Production |
|---|:-:|:-:|:-:|:-:|
| TRACE | ✔ | — | — | — |
| DEBUG | ✔ | — | — | — |
| INFO | ✔ | ✔ | ✔ | — |
| WARNING | ✔ | ✔ | ✔ | ✔ |
| ERROR | ✔ | ✔ | ✔ | ✔ |
| FATAL | ✔ | ✔ | ✔ | ✔ |

Implementado em `minimumLevelForEnvironment(String environment)` (`app_log_level.dart`), lido a partir de `AppEnvironment.environmentName` (o mesmo `--dart-define=APP_ENVIRONMENT` já introduzido na RC-03A). Um nome de ambiente desconhecido usa o mesmo piso de `production` (o mais restritivo), por segurança.

O piso é computado uma única vez (`AppLogger._environmentMinimumLevel`, `static final`), mas pode ser sobrescrito em testes via `AppLogger.debugMinimumLevelOverride` (anotado `@visibleForTesting`, nunca deve ser tocado fora de `test/`).

---

## 4. Integração com o Crash Reporting (RC-03A)

Regra única: **apenas WARNING, ERROR e FATAL** são encaminhados ao Sentry via `CrashReporting.captureLog`. TRACE/DEBUG/INFO nunca saem do dispositivo — nem em Development (onde tudo aparece localmente), nem em nenhum outro ambiente.

- Log com `error` anexado → `Sentry.captureException(error, stackTrace: ..., withScope: ...)`.
- Log sem `error` (só mensagem) → `Sentry.captureMessage(message, level: ..., withScope: ...)`.
- Em ambos os casos, a `scope` recebe `tag: 'origin' = 'app_logger'`, mais `log_tag`/`user_id` quando informados — permite filtrar no dashboard do Sentry tudo que veio do `AppLogger` separadamente do que veio da captura global/Riverpod/GoRouter (RC-03A).
- A sanitização de privacidade (`sentry_event_sanitizer.dart`, RC-03A) **não é duplicada** aqui — como `CrashReporting.captureLog` usa os mesmos `Sentry.captureException`/`captureMessage` que qualquer outro caminho, o `beforeSend` já registrado por `CrashReporting.run` sanitiza automaticamente, sem nenhum código extra.

### 4.1 Evitando eventos duplicados

`AppLogger.warning/error/fatal` são para erros **já tratados** — um `catch` que decide seguir em frente, logando o que aconteceu. Se o mesmo erro também for relançado (ou nunca capturado) e acabar chegando à captura global do `CrashReporting.run`, ao `SentryProviderObserver` ou ao `errorBuilder` do GoRouter (todos da RC-03A), ele geraria um **segundo** evento no Sentry.

**Convenção obrigatória:** um erro só deve passar por um dos dois caminhos, nunca os dois:
- Erro tratado e absorvido → `AppLogger.error(...)`, ponto final.
- Erro que vai propagar (rethrow, `Future` rejeitado sem `catch`, falha de provider, falha de navegação) → deixar a captura global da RC-03A cuidar disso; não chamar `AppLogger.error/fatal` com o mesmo `error`/`stackTrace` antes de relançar.

Não há enforcement automático dessa regra (não é tecnicamente possível sem análise estática dedicada) — é uma convenção de uso documentada aqui e a ser seguida em code review.

---

## 5. Padronização — busca por `print`/`debugPrint`/`developer.log`

Busca em toda a árvore `lib/`, `test/` e `integration_test/` (RC-03B): **zero ocorrências** de `print(`/`debugPrint(` em qualquer lugar do projeto — confirma o achado já registrado na RC-01/RC-02.5. A única ocorrência de `developer.log(` era dentro do próprio `AppLogger`, agora centralizada em `_defaultLocalSink`. Nenhuma substituição foi necessária em nenhuma tela/controller/repository — o projeto já não usava logging ad-hoc antes desta rodada.

---

## 6. Boas práticas de uso

- Use `tag` sempre que o log não for óbvio pelo contexto imediato — ajuda a filtrar tanto no `dart:developer` (DevTools) quanto no Sentry.
- Prefira `INFO` para eventos de negócio relevantes (login, criação de review, favoritar) e `DEBUG`/`TRACE` para detalhes de implementação (útil só em desenvolvimento).
- `WARNING` é para algo inesperado mas não quebrado (retry, fallback usado, dado ausente tratado com valor default).
- `ERROR` é para uma operação que falhou e foi tratada (usuário vê feedback, app continua funcional).
- `FATAL` é para um estado que não deveria ser alcançável — reservar para invariantes de app quebradas, não para erros de rede/validação comuns (esses são `ERROR`).
- Nunca logar senha, token, JWT ou e-mail completo diretamente na `message` "só para garantir" — mesmo que o `beforeSend` do Sentry redija automaticamente antes do envio (RC-03A), o log **local** (`dart:developer`) não passa por sanitização nenhuma, já que nunca sai do dispositivo. Evitar de qualquer forma é mais seguro que confiar só na camada de saída.

---

## 7. Testes

| Arquivo | Cobertura |
|---|---|
| `test/unit/core/logger/app_log_level_test.dart` | `minimumLevelForEnvironment` para os 4 ambientes + desconhecido; ordem de severidade; `label` |
| `test/unit/core/logger/app_logger_test.dart` | Gating por ambiente (piso TRACE/INFO/WARNING); TRACE/DEBUG/INFO nunca chegam ao Sentry; WARNING/ERROR/FATAL chegam exatamente uma vez cada (sem duplicidade); formato do log local (`tag`/`userId`/mensagem); `error`/`stackTrace` repassados intactos ao encaminhamento (prova de que a sanitização não é duplicada); `isLevelEnabled` |
| `test/unit/core/observability/crash_reporting_test.dart` | `CrashReporting.captureLog` não lança para nenhum dos 6 níveis, com ou sem `error` anexado |

Os testes de `AppLogger` usam 3 hooks `@visibleForTesting` (`debugMinimumLevelOverride`, `debugLocalSinkOverride`, `debugCrashReportingSinkOverride`) para observar o comportamento sem depender de `dart:developer.log` real nem de um Sentry inicializado — mesmo espírito de `debugPrint`/outros overrides de teste do próprio Flutter SDK.

---

## 8. Validação manual (checklist)

| Nível | Aparece localmente? | Chega ao Sentry? |
|---|---|---|
| TRACE | Só em Development | Nunca |
| DEBUG | Só em Development | Nunca |
| INFO | Development/QA/Beta | Nunca |
| WARNING | Todos os ambientes | Sim (`origin: app_logger`) |
| ERROR | Todos os ambientes | Sim (`origin: app_logger`) |
| FATAL | Todos os ambientes | Sim (`origin: app_logger`) |

Sem eventos duplicados: cada chamada a `AppLogger.warning/error/fatal` resulta em exatamente uma chamada a `CrashReporting.captureLog` (confirmado em `app_logger_test.dart`); a única forma de duplicidade possível é um erro que também propaga para a captura global da RC-03A — mitigado pela convenção da seção 4.1, não pelo código.

---

## 9. Limitações desta rodada

- Nenhuma verificação estática impede alguém de chamar `AppLogger.error()` e *também* relançar o mesmo erro (que seria capturado de novo pela RC-03A) — é uma convenção de code review, não uma garantia de compilador.
- O parsing de `tag` em "feature/Classe.metodo" é só uma convenção de nomenclatura — o `AppLogger` trata `tag` como uma string opaca, sem validar o formato.
- Nenhum breadcrumb automático é criado a partir de logs `INFO`/`DEBUG` (ex.: os últimos N logs antes de um erro aparecerem como trilha no Sentry) — isso exigiria configurar um `Sentry breadcrumb integration` dedicado, considerado melhoria futura, fora do escopo desta rodada.
