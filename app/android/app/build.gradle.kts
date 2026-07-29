import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // OBS-01A: ver bloco `sentry { ... }` abaixo para a configuracao.
    id("io.sentry.android.gradle")
}

// RC-04D: keystore de release (android/key.properties, nunca versionado - ver
// docs/operations/CI_CD_SECRETS.md secao 2). Ausente neste ambiente ate que a
// keystore real seja gerada e as credenciais fornecidas pelo responsavel.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.borah.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.borah.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // RC-04D: usa a keystore real quando android/key.properties existir;
            // sem ela, cai para a assinatura de debug (preserva `flutter run
            // --release` local sem keystore configurada).
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// OBS-01A: automatiza o upload do mapping.txt do R8/ProGuard ao Sentry a
// cada build de Release, para que crashes de Producao cheguem com stack
// traces deobfuscados (achado da BETA-10D - nenhum plugin do Sentry
// estava configurado ate agora). Le SENTRY_ORG/SENTRY_PROJECT/
// SENTRY_AUTH_TOKEN de variaveis de ambiente - nunca hardcoded (ver
// docs/operations/CI_CD_SECRETS.md). Sem o auth token, o upload e
// desabilitado automaticamente e a build continua funcionando
// normalmente - mesma filosofia nao-bloqueante ja usada para a keystore
// e os demais secrets de Producao deste projeto.
sentry {
    val hasSentryAuthToken = !System.getenv("SENTRY_AUTH_TOKEN").isNullOrEmpty()

    org.set(System.getenv("SENTRY_ORG"))
    projectName.set(System.getenv("SENTRY_PROJECT"))
    authToken.set(System.getenv("SENTRY_AUTH_TOKEN"))

    includeProguardMapping.set(true)
    autoUploadProguardMapping.set(hasSentryAuthToken)

    // Escopo estrito desta rodada: só o mapping do R8. Nao habilitar
    // symbols nativos, contexto de codigo-fonte ou instrumentacao de
    // tracing - nenhum desses fazia parte da arquitetura de
    // observabilidade ja existente (RC-03A), e nao devem ser
    // introduzidos como efeito colateral.
    uploadNativeSymbols.set(false)
    includeSourceContext.set(false)
    tracingInstrumentation {
        enabled.set(false)
    }
    // sentry_flutter ja traz e gerencia sua propria versao do SDK nativo
    // (io.sentry:sentry-android, ver o build.gradle do proprio pacote) -
    // desabilita a auto-instalacao do plugin para evitar uma segunda
    // dependencia/versao concorrente do mesmo SDK.
    autoInstallation {
        enabled.set(false)
    }
}

flutter {
    source = "../.."
}
