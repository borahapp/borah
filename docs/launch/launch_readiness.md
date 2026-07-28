# Launch Readiness — Resumo Consolidado

**Contexto:** BETA-11A. Consolida a auditoria e documentação produzidas em BETA-10B/C/C1/D/E/E1, sem repetir o conteúdo integral de cada uma (ver referências cruzadas ao final). Este é o ponto de partida para os demais documentos desta pasta.

---

## 1. O que já está pronto

| Área | Situação | Evidência |
|---|---|---|
| Backend (Supabase) | Produção provisionada, 30/30 migrations aplicadas, paridade Dev/QA/Produção confirmada | BETA-05, commits `eff9bfc`/`d32f0a0` |
| Build Android de Release | Gerada com sucesso (AAB de 63.914.526 bytes), R8/ProGuard confirmados ativos | BETA-10B, commit `d43b5f6` |
| Bug crítico do Kotlin/KGP | Diagnosticado e corrigido (`sentry_flutter` 8.x→9.x) | BETA-10B |
| Auditoria iOS estática | Completa — `Podfile`, plugins, `Info.plist`, assinatura, todos auditados | BETA-10C |
| Privacy Manifest (rascunho) | Conteúdo pronto, aguardando validação real no Xcode | BETA-10C1, `docs/apple/PrivacyInfo.draft.xcprivacy` |
| Instrumentação de Analytics | 8 eventos conectados (login/cadastro/logout/review/foto/exclusão de conta) | BETA-08A, commit `79fdab7` |
| Documentação jurídica | Política de Privacidade, Termos de Uso, Suporte — primeira versão completa | BETA-09B1, commit `7b9612a` |
| Infraestrutura de release documentada | Hospedagem, secrets por categoria, checklist | BETA-10D, commit `6a8ea68` |
| Presença nas lojas (textos) | Branding, descrições, keywords, FAQ | BETA-10E, commit `2877e47` |
| Especificação visual completa | Design system, ícone, feature graphic, screenshots, storyboard, marketing kit | BETA-10E1, commit `0fbaaa5` |

## 2. O que ainda depende de execução (não documentação)

| Item | Depende de |
|---|---|
| Keystore Android real | Ação do proprietário — geração + custódia segura |
| Conta Google Play Console | Proprietário — registro + verificação de identidade (até 2 dias úteis, BETA-04) |
| Conta Apple Developer Program | Proprietário — enrollment (24h a semanas conforme Individual/Organização, BETA-04) |
| Validação real de build iOS | Acesso a um Mac/Xcode (nunca ocorreu em nenhum ambiente até hoje) |
| Projeto Sentry de Produção | Proprietário — criação de conta |
| Projeto PostHog de Produção | Proprietário — criação de conta + decisão de região (US/EU) |
| Hospedagem do domínio `appborah.com.br` | Proprietário — configuração de DNS + publicação do site (arquitetura já decidida: GitHub Pages, BETA-10D) |
| Produção de assets visuais reais | Depende de build funcional instalável em dispositivo (Android pronto; iOS pendente de Mac) |
| Cadastro dos 9 secrets de Produção no GitHub | Depende dos itens acima existirem primeiro |

## 3. Riscos conhecidos

1. **Build iOS nunca validada em nenhum ambiente real** — é a maior incerteza técnica restante do projeto (BETA-10C).
2. **Upload do mapping R8 ao Sentry não configurado** — crashes de Produção chegariam com stack traces ofuscados até que o plugin `io.sentry.android.gradle` seja adicionado (achado da BETA-10D).
3. **5 das 6 constantes do Privacy Manifest não verificadas contra o schema oficial ao vivo** — precisa de confirmação no editor visual do Xcode antes de promover o arquivo de volta ao target `Runner` (BETA-10C1).
4. **Regra de 12 testadores/14 dias do Google Play** (contas pessoais criadas após 13/11/2023) pode atrasar a transição de Internal Testing para Produção, dependendo do tipo de conta escolhido (BETA-04).
5. **Nenhuma página do site institucional foi construída** — só o conteúdo-fonte (Markdown) existe; a arquitetura de hospedagem está decidida mas não implementada (BETA-10D).

## 4. Bloqueadores diretos de publicação

- Política de Privacidade/Termos **não publicados em nenhuma URL real** — ambas as lojas exigem isso no formulário de submissão.
- Nenhuma conta de loja existe — sem elas, nenhum dos passos seguintes (upload de build, Data Safety, App Privacy) pode começar.
- Nenhum screenshot/Feature Graphic/App Preview produzido — obrigatórios para publicar a ficha da loja.

---

## Referências cruzadas (não duplicadas aqui)

- `docs/FASE 9 - Execution/BETA-10A_*` até `BETA-10E1` (se aplicável) — auditorias originais
- `docs/release/` — hospedagem, secrets, infraestrutura
- `docs/store/` — branding, textos de loja, roteiros
- `docs/design/` — especificações visuais
- `docs/legal/` — documentação jurídica
- `docs/apple/PrivacyInfo.draft.xcprivacy` — manifesto em rascunho
- `docs/operations/CI_CD_SECRETS.md`, `POSTHOG_PRODUCTION_SETUP.md` — segredos e setup técnico
