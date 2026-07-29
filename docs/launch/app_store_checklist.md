# Apple App Store Connect — Checklist Completo

**Contexto:** BETA-11A. Consolida BETA-04/06/09/10C/10C1/10E. Cada item classificado por dependência: pode ser preparado agora (neste ambiente Windows), depende de macOS, ou depende exclusivamente da Apple (conta/aprovação/tempo de fila).

---

| # | Item | Pode ser preparado agora | Depende de macOS | Depende da Apple | Situação |
|---|---|:---:|:---:|:---:|---|
| 1 | Conta Apple Developer Program | | | ✅ | 🔴 Não existe — Individual (~24-48h) ou Organização (~1-2 semanas + D-U-N-S, BETA-04) |
| 2 | Bundle ID | ✅ (já definido) | | ✅ (registro no portal) | `com.borah.app` já consistente em todo o projeto — falta só registrar no portal da Apple |
| 3 | `DEVELOPMENT_TEAM` no Xcode | | ✅ | ✅ (precisa do Team ID) | Ausente no `project.pbxproj` (BETA-10C) — depende do item 1 existir primeiro |
| 4 | Certificados de distribuição | | ✅ | ✅ | Gerados automaticamente pelo Xcode (Automatic Signing já configurado, `CODE_SIGN_STYLE = Automatic`) — depende do item 3 |
| 5 | Provisioning Profiles | | ✅ | ✅ | Idem — automático via Xcode, depende do item 3 |
| 6 | `Podfile`/CocoaPods | | ✅ | | Não existe ainda — será gerado automaticamente no primeiro `flutter build ios`/`run` (BETA-10C, confirmado que `sentry_flutter`/`image_picker_ios`/`share_plus` exigem CocoaPods) |
| 7 | Privacy Manifest (`PrivacyInfo.xcprivacy`) | 🟡 Rascunho pronto | ✅ (validação final) | | `docs/apple/PrivacyInfo.draft.xcprivacy` — precisa ser validado no editor visual do Xcode e vinculado ao target `Runner` antes de promover |
| 8 | Build IPA / Archive | | ✅ | ✅ | Nunca executado em nenhum ambiente (Windows não suporta; CI `macos-latest` nunca rodou de verdade, BETA-10C) |
| 9 | App registrado em App Store Connect | | | ✅ | Depende dos itens 1-2 |
| 10 | TestFlight — grupos de teste | | | ✅ | Depende do item 9 — Internal Testing (até 100 usuários, membros da equipe) vs. External Testing (até 10.000, exige revisão da Apple na primeira build, ~24h, BETA-04) |
| 11 | App Privacy | 🟡 Resumo pronto (`docs/store/app_store_listing.md`) | | ✅ (preenchimento) | Preencher usando o inventário já levantado |
| 12 | Export Compliance | ✅ (resposta já sabida) | | ✅ (confirmação no upload) | App usa só HTTPS/TLS padrão para autenticação — isenção padrão de criptografia (BETA-10A); nenhuma chave `ITSAppUsesNonExemptEncryption` pré-declarada, será perguntado no upload |
| 13 | Publicação (TestFlight/App Store) | | | ✅ | Última etapa |
| 14 | Ficha da loja (subtitle, description, keywords) | ✅ Pronto (`docs/store/app_store_listing.md`) | | | Copiar para o App Store Connect quando a conta existir |
| 15 | Screenshots (iPhone 6.9"/iPad 13") | 🟡 Só especificados (`docs/design/`) | ✅ (captura real) | | Produção real depende de build iOS funcional |
| 16 | App Preview | 🟡 Storyboard pronto (`docs/design/storyboard.md`) | ✅ | | Idem |

## Ordem recomendada de execução

1. Decidir Individual vs. Organização (impacta itens 1, 3, 8-9).
2. Criar a conta Apple Developer Program (item 1) — iniciar o quanto antes, é o item de maior variabilidade de tempo (24h a semanas).
3. Assim que possível, abrir o projeto num Mac: configurar `DEVELOPMENT_TEAM` (item 3), rodar `pod install` pela primeira vez (item 6), validar se a build compila (item 8) — **este é o teste definitivo que nunca ocorreu**.
4. Validar/corrigir o Privacy Manifest no editor do Xcode e promovê-lo de volta a `app/ios/Runner/` (item 7).
5. Registrar o app em App Store Connect (item 9), preencher ficha da loja (item 14).
6. Preencher App Privacy e Export Compliance (itens 11-12).
7. Produzir screenshots/App Preview reais a partir da build validada (itens 15-16, BETA-11B).
8. Criar grupo de TestFlight e enviar a primeira build (item 10).
