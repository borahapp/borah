# RC-02B — Build Report

**Data:** 2026-08-02

## Validação de código (real, executada nesta sessão)

| Verificação | Resultado |
|---|---|
| `flutter analyze` | ✅ 0 issues |
| `flutter test` | ✅ 579/579 (100%) |
| `dart format --set-exit-if-changed .` | ✅ 0 arquivos |

## Builds tentados

```
$ flutter build apk --release
[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.

$ flutter build appbundle --release
(mesmo erro)

$ flutter build ios --release --no-codesign
(não tentado — requer macOS, indisponível por definição neste ambiente)
```

**Não tentei repetir esses comandos várias vezes.** "Repetir até ficar verde" pressupõe que cada repetição pode revelar um novo problema corrigível — mas isso não é um erro de compilação, é a ausência total do SDK Android neste sandbox (confirmado desde a RC-01A: a política de rede bloqueia `dl.google.com` com `403`, testado diretamente). Repetir o mesmo comando não muda esse fato; só teria sentido repetir depois de uma mudança real de ambiente, que não está ao meu alcance.

## O que isso significa

- **Não é um bug de código.** `analyze`/`test`/`format` — as três verificações que não dependem de SDK nativo — estão limpas.
- **Não é uma regressão desta sessão.** É a mesma limitação de ambiente documentada desde a RC-01A/RC01_RELEASE_READINESS.md.
- **Já foi contornado uma vez.** Uma sessão anterior, com acesso a um SDK Android real, completou `flutter build appbundle --release` com sucesso (`docs/operations/CI_CD_SECRETS.md §2.2`).

## Caminho real para gerar os 3 artefatos

| Artefato | Onde gerar | Comando exato |
|---|---|---|
| `app-release.apk` | Máquina com SDK Android, ou runner `ubuntu-latest` do GitHub Actions | `flutter build apk --release` + os 5 `--dart-define` de produção (ver `docs/release/BUILD_GUIDE.md`) |
| `app-release.aab` | idem | `flutter build appbundle --release` + mesmos `--dart-define` |
| `.ipa` | Mac real com Xcode + CocoaPods | `flutter build ipa` — requer antes `pod install` bem-sucedido, conta Apple Developer, `DEVELOPMENT_TEAM` (ver `docs/release/IOS_RELEASE.md`) |

O jeito mais reprodutível de obter os dois primeiros **sem depender de nenhuma máquina local**: disparar `.github/workflows/release.yml` de verdade (push de uma tag `v*.*.*`, ou `workflow_dispatch` manual) — já corrigido e revisado na RC-01D, só precisa dos 12 secrets cadastrados (`docs/release/SECRETS.md`) para produzir artefatos funcionalmente completos (sem eles, ainda gera os arquivos, só com `--dart-define` vazios e assinatura de debug).

## Veredito desta etapa

**Código pronto para build. Build real não gerado nesta sessão — ambiente sem SDK Android/macOS, mesma limitação já registrada na RC-01.** Não há mais nada a "corrigir e testar de novo" aqui: a próxima ação concreta é rodar isso num ambiente real (local ou CI), não iterar mais neste sandbox.
