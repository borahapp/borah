# RC-01 — Release Readiness Report

**Data:** 2026-08-02
**Branch:** `claude/turnstile-secret-diagnosis-0g0p82`
**Commit base:** `4ac3242` + as alterações desta sprint (RC-01A a RC-01D — Podfile iOS, `dart format` no `release.yml`), ainda não comitadas no momento em que este documento foi escrito.

Este documento consolida o resultado de RC-01A (auditoria), RC-01B (correções automáticas Android), RC-01C (auditoria/correção iOS) e RC-01D (revisão de CI) num único checklist de prontidão de release.

---

## Artefatos

| Artefato | Status |
|---|---|
| `app-release.apk` | ❌ **Não gerado nesta sessão** — sem SDK Android disponível neste ambiente (ver §"Ambiente" abaixo) |
| `app-release.aab` | ❌ **Não gerado nesta sessão** — mesmo motivo |
| `.ipa` | ❌ Não gerado — requer Mac real + conta Apple Developer (nunca disponível em nenhuma sessão) |

**Nenhum dos três arquivos foi produzido por mim até agora.** Isso não é o mesmo que "o projeto não builda" — é detalhado abaixo.

## Versionamento

| Campo | Valor |
|---|---|
| Version (pubspec.yaml) | `1.0.0+1` |
| Build Name (Android `versionName` / iOS `CFBundleShortVersionString`) | `1.0.0` |
| Build Number (Android `versionCode` / iOS `CFBundleVersion`) | `1` |
| Bundle ID / Application ID | `com.borah.app` (idêntico Android/iOS) |

## Toolchain

| Componente | Versão |
|---|---|
| Flutter | 3.44.6 (fixado via `.fvm/fvm_config.json`, idêntico em CI) |
| Dart | 3.12.2 |
| Android compileSdk | 36 (resolvido via `flutter.compileSdkVersion`) |
| Android targetSdk | 36 (resolvido via `flutter.targetSdkVersion`) |
| Android minSdk | 24 (resolvido via `flutter.minSdkVersion`) |
| NDK | 28.2.13676358 |
| Gradle | 9.1.0 |
| AGP (Android Gradle Plugin) | 9.0.1 |
| Kotlin | 2.3.20 (JVM target 17) |
| Java | 17 |
| iOS Deployment Target | 13.0 |
| Swift | 5.0 |

## Qualidade

| Verificação | Resultado |
|---|---|
| `flutter analyze` | ✅ **0 issues** |
| `flutter test` | ✅ **579/579 (100%)** |
| `dart format --set-exit-if-changed .` | ✅ **0 arquivos** |

## CI (GitHub Actions)

| Item | Status |
|---|---|
| `ci.yml` (Analyze/Test/Build Android debug/Integration Test) | ✅ Estrutura correta (RC-01D) |
| `release.yml` (Build Release Android/iOS) | ✅ Corrigido nesta sprint — `dart format` estava ausente do portão de qualidade, adicionado |
| Execução real no GitHub | ❌ **Nunca executada nesta sessão** — push bloqueado (ver §"Ambiente") |
| Secrets cadastrados | ❌ Nenhum (ver Pendências) |

## Pendências

Nenhuma pendência abaixo é código — todas exigem uma ação humana fora deste ambiente.

1. Cadastrar os secrets de CI (`docs/operations/CI_CD_SECRETS.md`): keystore Android, projeto Supabase de Produção, Sentry/PostHog de Produção.
2. Gerar a keystore Android de release real (`keytool -genkey ...`, ver `android/key.properties.example`).
3. Conta Google Play Console.
4. Conta Apple Developer Program + `DEVELOPMENT_TEAM` configurado no Xcode.
5. Rodar `pod install` num Mac real (o `Podfile` passou a existir nesta sprint, mas nunca foi resolvido de fato).
6. Substituir o placeholder do Google Client ID iOS em `Info.plist`.
7. Publicar Política de Privacidade/Termos em URL real.
8. Produzir assets visuais finais (screenshots, feature graphic) — depende de um build instalável real.
9. **Executar esta CI de verdade no GitHub** — nada disso foi confirmado contra um runner real em nenhuma sessão desta conversa; um `flutter build appbundle --release` foi validado com sucesso numa sessão anterior, mas fora do GitHub Actions.

## Checklist Google Play

- [x] `applicationId` definido e estável (`com.borah.app`)
- [x] `versionCode`/`versionName` corretos
- [x] Ícone adaptativo gerado a partir de arte real
- [x] ProGuard/R8 configurados (minify + shrink)
- [ ] Keystore de release real
- [ ] Conta Google Play Console
- [ ] Política de Privacidade publicada
- [ ] Screenshots/Feature Graphic
- [ ] Build real gerado e testado em dispositivo

## Checklist Apple

- [x] `PRODUCT_BUNDLE_IDENTIFIER` definido e estável (`com.borah.app`)
- [x] `Info.plist` com todas as chaves de permissão necessárias (`NSPhotoLibraryUsageDescription`)
- [x] `Podfile` existe (criado nesta sprint)
- [ ] `pod install` executado com sucesso num Mac real
- [ ] Conta Apple Developer Program
- [ ] `DEVELOPMENT_TEAM`/Provisioning Profile/Certificate
- [ ] Google Client ID iOS real (placeholder ainda presente)
- [ ] Build testado em dispositivo/simulador real
- [ ] `.ipa` gerado

## Ambiente desta sessão (por que os artefatos não foram gerados)

Este sandbox **não tem SDK Android instalado nem instalável** — a política de rede bloqueia `dl.google.com` (testado diretamente nesta sprint: `403` no túnel CONNECT) e **não tem macOS/Xcode** em nenhuma hipótese. Isso não é um problema do projeto:

- `flutter analyze`/`flutter test` — ferramentas puramente Dart, não precisam de SDK nativo, e passam 100%.
- Uma **sessão anterior**, com SDK Android disponível, já validou `flutter build appbundle --release` de ponta a ponta com sucesso (registrado em `docs/operations/CI_CD_SECRETS.md §2.2`).
- O lugar certo para gerar `app-release.apk`/`app-release.aab` de forma reproduzível e verificável é o próprio `release.yml`, rodando num runner `ubuntu-latest` real do GitHub Actions — que já está corrigido e pronto (RC-01D), só falta ser executado de fato (depende de push, hoje bloqueado por permissão deste ambiente) e dos secrets serem cadastrados.

## Pronto para Beta?

**NÃO — ainda não, pelos critérios literais desta sprint** (`app-release.apk`/`app-release.aab` como arquivos existentes). Mas:

- **Código: 100% pronto.** `flutter analyze` limpo, `flutter test` 100%, `dart format` limpo, todas as correções de build automatizáveis (RC-01B/C/D) já aplicadas.
- **CI: pronta, não executada.** `release.yml` geraria os artefatos corretamente num runner real — falta só rodar de verdade (push + tag) e cadastrar os secrets.
- **Nenhum bloqueador restante é código.** Todos os itens de "Pendências" acima são operacionais (contas, credenciais, execução em ambiente real).

Em outras palavras: **o projeto está pronto para que os artefatos sejam gerados**, mas os artefatos em si — o critério de aceite literal desta sprint — ainda não existem, porque nenhuma sessão até agora teve acesso a um ambiente com SDK Android real e execução de CI real ao mesmo tempo.
