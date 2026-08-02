# RC-02E — Beta Readiness (consolidado)

**Data:** 2026-08-02

## Resposta objetiva: **NÃO, ainda não** — mas por nenhum motivo de código ou produto

Todo bloqueador que resta é operacional (contas, secrets, execução em ambiente real) ou de produção de assets visuais. Nenhum exige mais decisão de produto ou mais código.

| Frente | Relatório | Veredito |
|---|---|---|
| Infraestrutura de produção | `RC02_INFRASTRUCTURE_REPORT.md` (RC-02A) | 🔴 Operacional — contas, 12 secrets, Redirect URL, Google Client ID iOS, domínio, publicação legal |
| Build real (APK/AAB/IPA) | `RC02_BUILD_REPORT.md` (RC-02B) | 🔴 Não gerado neste sandbox (sem SDK Android/macOS) — código valida limpo (`analyze` 0, `test` 579/579, `format` 0) |
| Ficha de loja (Google/Apple) | `RC02_STORE_REPORT.md` (RC-02C) | ✅ Corrigida nesta sessão (achado real: descrevia o produto anterior ao pivô para Grupos/Rolês) — falta só assets visuais e formulários do Console |
| Smoke Test end-to-end | `RC02_SMOKE_TEST.md` (RC-02D) | 🔴 Roteiro pronto, execução real pendente — requer dispositivo/emulador + backend de produção reais |

## O que precisa acontecer, em ordem, fora deste sandbox

1. Provisionar contas: Google Play Console, Apple Developer, projetos de produção Sentry/PostHog.
2. Cadastrar os 12 secrets (`docs/release/SECRETS.md`) e o Redirect URL de Auth/Google Client ID iOS real.
3. Rodar os builds reais — local com SDK, ou disparando `.github/workflows/release.yml` (já revisado na RC-01D).
4. Executar o roteiro de `RC02_SMOKE_TEST.md` contra a build real + backend de produção.
5. Produzir os assets visuais (ícone já pronto; faltam Feature Graphic e screenshots — roteiro em `docs/store/screenshots.md`, já corrigido).
6. Preencher Data Safety (Google) / App Privacy (Apple) e o questionário de Content Rating usando a ficha corrigida.
7. Publicar Privacy Policy/Terms em URL real e submeter à revisão.

## O que já está genuinamente pronto

- Código: 0 issues de análise, 579/579 testes, formatação consistente, arquitetura auditada (QA-15/QA-15 Final).
- CI/CD: workflow revisado e corrigido (RC-01D).
- Conteúdo de loja: alinhado ao produto real (Grupos/Rolês/Avaliação Coletiva como núcleo).
- Conteúdo legal (Privacy Policy, Terms) redigido.
- Decisão de escopo registrada: Push Notifications fora do Beta fechado (decisão do proprietário).

Nada nesta lista de pendências depende de mais trabalho de código ou de conteúdo neste ambiente — são todas ações que só o proprietário do projeto pode executar (contas, pagamentos, dispositivos reais).
