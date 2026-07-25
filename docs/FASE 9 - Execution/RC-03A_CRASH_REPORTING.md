# RC-03A — Crash Reporting

**Data:** 2026-07-25
**Branch:** `feature/rc-03a-crash-reporting`
**Status:** Implementado — aguardando provisionamento de um projeto Sentry real por ambiente (ver §6)
**Escopo:** exclusivamente observabilidade de erros (Sentry). Analytics, Feature Flags, Feedback In-App e mudanças de segurança são itens separados do backlog da RC-02.5 (RC-03B/C/D/E, RC-04) e não foram tocados nesta rodada.

---

## 1. Objetivo

Dar visibilidade a crashes e exceções não tratadas em qualquer dispositivo rodando o BORAH (Development, QA, Beta, Production), sem depender de relato manual do usuário — pré-requisito identificado na RC-02.5 antes de abrir qualquer Beta Fechada.

---

## 2. Arquitetura

Toda a configuração fica centralizada em `app/lib/core/observability/` — nenhum outro arquivo do app chama `SentryFlutter.init`/`Sentry.captureException` diretamente.

```
lib/core/observability/
├── crash_reporting.dart          # único ponto de init + captura manual
├── sentry_event_sanitizer.dart   # sanitização de privacidade (beforeSend)
└── sentry_provider_observer.dart # integração com Riverpod
```

### 2.1 Captura global (`CrashReporting.run`)

`main.dart` chama `CrashReporting.run(appRunner)`, que por sua vez chama `SentryFlutter.init(options, appRunner: appRunner)`. O próprio `SentryFlutter.init` instala automaticamente:

- `FlutterError.onError` (exceções de framework/build/layout);
- `PlatformDispatcher.instance.onError` (erros assíncronos fora da árvore de widgets, incluindo `Future`s não tratados);
- `runZonedGuarded` (quando a plataforma exige — ex. Web; em mobile o SDK usa `PlatformDispatcher.onError` diretamente).

Essas três camadas **não foram reimplementadas manualmente** — fazer isso além do que o `SentryFlutter.init` já instala causaria captura duplicada do mesmo erro. `initializeSupabase()` e `runApp()` rodam dentro do `appRunner`, então qualquer erro durante o próprio bootstrap do app (não só depois da UI subir) também é capturado.

### 2.2 Integração com Riverpod (`SentryProviderObserver`)

Um `ProviderObserver` (registrado em `ProviderScope(observers: [SentryProviderObserver()])`) sobrescreve `providerDidFail` e reporta qualquer provider que falhar — síncrono ou assíncrono (`FutureProvider`, `AsyncNotifier`, etc.) — com uma tag `origin: riverpod_provider:<nome-ou-tipo>` para identificar a origem no dashboard do Sentry.

### 2.3 Integração com GoRouter (erros de navegação)

`appRouterProvider` ganhou um `errorBuilder`: quando uma rota não existe ou falha ao construir, o erro é reportado (`origin: go_router`) e a tela mostra o componente `ErrorState` (Design System, já existente desde a RC-02) em vez da tela de erro padrão/crua do GoRouter — mantém a experiência consistente com o resto do app mesmo num caso de erro.

### 2.4 Captura manual (`CrashReporting.captureException`)

Wrapper único usado pelas duas integrações acima (`origin` obrigatório, para sempre saber a fonte do erro sem abrir o stack trace). Nenhuma outra parte do app chama isso diretamente nesta rodada — não foi adicionado tratamento de erro manual em nenhuma tela/controller/repository (fora do escopo da RC-03A).

---

## 3. Privacidade

Toda a sanitização acontece em `sentry_event_sanitizer.dart`, usado como `SentryOptions.beforeSend` — é o único ponto de saída de dados para o Sentry, então nenhum evento sai sem passar por ele.

Garantias:
- `sendDefaultPii = false` — o SDK nunca anexa IP, e-mail ou nome de usuário automaticamente.
- `attachScreenshot = false` — nenhuma captura de tela (poderia expor dados sensíveis exibidos na UI no momento do crash).
- Nenhuma integração HTTP (`sentry_dio` ou equivalente) foi adicionada — o Supabase client não é interceptado, então requests/headers/tokens de autenticação nunca chegam a fazer parte de um evento em primeiro lugar.
- `beforeSend` redige defensivamente (mesmo sem uma integração HTTP, como camada extra):
  - Qualquer chave de tag/extra cujo nome contenha `password`, `token`, `jwt`, `refresh`, `secret`, `authorization` ou `api_key`/`access_key` (case-insensitive) → substituída por `[REDACTED]`.
  - Qualquer texto livre (mensagem de exceção, mensagem de breadcrumb, mensagem do evento) que contenha um padrão de JWT (`eyJ...`) ou um e-mail completo → o trecho correspondente é substituído por `[REDACTED]`.
- Coberto por 7 testes unitários (`test/unit/core/observability/sentry_event_sanitizer_test.dart`).

**Limitação conhecida:** a redação de texto livre é feita por regex (JWT/e-mail), não por uma lista exaustiva de todo padrão sensível possível — é uma defesa em profundidade, não uma garantia absoluta. Nenhum dado estruturado sensível (senha, token, refresh token) é anexado deliberadamente em nenhum lugar do app hoje; se algum código futuro passar a anexar `extra`/`tags` a um evento manualmente, deve usar nomes de chave que o padrão de redação reconheça, ou estender `sentry_event_sanitizer.dart`.

---

## 4. Ambientes

| Ambiente | `SENTRY_DSN` | `APP_ENVIRONMENT` | Comportamento |
|---|---|---|---|
| Development | vazio (`.env.development`) | `development` | Sentry desabilitado por padrão — DSN vazio faz o SDK não enviar nenhum evento (comportamento nativo do pacote `sentry`, não é uma flag customizada). |
| QA | vazio (`.env.qa`) hoje; `--dart-define=APP_ENVIRONMENT=qa` já configurado em `ci.yml` | `qa` | Mesma coisa — sem DSN configurado, nenhum evento é enviado. Pronto para ativar assim que um projeto Sentry real existir. |
| Beta | ainda não existe como ambiente real (ver RC-02.5) | `beta` | Mecanismo já suportado pelo mesmo `--dart-define=APP_ENVIRONMENT=beta` — falta só provisionar o ambiente em si (RC-05, fora do escopo desta rodada). |
| Production | ainda não existe como ambiente real (ver RC-02.5) | `production` | Idem — mecanismo pronto, ambiente ainda não provisionado. |

### Como configurar um novo ambiente (quando Beta/Production existirem)

1. Criar um projeto no Sentry (ou usar um projeto único com ambientes separados via tag — decisão a tomar quando o ambiente for provisionado).
2. Definir `SENTRY_DSN=<dsn-real>` e `APP_ENVIRONMENT=<nome>` no `.env.<ambiente>` correspondente (nunca commitado — mesmo padrão de `.env.development`/`.env.qa`).
3. Passar ambos via `--dart-define-from-file=.env.<ambiente>` (execução local/manual) ou `--dart-define=SENTRY_DSN=... --dart-define=APP_ENVIRONMENT=...` (CI, a partir de um GitHub Secret dedicado — nenhum secret de Sentry existe ainda, precisa ser criado quando o projeto Sentry for provisionado).
4. Nenhuma mudança de código é necessária — o mecanismo já lê esses dois valores via `AppEnvironment`.

---

## 5. Limitações desta rodada

- Nenhum projeto Sentry real foi criado — não há DSN válido em nenhum ambiente hoje. A infraestrutura de código está pronta; falta só a etapa operacional (criar conta/projeto Sentry), fora do escopo de uma tarefa de implementação de código.
- Não há teste de performance/tracing (`tracesSampleRate` não configurado/deixado no default) — só crash reporting, conforme o escopo explícito desta rodada.
- Não há captura de breadcrumbs automáticos de navegação (ex. um `NavigatorObserver` de breadcrumb) — só o `errorBuilder` para falhas reais de rota. Adicionar breadcrumbs de navegação bem-sucedida é uma melhoria futura de observabilidade, não um requisito desta rodada.
- Não foi adicionado nenhum botão/tela de teste manual de crash (ex. "Forçar crash de teste") — validação foi feita via testes automatizados (ver §7); considerar adicionar um botão assim em modo debug numa rodada futura, se necessário para QA manual.

---

## 6. Pendência operacional

Criar o(s) projeto(s) Sentry reais (Development pode ficar deliberadamente sem DSN — não há necessidade de observabilidade em máquina de desenvolvedor local; QA/Beta/Production precisam de DSN real antes de gerarem valor) é uma ação fora deste código, a ser feita por quem tem acesso administrativo, seguindo o mesmo padrão já usado para o Supabase (`docs/operations/CI_CD_SECRETS.md`). Um novo documento operacional (`docs/operations/SENTRY_SETUP.md` ou seção equivalente em `CI_CD_SECRETS.md`) deve ser criado quando isso acontecer.

---

## 7. Testes

| Arquivo | O que cobre |
|---|---|
| `test/unit/core/observability/sentry_event_sanitizer_test.dart` | Sanitização (JWT, e-mail, chaves sensíveis em tags/extra, texto normal preservado, evento vazio) — 7 testes |
| `test/unit/core/observability/sentry_provider_observer_test.dart` | Integração com Riverpod: provider síncrono, assíncrono (`FutureProvider`), nomeado e sem nome, todos continuam propagando o erro original normalmente após o observer ser notificado — 4 testes |
| `test/widget/widget_test.dart` (novo caso) | Integração com GoRouter: rota desconhecida renderiza `ErrorState` em vez de crashar/mostrar a tela de erro crua do GoRouter |

`Sentry.captureException` chamado antes de `Sentry.init` faz no-op seguro (o Hub padrão do pacote é um `NoOpHub` até o SDK ser inicializado) — por isso os testes de integração acima não precisam inicializar o Sentry de verdade; eles validam que **nossa** integração (Riverpod/GoRouter → `CrashReporting.captureException`) está corretamente conectada, não o SDK do Sentry em si (que já tem sua própria suíte de testes upstream).

---

## 8. Validação manual recomendada (pós-merge, com DSN real configurado)

Quando um DSN real estiver disponível num ambiente:
1. Erro síncrono: lançar uma exceção dentro de um `onPressed` qualquer → deve aparecer no Sentry com stack trace completo.
2. Erro assíncrono/`Future`: uma chamada de repositório que rejeita sem `try/catch` → deve aparecer com o mesmo nível de detalhe.
3. Erro de Provider: um provider que lança durante `build()` → deve aparecer com a tag `origin: riverpod_provider:<nome>`.
4. Erro de navegação: navegar para uma rota inexistente → deve aparecer com a tag `origin: go_router`, e a tela deve mostrar `ErrorState`, não travar o app.
5. Conferir manualmente no dashboard do Sentry que nenhum evento de teste acima contém senha/token/e-mail completo.
