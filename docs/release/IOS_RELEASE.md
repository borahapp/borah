# iOS Release — BORAH

Estado exato da configuração iOS para gerar um `.ipa`. Auditado em duas rodadas (RC-01A, RC-01C) — o achado mais importante das duas: **este projeto iOS nunca passou por `pod install` até a RC-01C**. Para os comandos, ver `BUILD_GUIDE.md`; para o pipeline de CI, `CI_GUIDE.md`.

## Identidade do app

| Campo | Valor | Onde está |
|---|---|---|
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.borah.app` | `ios/Runner.xcodeproj/project.pbxproj` (Debug/Profile/Release) |
| Nome exibido | `BORAH` | `Info.plist` (`CFBundleDisplayName`/`CFBundleName`) |
| Deployment target | `13.0` | `project.pbxproj` |
| Swift | `5.0` | `project.pbxproj` |
| `TARGETED_DEVICE_FAMILY` | `1,2` (iPhone + iPad) | `project.pbxproj` |

Idêntico ao `applicationId` do Android (`com.borah.app`) — mesma identidade nas duas plataformas.

## CocoaPods — achado real (RC-01A/RC-01C)

Até a RC-01C, `ios/Podfile` **não existia** — confirmado por zero ocorrências de "Pods"/"CocoaPods" em todo `project.pbxproj` (nenhuma referência a `Pods-Runner`, nenhum build phase "Check Pods Manifest.lock"). Isso não é "iOS nunca testado" de forma abstrata — é a evidência concreta de que o projeto nunca chegou a compilar de fato uma vez, porque `flutter build ios` depende de CocoaPods para linkar o código nativo dos plugins (`google_sign_in_ios`, `image_picker_ios`, `share_plus`, `sentry_flutter`, `posthog_flutter`).

**Corrigido na RC-01C:** `ios/Podfile` criado a partir do template oficial do Flutter (mesma versão, 3.44.6), incluindo o target `RunnerTests` (que já existe no Xcode project). Sintaxe validada (`ruby -c`) — **mas nunca validado com um `pod install` real**, porque nenhuma sessão até hoje teve acesso a um Mac. Este é o próximo passo concreto, e só pode ser feito num ambiente real.

## Assinatura

```
CODE_SIGN_STYLE = Automatic
```

**`DEVELOPMENT_TEAM`/`PROVISIONING_PROFILE` não existem em nenhum lugar do `project.pbxproj`** (confirmado por busca — zero ocorrências) — o projeto nunca foi aberto no Xcode com uma conta Apple Developer real logada. Sem isso, não há como gerar um `.ipa` assinado; `--no-codesign` (usado em `release.yml`) só permite confirmar que a build *compila*, nunca produz um artefato distribuível.

Não há automação de assinatura (Fastlane match ou equivalente) — a estratégia planejada é assinatura manual via Xcode (`CODE_SIGN_STYLE = Automatic`) assim que a conta existir.

## Google Sign-In — placeholder pendente

`Info.plist` ainda tem um valor literal de espera, não uma variável de ambiente:

```xml
<string>com.googleusercontent.apps.PENDENTE-GOOGLE-IOS-CLIENT-ID</string>
```

Não bloqueia o build nem a geração do IPA — só bloqueia o *fluxo* de login Google em runtime no iOS até ser substituído pelo Client ID real (Google Cloud Console → criar um OAuth Client ID do tipo iOS para `com.borah.app`, formato `com.googleusercontent.apps.<client-id>`).

## Google Places — dependência de secret (IOS-PLACES-02)

`AppEnvironment.googlePlacesApiKey` (`String.fromEnvironment('GOOGLE_PLACES_API_KEY')`, sem `defaultValue`) precisa do `--dart-define=GOOGLE_PLACES_API_KEY=...` presente na compilação — sem ele, a busca de restaurantes via Google Places falha imediatamente com uma mensagem genérica (`GooglePlacesMissingApiKeyException`), antes de qualquer chamada de rede. O job `build_release_ios` (`.github/workflows/release.yml`) já injeta essa flag a partir do secret `GOOGLE_PLACES_API_KEY_PRODUCTION` (ver `CI_CD_SECRETS.md` §2.1) — **mas o secret ainda não foi cadastrado no GitHub**, então, assim como os demais secrets desta seção, o build atual da CI continua funcionalmente vazio nesse campo até que seja cadastrado.

Isso **não corrige** o runtime iOS por si só: nenhum `.ipa` foi gerado nem testado em dispositivo real nesta rodada (mesma limitação de ambiente já documentada acima — sem Mac/Xcode). O Google Places no iOS continua **não confirmado em runtime**.

## Permissões (`Info.plist`)

Só `NSPhotoLibraryUsageDescription` (seleção de avatar/fotos via `image_picker`) — câmera, localização e notificações não são usadas, sem chaves correspondentes. Deep link `borah://password-recovery` registrado (mesmo esquema do Android) para o fluxo de recuperação de senha do `supabase_flutter`.

## Assets

`AppIcon.appiconset`: todos os tamanhos obrigatórios presentes (20pt–1024pt, @1x/@2x/@3x), gerados por `flutter_launcher_icons` a partir de arte real. `LaunchScreen.storyboard`: já reflete o símbolo real do BORAH (`flutter_native_splash` já rodou para iOS — o storyboard referencia a imagem em 4096×4096, a mesma dimensão do arquivo-fonte, não é mais o placeholder do template).

## O que falta exatamente para gerar um IPA

1. **Rodar `pod install` num Mac real** — primeira vez que este projeto passaria por isso; o `Podfile` já existe e tem sintaxe válida, mas resolver as dependências só é verificável de fato lá.
2. **Conta Apple Developer Program ativa**, com `DEVELOPMENT_TEAM` selecionado no Xcode (ou via `xcodebuild -allowProvisioningUpdates`).
3. **Provisioning Profile + Certificate de distribuição** válidos para `com.borah.app` (automático pelo Xcode assim que a conta estiver logada).
4. **Substituir o placeholder do Google Client ID iOS** (não bloqueia o IPA, mas o login Google fica quebrado até então).
5. `flutter build ipa` (ou Xcode Organizer → Archive → Distribute App).

Nenhum destes 5 itens é código.

## Checklist Apple

- [x] `PRODUCT_BUNDLE_IDENTIFIER` estável e definitivo
- [x] `Info.plist` com as permissões necessárias
- [x] `Podfile` existe e é sintaticamente válido
- [x] Ícone/splash gerados a partir de arte real
- [ ] `pod install` executado com sucesso num Mac real
- [ ] Conta Apple Developer Program
- [ ] `DEVELOPMENT_TEAM`/Provisioning Profile/Certificate
- [ ] Google Client ID iOS real
- [ ] Build testada em dispositivo/simulador real
- [ ] `.ipa` gerado

Nenhum item pendente é código.
