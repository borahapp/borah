# Versioning — BORAH

## Fonte única de verdade

`app/pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Formato `<build-name>+<build-number>` (`MAJOR.MINOR.PATCH+BUILD`). **Nenhuma outra parte do projeto declara uma versão independente** — Android e iOS derivam os campos nativos automaticamente a partir deste único valor, nunca hardcoded em nenhum arquivo de plataforma.

## Como cada plataforma consome

| Plataforma | Campo nativo | Origem |
|---|---|---|
| Android | `versionName` | `flutter.versionName` (`android/app/build.gradle.kts`) |
| Android | `versionCode` | `flutter.versionCode` |
| iOS | `CFBundleShortVersionString` | `$(FLUTTER_BUILD_NAME)` (`Info.plist`, resolvido via `Generated.xcconfig`) |
| iOS | `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` |

Trocar a versão é sempre uma única edição em `pubspec.yaml` — nunca editar `build.gradle.kts`/`project.pbxproj`/`Info.plist` diretamente para isso.

## Sobrescrever pontualmente (build local, sem editar `pubspec.yaml`)

```bash
flutter build apk --release --build-name=1.0.1 --build-number=2
```

Uso típico: builds de teste intermediários sem comitar uma mudança de versão ainda.

## Versão atual

`1.0.0+1` — ainda não publicada em nenhuma loja (primeiro Beta fechado planejado, ver `BORAH_RELEASE_CANDIDATE_REPORT.md`).

## Convenção de tags de release

`release.yml` dispara em `push: tags: ["v*.*.*"]` — formato `vMAJOR.MINOR.PATCH` (ex.: `v1.0.0`), consistente com `AR-04_GIT_STRATEGY.md §11`/`DV-12 §3`. A tag **não precisa bater automaticamente** com o `version:` do `pubspec.yaml` no momento em que é criada — são mecanismos independentes (a tag dispara o workflow; o `pubspec.yaml` decide o que vai dentro do artefato). Na prática, a disciplina esperada é: atualizar `pubspec.yaml` num commit em `main`, depois criar a tag correspondente a partir desse mesmo commit — nunca o inverso.

`release.yml` também aceita `workflow_dispatch` (disparo manual) — útil para testar o pipeline inteiro sem publicar uma tag real ainda (ex.: validar que os secrets recém-cadastrados funcionam antes do primeiro release de verdade).

## Quando incrementar o quê

- **Build number** (`+N`): a cada novo artefato enviado a uma loja (TestFlight/Play Console internal testing), mesmo sem nenhuma mudança de código visível — as duas lojas exigem um build number sempre crescente por versão.
- **Patch** (`x.x.N`): correções de bug sem mudança de comportamento visível ao usuário.
- **Minor** (`x.N.x`): novas funcionalidades, sem quebra de compatibilidade.
- **Major** (`N.x.x`): reservado para mudanças que justifiquem uma nova geração do produto — não esperado no curto prazo pós-Beta.

Nenhuma automação de bump de versão existe hoje (nem no CI, nem em script) — é sempre uma edição manual e deliberada de `pubspec.yaml`.
