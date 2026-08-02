# CI Guide — BORAH

Como `.github/workflows/ci.yml` e `.github/workflows/release.yml` funcionam hoje, job por job. Revisado por completo na RC-01D (2026-08-02) — a correção aplicada nessa rodada já está refletida abaixo.

## `ci.yml` — roda em todo push/PR para `main`/`develop`

`concurrency: ci-${{ github.workflow }}-${{ github.ref }}` com `cancel-in-progress: true` — um push novo cancela a execução anterior da mesma branch, evita gastar runner com código já obsoleto.

| Job | O que faz | Depende de |
|---|---|---|
| `analyze` | `flutter pub get` → `dart format --set-exit-if-changed .` → `flutter analyze` | — |
| `unit_test` | `flutter pub get` → `flutter test --coverage --reporter github`, sobe `coverage-report` (`lcov.info`) como artefato mesmo se falhar (`if: always()`) | — |
| `build_android` | `flutter build apk --debug`, sobe `app-debug-apk` como artefato | — |
| `integration_test` | Matriz de **23 arquivos** de `integration_test/`, um por vez, contra o Supabase real de QA (`borah-qa`) | `analyze`, `unit_test`, `build_android` |

### `integration_test` — serialização total, intencional

A matriz tem 23 entradas mas **nunca roda em paralelo**, nem entre si nem contra outra execução concorrente deste mesmo job (`concurrency.group: integration-tests`, nome estático, sem `matrix.test_file` nem `github.ref`) — dois mecanismos redundantes de propósito:

1. `strategy.max-parallel: 1` — limita a própria matriz.
2. `concurrency.group` estático — impede qualquer outra execução (outro PR, outro push) de rodar ao mesmo tempo no repositório inteiro; as demais ficam em fila (`cancel-in-progress: false`), não são canceladas.

**Por quê:** os 23 testes rodam contra o mesmo projeto Supabase real e compartilhado (`borah-qa`) via emulador Android — execuções concorrentes colidiriam nos mesmos dados. Trade-off aceito: correção sobre velocidade. Uma consequência prática é que este job é o mais lento do pipeline (23 execuções seriais de emulador Android) — nenhuma otimização de paralelismo deve ser introduzida sem resolver primeiro o isolamento de dados entre execuções.

Roda no `environment: qa` do GitHub (consome os secrets `SUPABASE_QA_URL`/`SUPABASE_QA_ANON_KEY`/`SUPABASE_QA_SERVICE_ROLE_KEY` — ver `SECRETS.md`).

## `release.yml` — roda em push de tag `v*.*.*` ou disparo manual

| Job | Runner | O que faz |
|---|---|---|
| `build_release` | `ubuntu-latest`, `environment: production` | `pub get` → `dart format` → `analyze` → `test` → decodifica keystore (se `ANDROID_KEYSTORE` existir) → `flutter build apk --release`/`appbundle --release` com os 5 `--dart-define` de produção → sobe `release-apk`/`release-aab` → cria GitHub Release (se a ref for uma tag `v*`) |
| `build_release_ios` | `macos-latest`, `environment: production` | `pub get` → `dart format` → `analyze` → `test` → `flutter build ios --release --no-codesign` |

### Correção aplicada na RC-01D

Antes desta rodada, **só `ci.yml` rodava `dart format --set-exit-if-changed .`** — `release.yml` tinha um comentário dizendo "mesmas validações da CI", mas só listava `analyze`/`test`. Uma tag criada a partir de um commit fora do padrão de formatação passaria pelo release sem ser detectada. Corrigido: `dart format` agora roda nos dois jobs, na mesma posição relativa que `ci.yml` usa (depois de `pub get`, antes de `analyze`).

### Assinatura Android condicional

```yaml
- name: Decode Android release keystore (se configurada)
  if: ${{ secrets.ANDROID_KEYSTORE != '' }}
```

Sem o secret, nenhum arquivo é criado e o Gradle cai para a assinatura de debug (mesmo fallback de `android/app/build.gradle.kts`, ver `ANDROID_RELEASE.md`) — o job nunca quebra por falta desse secret, só produz um artefato não-assinado para distribuição real.

### iOS — o que este job garante e o que não garante

`--no-codesign` prova que a build de Release **compila e empacota** para iOS — não gera um `.ipa`, não assina, não pode ser enviado ao TestFlight. Ver `IOS_RELEASE.md` para a lista completa do que falta.

### Sentry (upload do mapping R8) — variáveis de ambiente, não `--dart-define`

```yaml
env:
  SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
  SENTRY_PROJECT: ${{ secrets.SENTRY_PROJECT }}
  SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
```

Lidas por `System.getenv(...)` dentro de `android/app/build.gradle.kts` (plugin `io.sentry.android.gradle`) — um contexto totalmente separado do `--dart-define` (que só afeta o bytecode Dart). Sem `SENTRY_AUTH_TOKEN`, o upload do `mapping.txt` é pulado automaticamente, sem quebrar o build.

## Cache

| O quê | Chave | Usado em |
|---|---|---|
| `~/.pub-cache` | `${{ runner.os }}-pub-${{ hashFiles('app/pubspec.lock') }}` | Todos os jobs |
| `~/.gradle/caches` + `~/.gradle/wrapper` | `${{ runner.os }}-gradle-${{ hashFiles('app/android/**/*.gradle*', ...) }}` | `build_android`, `integration_test`, `build_release` |
| CocoaPods (iOS) | **Não existe ainda** | — |

**Por que não há cache de CocoaPods:** o `ios/Podfile` só passou a existir na RC-01C (não havia nenhum `pod install` registrado até então). Sem um `Podfile.lock` real (gerado só num Mac real), qualquer chave de cache seria um palpite não testável neste ambiente — melhor não introduzir do que introduzir uma chave errada sem conseguir validar. Assim que alguém rodar `pod install` num Mac real e comitar o `Podfile.lock`, adicionar cache de `~/Library/Caches/CocoaPods` e/ou `ios/Pods`, chaveado pelo hash do lock.

## Artefatos e uploads

| Artefato | Job | Condição |
|---|---|---|
| `coverage-report` (`lcov.info`) | `unit_test` | Sempre (`if: always()`) |
| `app-debug-apk` | `build_android` | Sempre |
| `integration-test-log-N` | `integration_test` | Só em falha (`if: failure()`) |
| `release-apk` / `release-aab` | `build_release` | Sempre que o job roda |
| GitHub Release (com os 2 artefatos acima anexados) | `build_release` | Só se a ref for uma tag `v*` |

Nenhum artefato do `coverage-report` é hoje agregado a um serviço externo (Codecov/Coveralls) — fica disponível só para download manual. Não é um problema, é uma oportunidade não aproveitada.

## Secrets consumidos por estes workflows

Ver `SECRETS.md` para a tabela completa (nome, ambiente, status de cadastro).

## Custo do runner `macos-latest`

GitHub Actions cobra minutos de runner macOS numa taxa bem mais alta que Linux (~10×). `build_release_ios` só roda em push de tag ou disparo manual (nunca em todo push/PR, ao contrário dos jobs Android) — impacto de custo baixo, mas o responsável pelo billing do repositório deve estar ciente antes da primeira tag real.

## Execução real

**Nenhum destes workflows foi executado de fato no GitHub em nenhuma sessão desta conversa** — push está bloqueado neste ambiente por permissão. Uma sessão anterior validou `flutter build appbundle --release` com sucesso, mas fora do GitHub Actions (execução local com SDK real disponível). Confirmar a execução real do pipeline é a próxima ação concreta antes de qualquer tag de release.
