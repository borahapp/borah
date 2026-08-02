# Build Guide — BORAH

Como compilar o app localmente e entender o que cada comando produz. Para o processo de CI, ver `CI_GUIDE.md`. Para assinatura/versionamento por plataforma, ver `ANDROID_RELEASE.md`/`IOS_RELEASE.md`.

## Pré-requisitos

- **Flutter 3.44.6**, fixado via FVM (`app/.fvm/fvm_config.json`) — não usar outra versão; `ci.yml`/`release.yml` consomem exatamente esse arquivo (`flutter-version-file`), então uma versão local diferente pode mascarar (ou criar) incompatibilidades que só apareceriam na CI.
- **Dart 3.12.2** (vem embutido no Flutter acima — não instalar separadamente).
- Android: SDK com `compileSdk`/`targetSdk` 36, NDK `28.2.13676358` (todos resolvidos automaticamente por `flutter.*` em `android/app/build.gradle.kts` — não hardcoded, não precisa configurar manualmente além de ter o SDK instalado).
- iOS: macOS + Xcode + CocoaPods — **nenhuma sessão até hoje validou isso numa máquina real** (ver `IOS_RELEASE.md`).

## Comandos do dia a dia

```bash
cd app
flutter pub get
flutter analyze
flutter test
dart format --set-exit-if-changed .   # mesmo gate que a CI usa (ci.yml e release.yml)
```

## Builds de debug (desenvolvimento local)

```bash
flutter run                                    # roda no emulador/dispositivo conectado
flutter build apk --debug                       # gera app/build/app/outputs/flutter-apk/app-debug.apk
```

Sem nenhum `--dart-define`, o app roda com os defaults de `AppEnvironment` (`APP_ENVIRONMENT=development`, `SENTRY_DSN`/`POSTHOG_API_KEY` vazios — Analytics/Crash Reporting ficam desabilitados nativamente pelos próprios SDKs, não é um erro).

## Builds de release (Android)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<chave> \
  --dart-define=SENTRY_DSN=<dsn> \
  --dart-define=POSTHOG_API_KEY=<chave> \
  --dart-define=POSTHOG_HOST=<host> \
  --dart-define=APP_ENVIRONMENT=<development|qa|beta|production>

flutter build appbundle --release \
  # mesmos --dart-define acima
```

- **Saída:** `app/build/app/outputs/flutter-apk/app-release.apk` e `app/build/app/outputs/bundle/release/app-release.aab`.
- **Assinatura:** automática via `android/app/build.gradle.kts` — usa `android/key.properties` se existir (keystore real), senão cai para a assinatura de debug sem quebrar o build (ver `ANDROID_RELEASE.md`).
- **`APP_ENVIRONMENT`** não é cosmético: `QaEnvironment.assertRunningAgainstQaProject()` e lógicas equivalentes dependem desse valor bater com a URL do Supabase informada — nunca misturar `SUPABASE_URL` de um ambiente com `APP_ENVIRONMENT` de outro.

## Build de release (iOS)

```bash
flutter build ios --release --no-codesign \
  # mesmos --dart-define do Android acima
```

`--no-codesign` só confirma que compila — não produz um `.ipa` distribuível. Ver `IOS_RELEASE.md` para o que falta de fato para gerar um IPA assinado.

## `flavors`

**BORAH não usa flavors do Gradle/Xcode.** A diferenciação entre ambientes (development/qa/beta/production) é feita inteiramente via `--dart-define` (lido por `AppEnvironment`, `app/lib/core/environment/app_environment.dart`) — um único build type (`debug`/`release`) por plataforma, nunca múltiplos `applicationId`/`bundle id` por ambiente. Isso é uma decisão de arquitetura, não uma lacuna: simplifica a CI (um só job de build por plataforma) ao custo de exigir sempre os `--dart-define` corretos na hora de gerar cada artefato.

## Onde as versões de SDK/toolchain vêm de

Nenhum valor de `compileSdk`/`minSdk`/`targetSdk`/NDK está hardcoded em `android/app/build.gradle.kts` — todos vêm de `flutter.*`, resolvidos pelo próprio Flutter Gradle Plugin a partir da versão do Flutter instalada. Trocar a versão do Flutter (fora do fixado em `.fvm/fvm_config.json`) muda esses valores automaticamente — ver `VERSIONING.md` para o valor exato usado hoje.
