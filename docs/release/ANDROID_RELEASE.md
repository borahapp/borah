# Android Release — BORAH

Estado exato da configuração Android para gerar `app-release.apk`/`app-release.aab`. Para os comandos, ver `BUILD_GUIDE.md`; para o pipeline de CI, `CI_GUIDE.md`; para os secrets envolvidos, `SECRETS.md`.

## Identidade do app

| Campo | Valor | Onde está |
|---|---|---|
| `applicationId` | `com.borah.app` | `android/app/build.gradle.kts` |
| `namespace` | `com.borah.app` | `android/app/build.gradle.kts` |
| Pacote Kotlin real | `com.borah.app` | `android/app/src/main/kotlin/com/borah/app/MainActivity.kt` |
| Nome exibido | `BORAH` | `android/app/src/main/AndroidManifest.xml` (`android:label`) |

Consistente com o `PRODUCT_BUNDLE_IDENTIFIER` do iOS (`com.borah.app`) — mesma identidade nas duas plataformas.

## Toolchain

| Componente | Valor | Como é resolvido |
|---|---|---|
| compileSdk | 36 | `flutter.compileSdkVersion` — dinâmico, nunca hardcoded |
| targetSdk | 36 | `flutter.targetSdkVersion` |
| minSdk | 24 | `flutter.minSdkVersion` |
| NDK | 28.2.13676358 | `flutter.ndkVersion` |
| AGP | 9.0.1 | `android/settings.gradle.kts` |
| Kotlin | 2.3.20 | `android/settings.gradle.kts`, JVM target 17 |
| Java | 17 | `sourceCompatibility`/`targetCompatibility` em `android/app/build.gradle.kts` |
| Gradle (wrapper) | 9.1.0 | `android/gradle/wrapper/gradle-wrapper.properties` |

Combinação já validada empiricamente numa sessão anterior via `flutter build appbundle --release` real, incluindo a compatibilidade do plugin `io.sentry.android.gradle 6.16.0` com AGP 9.0.1/Kotlin 2.3.20.

`flutter_launcher_icons` declara `min_sdk_android: 21` (mais baixo que o `minSdk` real de 24) — isso só controla quais variantes de ícone legado são geradas, não afeta o `minSdk` de fato aplicado ao app; sem efeito prático, não é uma inconsistência a corrigir.

## Assinatura

`android/app/build.gradle.kts` lê `android/key.properties` (nunca versionado — `android/.gitignore` cobre `key.properties`/`*.jks`/`*.keystore`) em tempo de build:

```kotlin
val hasReleaseKeystore = keystorePropertiesFile.exists()
// ...
signingConfig = if (hasReleaseKeystore) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
```

**Sem a keystore real, o build de Release cai para a assinatura de debug automaticamente — nunca quebra.** Isso permite `flutter run --release`/`flutter build apk --release` funcionarem localmente mesmo sem nenhuma credencial, mas o artefato resultante **não é assinável para a Play Store** até a keystore real existir.

### Gerar a keystore real (ação do proprietário, uma única vez, fora deste repositório)

```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias borah_release
```

Depois: copiar `android/key.properties.example` → `android/key.properties`, preencher `storePassword`/`keyPassword`/`keyAlias`/`storeFile`, guardar o `.jks` e as senhas num cofre seguro (nunca em texto puro, nunca versionado).

## ProGuard / R8

`isMinifyEnabled = true`, `isShrinkResources = true` (só no `buildType release`). Regras em `android/app/proguard-rules.pro`: o Flutter Gradle Plugin já injeta as regras do motor Flutter/Dart automaticamente; as dependências nativas (Sentry, PostHog, `image_picker`, `share_plus`, `package_info_plus`) publicam suas próprias `consumer-rules.pro` dentro do AAR, aplicadas automaticamente pelo R8. Nenhuma regra adicional é necessária hoje — só seria preciso adicionar uma `-keep` específica se um release real revelasse uma falha por remoção indevida de classe (nunca observado, porque nenhum release real ainda existiu).

## Upload do mapping R8 ao Sentry

`android/app/build.gradle.kts` aplica `io.sentry.android.gradle` (versão `6.16.0`):

```kotlin
sentry {
    val hasSentryAuthToken = !System.getenv("SENTRY_AUTH_TOKEN").isNullOrEmpty()
    autoUploadProguardMapping.set(hasSentryAuthToken)
    // uploadNativeSymbols, includeSourceContext, tracingInstrumentation, autoInstallation: todos desabilitados de propósito (escopo estrito - só o mapping do R8)
}
```

Sem `SENTRY_AUTH_TOKEN`, o upload é pulado automaticamente (`> skipping upload.` no log) — build continua funcionando normalmente. Ver `SECRETS.md` para os 3 secrets envolvidos (`SENTRY_ORG`/`SENTRY_PROJECT`/`SENTRY_AUTH_TOKEN`).

## Manifest

`android/app/src/main/AndroidManifest.xml`: só `INTERNET` (chamadas ao Supabase) — sem câmera, localização, notificações ou armazenamento direto (não usados). Deep link `borah://password-recovery` registrado para o fluxo de recuperação de senha do `supabase_flutter`. `queries` para `PROCESS_TEXT` (exigido pelo próprio Flutter engine).

## Checklist Google Play

- [x] `applicationId` estável e definitivo
- [x] `versionCode`/`versionName` corretos (ver `VERSIONING.md`)
- [x] Ícone adaptativo gerado a partir de arte real (`flutter_launcher_icons`, fonte em `assets/borah/app_icon/`)
- [x] Splash nativo gerado a partir de arte real (`flutter_native_splash`)
- [x] ProGuard/R8 configurados
- [x] Build de Release validada com sucesso (sessão anterior, `flutter build appbundle --release`)
- [ ] Keystore de release real gerada
- [ ] 4 secrets Android cadastrados no GitHub (`ANDROID_KEYSTORE*`, ver `SECRETS.md`)
- [ ] Conta Google Play Console
- [ ] Política de Privacidade publicada em URL real
- [ ] Screenshots/Feature Graphic
- [ ] Execução real de `release.yml` num runner do GitHub

Nenhum item pendente é código.
