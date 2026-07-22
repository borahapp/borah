
# AR-05 — CI/CD

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-05_CI_CD.md

---

# 1. Objetivo

Definir a estratégia de Integração Contínua (CI) e Entrega Contínua (CD) do BORAH, automatizando validações, builds, testes e deploys para garantir qualidade, segurança e rapidez na entrega.

---

# 2. Objetivos da Pipeline

- Automatizar validações
- Garantir qualidade do código
- Reduzir erros manuais
- Padronizar builds
- Facilitar releases
- Permitir deploys reproduzíveis

---

# 3. Ferramentas

| Ferramenta | Finalidade |
|------------|------------|
| GitHub Actions | CI/CD |
| Flutter | Build |
| FVM | Controle da versão do Flutter |
| Supabase CLI | Migrações e Edge Functions |
| GitHub Releases | Distribuição |
| Google Play Console | Android |
| App Store Connect | iOS |

---

# 4. Fluxo da Pipeline

```text
Commit
   ↓
Pull Request
   ↓
CI
   ↓
Lint
   ↓
Testes
   ↓
Build
   ↓
Review
   ↓
Merge
   ↓
CD
   ↓
Deploy
```

---

# 5. Integração Contínua (CI)

Executar automaticamente em Pull Requests:

- Instalação de dependências
- Análise estática
- Formatação
- Geração de código
- Testes unitários
- Testes de widget
- Build de validação

---

# 6. Entrega Contínua (CD)

Após merge em `main`:

- Gerar artefatos
- Criar Release
- Publicar Tags
- Executar deploy do backend
- Publicar aplicativo (quando aplicável)

---

# 7. Ambientes

## Development
- Testes rápidos
- Builds internos

## Staging
- Validação da equipe
- Testes de integração

## Production
- Usuários finais
- Deploy aprovado

---

# 8. Qualidade

Critérios mínimos:

- Lint sem erros
- Testes aprovados
- Cobertura mínima definida pelo time
- Build concluído com sucesso

---

# 9. Segurança

- Secrets no GitHub Secrets
- Tokens nunca versionados
- Permissões mínimas para workflows
- Assinatura de artefatos quando aplicável

---

# 10. Pipeline do Backend

Automatizar:

- Migrações do banco
- Publicação de Edge Functions
- Atualização de políticas RLS
- Validação do schema

---

# 11. Pipeline do Flutter

Automatizar:

- flutter pub get
- dart format
- flutter analyze
- build_runner
- flutter test
- flutter build

---

# 12. Artefatos

Gerar:

- APK (debug)
- AAB (release)
- IPA (quando disponível)
- Relatórios de testes
- Logs da pipeline

---

# 13. Rollback

Toda release deve permitir:

- Reversão do backend
- Reversão do aplicativo
- Recuperação de migrações quando possível

---

# 14. Monitoramento

Após deploy acompanhar:

- Falhas
- Tempo de execução
- Logs
- Taxa de sucesso
- Erros críticos

---

# 15. Boas Práticas

- Workflows pequenos e reutilizáveis
- Cache de dependências
- Execução paralela quando possível
- Aprovação manual para produção

---

# 16. Anti-patterns

Evitar:

- Deploy manual recorrente
- Secrets no repositório
- Ignorar falhas da pipeline
- Builds sem testes

---

# 17. Critérios de Aceite

- Pipeline documentada
- CI automatizada
- CD automatizada
- Ambientes separados
- Segurança configurada

---

# 18. Checklist

- GitHub Actions definidos
- CI documentada
- CD documentada
- Build automatizado
- Testes automatizados
- Deploy automatizado
- Estratégia de rollback definida
- Monitoramento previsto

---

# 19. Implementação Atual (QA-03, Rodada F)

Esta seção documenta o que **realmente existe** no repositório, em complemento
às seções acima (intenção/arquitetura recomendada). Detalhes práticos de
Secrets e configuração manual do GitHub estão em
`docs/operations/CI_CD_SECRETS.md`.

## 19.1 Workflows

| Arquivo | Gatilho | Objetivo |
|---|---|---|
| `.github/workflows/ci.yml` | `pull_request`/`push` para `main`/`develop` | Lint, formatação, testes unitários/widget, build Android, Integration Tests |
| `.github/workflows/release.yml` | push de tag `v*.*.*` ou `workflow_dispatch` | Build de release (APK+AAB) e criação de GitHub Release |

## 19.2 Jobs de `ci.yml`

Quatro jobs. Os três primeiros são independentes entre si (sem `needs`),
rodando **em paralelo** (§15 "Execução paralela quando possível"):

- **`analyze`** — `dart format --set-exit-if-changed` + `flutter analyze`.
- **`unit_test`** — `flutter test --coverage --reporter github` (o reporter
  `github` anota falhas diretamente no PR); upload de `lcov.info` como
  artifact, sempre (`if: always()`), mesmo em falha.
- **`build_android`** — `flutter build apk --debug`; upload do APK como
  artifact.
- **`integration_test`** — depende dos três anteriores (`needs`), enumera
  os 23 arquivos via `strategy.matrix` contra o `borah-qa` real, usando
  `reactivecircus/android-emulator-runner` (API 34, `google_apis`,
  `x86_64`). Usa o Environment `qa` (secrets). **Totalmente serializado,
  nunca paralelo** (confirmado na Rodada F) por dois mecanismos
  redundantes: `strategy.max-parallel: 1` (nenhuma entrada da matriz roda
  simultânea a outra, dentro da mesma execução do workflow) e
  `concurrency.group: integration-tests` com grupo estático (nenhuma
  execução deste job — de nenhum push/PR — roda ao mesmo tempo que
  outra, no repositório inteiro). Upload do log de execução como
  artifact em caso de falha.

## 19.3 Cache

- **Flutter SDK**: `cache: true` em `subosito/flutter-action@v2` (evita
  reinstalar o SDK a cada execução).
- **Pub**: `~/.pub-cache`, chave por hash de `pubspec.lock`.
- **Gradle**: `~/.gradle/caches` + `~/.gradle/wrapper`, chave por hash dos
  arquivos `*.gradle*`/`gradle-wrapper.properties` — só nos jobs que
  compilam Android (`build_android`, `integration_test`).

## 19.4 Artifacts

- `coverage-report` (`lcov.info`) — job `unit_test`.
- `app-debug-apk` — job `build_android`.
- `integration-test-log-<índice>` — apenas em falha, job `integration_test`.
- `release-apk`/`release-aab` — job `build_release` de `release.yml`.

## 19.5 Limitações conhecidas

- Nenhuma execução real dos workflows foi confirmada nesta rodada — apenas
  validação sintática do YAML e dos comandos individuais (já exercidos
  exaustivamente nas Rodadas B–E). Confirmar manualmente após o push.
- Artefatos de `release.yml` são assinados com a chave de **debug**
  (`android/app/build.gradle.kts` nunca teve uma keystore de release
  configurada) — não aptos para publicação real. Ver
  `docs/operations/CI_CD_SECRETS.md` §2.
- Proteção de branch (§17 acima) e o Environment `qa` precisam ser
  configurados manualmente no GitHub — nenhuma ferramenta com acesso à
  API/Actions do GitHub estava disponível durante a implementação. Ver
  `docs/operations/CI_CD_SECRETS.md` §3.
- Pipeline de backend (migrations/Edge Functions automatizadas, §10 acima)
  permanece deliberadamente fora desta rodada — aplicar migrations
  automaticamente contra um projeto Supabase real via CI é uma decisão que
  precisa de autorização própria, separada da automação de testes.
