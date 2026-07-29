# RC-04D — Release Readiness & Store Preparation

**Data:** 2026-07-26
**Branch:** `feature/rc-04d-release-readiness`
**Status:** Implementado — preparativos de configuração concluídos; publicação, criação de release e Beta Fechado permanecem **fora do escopo**, conforme instruído
**Escopo:** exclusivamente preparativos técnicos para publicação nas lojas (Android/iOS). Nenhuma regra de negócio foi alterada; nenhuma arte foi criada; nenhuma publicação foi realizada.

---

## 1. Objetivo

Deixar o BORAH tecnicamente pronto para um Beta Fechado e para futura submissão à Google Play e Apple App Store, sem publicar, sem criar release e sem alterar regras de negócio.

---

## 2. Auditoria inicial (obrigatória antes de qualquer alteração)

Conduzida integralmente antes de qualquer edição de código, conforme instruído ("Caso encontre qualquer item crítico, interromper a implementação e apresentar o relatório antes de prosseguir"). Resultado completo, por item do checklist:

| Item | Situação encontrada | Ação nesta rodada |
|---|---|---|
| Versão do app | `1.0.0+1` (`pubspec.yaml`), propagada automaticamente para Android/iOS via tooling do Flutter | Nenhuma — já correto |
| `applicationId`/bundle id | `com.borah.app` em ambas as plataformas (confirmado também em `project.pbxproj`), consistente | Nenhuma — já correto |
| `versionCode`/`versionName` | Derivados de `pubspec.yaml`, sem valor hardcoded divergente | Nenhuma |
| Ícone (Android/iOS) | **Ainda é o logo padrão do template Flutter** — confirmado visualmente | Infra de geração preparada (§3); arte pendente (§6) |
| Splash screen | **Branco liso, sem marca**, em ambas as plataformas | Infra de geração preparada (§3); arte pendente (§6) |
| Nome do aplicativo | `android:label="app"` e `CFBundleDisplayName`/`CFBundleName = "App"/"app"` — placeholders genéricos | Corrigido para "BORAH" (§4) |
| Permissões Android | **Zero `<uses-permission>` declaradas**, nem `INTERNET` | Adicionada `INTERNET` (única necessária — ver §5) |
| Permissões iOS | **Zero chaves de privacidade** no `Info.plist` (nenhuma `NS*UsageDescription`) | Adicionada `NSPhotoLibraryUsageDescription` (única necessária — ver §5) |
| Assinatura Android | `release` assinado com a chave de **debug** (TODO original do template, já registrado em `CI_CD_SECRETS.md` §2 desde a Rodada F do QA-03) | Plumbing de keystore real preparado, sem gerar a chave (§3) |
| Assinatura iOS | `CODE_SIGN_STYLE = Automatic`, sem `DEVELOPMENT_TEAM` | Documentado como pendência — requer conta Apple Developer real (§3) |
| Ambientes/segredos | Nenhum `.env.*` real versionado (só `.env.example`, vazio); `.gitignore` cobre todas as variantes; `AppEnvironment` usa exclusivamente `String.fromEnvironment` com defaults seguros | Nenhuma — já correto |
| Dependências de produção | Todas as entradas em `dependencies:` são de runtime legítimo; nenhum pacote de teste/dev misclassificado | Nenhuma |
| TODO/FIXME/prints/asserts | Varredura completa em `lib/`: as únicas ocorrências são falsos positivos (comentários de documentação); nenhum `assert(` em produção | Nenhuma |
| Crash/Analytics/Flags/Feedback em Release | Inicializam incondicionalmente em `main.dart`, sem gate de `kDebugMode`; os únicos usos de `kDebugMode` controlam apenas o log interno dos próprios SDKs (Sentry/PostHog), não o envio de eventos | Nenhuma — já correto |

Dos itens acima, dois exigiram decisão do usuário antes de implementar (assinatura de release e ícone/splash), por envolverem segredos/ativos que só o responsável pela publicação pode fornecer — resolvidos via `AskUserQuestion`, ambos com a opção recomendada ("preparar infraestrutura, sem gerar segredo/arte").

---

## 3. Configuração de release

### 3.1 Android — assinatura

`app/android/app/build.gradle.kts` passou a ler `android/key.properties` (arquivo novo `key.properties.example` documenta o formato) quando presente, configurando `signingConfigs.create("release")` a partir dele; na ausência do arquivo, cai para a assinatura de debug (preserva `flutter run --release` local sem keystore). **Nenhuma keystore ou senha foi gerada nesta rodada** — isso exige custódia exclusiva de quem for publicar o app, mesmo padrão já usado para a rotação da `SERVICE_ROLE_KEY` na RC-04A. Procedimento completo documentado em `docs/operations/CI_CD_SECRETS.md` §2 (atualizado nesta rodada), incluindo o comando `keytool` e os 4 secrets de CI ainda pendentes de cadastro.

### 3.2 Android — shrink/minify/obfuscation

`buildTypes.release` ganhou `isMinifyEnabled = true`, `isShrinkResources = true` e `proguardFiles(...)` apontando para um novo `app/android/app/proguard-rules.pro`. O arquivo não define regras `-keep` especulativas: o Flutter Gradle Plugin já injeta as regras necessárias para o próprio motor Flutter/Dart, e as dependências nativas do projeto (Sentry, PostHog, image_picker, share_plus, package_info_plus) publicam suas próprias *consumer rules* dentro do AAR, aplicadas automaticamente pelo R8. **Esta configuração não foi validada com uma build de release real** — este ambiente não tem SDK Android completo para gerar um APK/AAB assinado (mesma limitação já registrada para as suítes pgTAP em rodadas anteriores). Validação real (instalar e testar um build `--release` de verdade) é uma pendência antes da publicação.

### 3.3 iOS — capabilities e assinatura

`ios/Runner.xcodeproj` já usa `CODE_SIGN_STYLE = Automatic`, o padrão recomendado quando a assinatura será configurada depois no Xcode. Não há `DEVELOPMENT_TEAM` definido — requer uma conta Apple Developer Program real, atribuída diretamente no Xcode por quem for publicar; nada a preparar em código para isso. Nenhuma capability adicional (Push Notifications, Sign in with Apple, etc.) está habilitada hoje, consistente com o app não ter nenhuma dessas funcionalidades implementadas.

---

## 4. Metadados — nome do aplicativo

Corrigidos os dois placeholders genéricos do template Flutter, sem qualquer decisão de negócio envolvida:
- Android (`AndroidManifest.xml`): `android:label="app"` → `android:label="BORAH"`.
- iOS (`Info.plist`): `CFBundleDisplayName`/`CFBundleName` = `"App"`/`"app"` → `"BORAH"`.

Descrição curta/completa da loja, cores e identidade visual não fazem parte deste item — são conteúdo de marketing/design, não infraestrutura de código, e permanecem como pendência de publicação (§6).

---

## 5. Privacidade — permissões

Mapeamento completo pedido pelo brief (câmera, galeria, internet, localização, notificações, armazenamento), feito a partir do uso real do código (não de suposição):

- **Internet**: usada constantemente (Supabase). Adicionada `android.permission.INTERNET` — antes ausente do manifesto do próprio app (embora plugins possam mesclá-la via manifest merger, declarar explicitamente é a prática esperada e mais transparente para a revisão da loja).
- **Galeria**: usada via `image_picker` (avatar, capa de restaurante, fotos de review) — confirmei por busca em todo `lib/` que `ImageSource.gallery` é a única fonte usada em todo o projeto (nenhuma chamada com `ImageSource.camera`). Adicionada `NSPhotoLibraryUsageDescription` (iOS); no Android, o próprio manifest merger do plugin cobre o acesso, sem necessidade de entrada explícita no manifesto do app.
- **Câmera**: **não usada em nenhum ponto do app** — nenhuma permissão/chave adicionada (removida do escopo por não ser necessária, conforme instruído: "caso alguma permissão seja desnecessária, remover" — nunca chegou a existir, então não havia o que remover, apenas confirmar a ausência).
- **Localização**: não há nenhum uso de geolocalização no código — nenhuma permissão adicionada.
- **Notificações**: não há infraestrutura de push/local notifications implementada — nenhuma permissão adicionada.
- **Armazenamento direto**: o app nunca lê/escreve arquivos fora do fluxo do `image_picker` (que já gerencia suas próprias permissões via manifest merger/PHPicker) — nenhuma permissão adicional necessária.

---

## 6. Ícone e splash screen — infraestrutura preparada, arte pendente

Não existe, em todo o repositório, nenhum asset de logo/ícone BORAH em alta resolução (`app/assets/` só contém um ícone de pino de mapa e o GIF/WebP de loading — nenhum logotipo completo). Por instrução explícita ("Não criar artes. Apenas validar a infraestrutura"), nenhuma arte foi criada.

Adicionadas as dev-dependencies `flutter_launcher_icons: ^0.14.4` e `flutter_native_splash: ^2.4.8` ao `pubspec.yaml`, com configuração pronta apontando para `assets/icon/borah_icon.png` — caminho que **ainda não existe**. Assim que o arquivo de logo for fornecido pelo time de design, bastam os comandos:

```
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

para gerar automaticamente todos os tamanhos de ícone (Android/iOS) e a splash screen nativa, sem nenhuma edição manual de código adicional.

---

## 7. Segurança

- Nenhuma chave sensível embutida no código-fonte (confirmado: `AppEnvironment` usa só `String.fromEnvironment`, defaults vazios/seguros).
- Nenhum arquivo `.env.*` real está versionado; `.gitignore` cobre todas as variantes usadas pelo projeto.
- Nenhum endpoint de desenvolvimento hardcoded encontrado.
- Nenhum log excessivo: varredura completa em `lib/` não encontrou `print()`/`debugPrint()` fora de comentários de documentação; o próprio `AppLogger` é o único canal de log em produção, com `warning()`/`error()` encaminhados ao Sentry a partir de `WARNING+`.
- Nenhuma configuração insegura de build encontrada além do já registrado (assinatura de release, tratada em §3.1).

---

## 8. Analytics, Crash Reporting, Feature Flags e Feedback em Release

Confirmado em `main.dart`: `CrashReporting.run`, `AppAnalytics.initialize()`, `AppFeatureFlags.initialize()` e `AppFeedback.initialize()` rodam incondicionalmente no boot, sem nenhum gate de `kDebugMode`/`kReleaseMode`. Os únicos dois usos desses flags no projeto (`posthog_analytics_service.dart`, `crash_reporting.dart`) controlam apenas a flag `debug` interna dos próprios SDKs (verbosidade de log local), nunca o envio de eventos — os 4 sistemas continuam funcionais em uma build Release.

---

## 9. Arquivos criados

- `docs/FASE 9 - Execution/RC-04D_RELEASE_READINESS.md` (este documento)
- `app/android/app/proguard-rules.pro`
- `app/android/key.properties.example`

## 10. Arquivos modificados

- `app/android/app/build.gradle.kts` — signing config condicional + minify/shrink/proguard
- `app/android/app/src/main/AndroidManifest.xml` — `android:label="BORAH"` + `uses-permission INTERNET`
- `app/ios/Runner/Info.plist` — `CFBundleDisplayName`/`CFBundleName="BORAH"` + `NSPhotoLibraryUsageDescription`
- `app/pubspec.yaml` — dev-dependencies + configuração `flutter_launcher_icons`/`flutter_native_splash`
- `app/pubspec.lock` — resolução das novas dev-dependencies
- `docs/operations/CI_CD_SECRETS.md` — §2 atualizada com o procedimento de keystore já preparado
- `docs/FASE 9 - Execution/EX-02_DEVELOPMENT_ROADMAP.md` — parágrafo da RC-04D

---

## 11. Resultado dos testes

- `flutter analyze`: **sem nenhum problema**.
- `dart format --set-exit-if-changed .`: **346 arquivos, 0 alterados**.
- `flutter test`: **479/479** — nenhuma regressão em relação à baseline da RC-04C.

Nenhum teste automatizado novo foi necessário: esta rodada alterou apenas configuração de build/manifesto/plist e documentação, sem nenhum código Dart de produção.

---

## 12. Checklist de Release

| Item | Status |
|---|---|
| Versão/build number | ✅ Pronto |
| Application ID / Bundle ID | ✅ Pronto |
| Nome do aplicativo | ✅ Corrigido ("BORAH") |
| Permissões Android | ✅ Mapeadas e mínimas (só `INTERNET`) |
| Permissões iOS | ✅ Mapeadas e mínimas (só `NSPhotoLibraryUsageDescription`) |
| Shrink/minify/obfuscation (Android) | ⚠️ Configurado, **não validado com build real** |
| Assinatura de release Android | 🔴 Plumbing pronto — **falta gerar a keystore real** (ação do responsável, fora deste chat) |
| Assinatura de release iOS | 🔴 **Falta configurar `DEVELOPMENT_TEAM`** com uma conta Apple Developer real |
| Ícone de app | ✅ Resolvido na IV-02 — ícone oficial aplicado em Android/iOS (ver `IV-01_A_05_BRAND_IDENTITY_INTEGRATION.md`) |
| Splash screen | ✅ Resolvido na IV-03 — símbolo oficial aplicado em Android/iOS (ver `IV-01_A_05_BRAND_IDENTITY_INTEGRATION.md`) |
| Descrição curta/completa da loja | 🔴 Não iniciado (conteúdo de marketing, fora do escopo desta rodada) |
| Ambientes/segredos | ✅ Confirmado seguro |
| Dependências de produção | ✅ Revisadas, sem itens indevidos |
| TODO/FIXME/prints/asserts | ✅ Nenhum encontrado |
| Crash/Analytics/Flags/Feedback em Release | ✅ Confirmados funcionais |

---

## 13. Pendências restantes antes da publicação

1. **Gerar a keystore de release Android** e preencher `android/key.properties` (procedimento em `docs/operations/CI_CD_SECRETS.md` §2) — ação exclusiva do responsável pela publicação.
2. **Configurar `DEVELOPMENT_TEAM` no Xcode** com uma conta Apple Developer Program real.
3. ~~Fornecer o asset de logo BORAH em alta resolução e rodar `flutter_launcher_icons`/`flutter_native_splash`~~ — ✅ **resolvido na IV-02/IV-03** (`IV-01_A_05_BRAND_IDENTITY_INTEGRATION.md`); ícone Google Play 512px também copiado do pacote oficial na IV-09 (`IV-06_A_09_BRAND_IDENTITY_COMPLETION.md`). Screenshots de loja e feature graphic seguem ausentes — não existem no pacote oficial e não foram criados (nenhuma arte nova), ver item 8.
4. **Validar a build de release real** (`flutter build appbundle --release` / `flutter build ipa --release`) em um ambiente com SDK Android/Xcode completos — não disponível nesta sessão — para confirmar que o `minifyEnabled`/`shrinkResources` não quebra nenhuma dependência nativa em tempo de execução.
5. **Adaptar `.github/workflows/release.yml`** para decodificar os 4 secrets de keystore em CI (hoje o workflow gera artefatos, mas ainda sem a etapa de assinatura real).
6. **Escrever descrição curta/completa da loja** e demais conteúdos de marketing (fora do escopo de código desta rodada).
7. **Executar as suítes pgTAP pendentes** (RC-04A/RC-04B, já registradas anteriormente) — segue bloqueado exclusivamente pela indisponibilidade do Docker Desktop neste ambiente, sem relação com esta rodada.
8. **Capturar screenshots reais de loja e produzir o feature graphic** (Google Play, 1024×500) — dependem de um dispositivo/emulador real ou build de release funcional (item 4), já que não existe arte oficial pronta para isso no pacote de identidade visual.
