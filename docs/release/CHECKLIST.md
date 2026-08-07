# Release Checklist — Build & CI (BORAH)

Checklist reutilizável de engenharia de build/release — usar antes de **toda** tag `v*.*.*`, não só na primeira. Para o checklist mais amplo de infraestrutura/loja/marketing (domínio, Sentry/PostHog, Data Safety, screenshots), ver `docs/release/release_checklist.md`. Para o estado datado de uma rodada específica, ver `RC01_RELEASE_READINESS.md` (snapshot, não um checklist reaproveitável).

## Antes de criar a tag

- [ ] `pubspec.yaml` com a versão correta (`VERSIONING.md`) — build number maior que o último já publicado em cada loja
- [ ] `flutter analyze` limpo localmente
- [ ] `flutter test` 100% localmente
- [ ] `dart format --set-exit-if-changed .` limpo localmente
- [ ] Commit da versão já está em `main`, revisado via PR normal

## Secrets (ver `SECRETS.md` para a lista completa)

- [ ] Environment `qa` com os 3 secrets de Integration Test cadastrados
- [ ] Environment `production` com os 12 secrets de Produção cadastrados (2 Supabase + 4 Sentry + 2 PostHog + 4 Android)
- [ ] `POSTHOG_HOST_PRODUCTION` **nunca vazio**, se cadastrado (ver aviso em `SECRETS.md`)
- [ ] "Required reviewers" configurado no Environment `production`

## Android (ver `ANDROID_RELEASE.md`)

- [ ] Keystore de release real gerada e custodiada (nunca em texto puro)
- [ ] `android/key.properties` presente e correto (só em ambiente local — nunca comitado)
- [ ] `flutter build apk --release`/`appbundle --release` sem erros
- [ ] AAB assinado com a keystore real (não a de debug) antes de subir à Play Console
- [ ] **Pendência registrada, não bloqueante hoje** — Deep Link de convite de grupo (`core/deep_link/`) usa esquema customizado (`borah://group/join`) até aqui; migrar para Android App Links reais (`https://appborah.com.br/...`, verificado via `assetlinks.json`) depende do fingerprint SHA-256 da keystore de release acima — só é possível gerar o `assetlinks.json` final depois que essa keystore existir. Mesma dependência já vale para iOS Universal Links (`apple-app-site-association`, depende do Team ID do Apple Developer Program).

## iOS (ver `IOS_RELEASE.md`)

- [ ] `pod install` executado com sucesso num Mac real
- [ ] Conta Apple Developer Program ativa, `DEVELOPMENT_TEAM` configurado
- [ ] Provisioning Profile + Certificate de distribuição válidos
- [ ] Google Client ID iOS real (não o placeholder) em `Info.plist`
- [ ] `flutter build ipa` sem erros
- [ ] Testado em pelo menos um dispositivo/simulador real antes de enviar ao TestFlight

## Após criar a tag

- [ ] `release.yml` executado com sucesso (`build_release` + `build_release_ios`)
- [ ] `release-apk`/`release-aab` conferidos (baixar o artefato, instalar num dispositivo de teste)
- [ ] GitHub Release criado automaticamente com os 2 artefatos anexados
- [ ] Upload do `mapping.txt` ao Sentry confirmado no dashboard (se `SENTRY_AUTH_TOKEN` estiver cadastrado)

## Antes de enviar às lojas

- [ ] Checklist de infraestrutura/loja completo (`docs/release/release_checklist.md`): domínio, Política de Privacidade publicada, Data Safety/App Privacy preenchidos, screenshots, Feature Graphic
- [ ] `RC01_RELEASE_READINESS.md` (ou o snapshot equivalente da rodada atual) sem nenhum item de código pendente

## Regra geral

**Nenhum item de código nunca deve ficar pendente neste checklist.** Se algo aqui estiver marcado como pendente e for código (não conta/credencial/asset), é um bug de processo — corrigir antes de seguir, não documentar como "aceitável" indefinidamente.
