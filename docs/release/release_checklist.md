# Release Checklist — BORAH

**Contexto:** BETA-10D. Checklist consolidado de tudo o que falta antes da primeira publicação (Beta Fechado). Atualiza e substitui, para fins de acompanhamento, a visão dispersa das rodadas BETA-04/08/09/10A.

**Nota da RC-01 (2026-08-02):** este documento cobre infraestrutura/loja/marketing. Para o checklist reutilizável de engenharia de build/CI (o que rodar antes/depois de cada tag de release), ver `docs/release/CHECKLIST.md`. O item "Upload automático de mapping R8/dSYM" abaixo está desatualizado para Android — ver correção na linha correspondente.

| Categoria | Item | Status |
|---|---|---|
| **Infraestrutura** | Supabase de Produção provisionado, migrations aplicadas | ✅ Concluído |
| | Paridade Dev/QA/Produção confirmada | ✅ Concluído |
| | GitHub Environment `production` documentado | 🟡 Parcial — documentado, não criado no GitHub ainda |
| **Domínio** | `appborah.com.br` — estrutura de hospedagem definida | 🟡 Parcial — arquitetura proposta (`hosting.md`), site não construído |
| | Configuração de DNS | 🔴 Pendente — ação do proprietário |
| **Hospedagem** | Solução escolhida e justificada | ✅ Concluído — GitHub Pages |
| | Site estático implementado | 🔴 Pendente |
| | Deploy automatizado (Actions) | 🔴 Pendente |
| **URLs** | `/privacidade`, `/termos`, `/suporte` — conteúdo pronto | ✅ Concluído (`docs/legal/`) |
| | `/` (home) e `/contato` — conteúdo redigido | 🔴 Pendente |
| | URLs publicadas e acessíveis | 🔴 Pendente |
| **Analytics** | Instrumentação de eventos (PostHog) | ✅ Concluído (BETA-08A) |
| | Guia de setup de Produção | ✅ Concluído (`POSTHOG_PRODUCTION_SETUP.md`) |
| | Projeto PostHog de Produção criado | 🔴 Pendente |
| | Secrets cadastrados (`POSTHOG_API_KEY_PRODUCTION`/`POSTHOG_HOST_PRODUCTION`) | 🔴 Pendente |
| | Decisão de retenção de dados no PostHog | 🔴 Pendente |
| **Observabilidade** | Integração Sentry no app | ✅ Concluído (RC-03A) |
| | Guia de setup de Produção | ✅ Concluído (consolidado nesta rodada) |
| | Projeto Sentry de Produção criado | 🔴 Pendente |
| | Secret cadastrado (`SENTRY_DSN_PRODUCTION`) | 🔴 Pendente |
| | Upload automático de mapping R8 (Android) | 🟡 Parcial — plugin `io.sentry.android.gradle` configurado desde a OBS-01A (posterior a este checklist), só falta o secret `SENTRY_AUTH_TOKEN` ser cadastrado (ver `docs/release/SECRETS.md`) |
| | Upload automático de dSYM (iOS) | 🔴 Pendente — não configurado, e só verificável num Mac real |
| | Alertas configurados | 🔴 Pendente |
| **GitHub** | Environment `production` criado | 🔴 Pendente |
| | Secrets QA já cadastrados (presumido, herdado da QA-03) | 🟡 Parcial — não confirmável por este chat |
| **Segredos** | 12 secrets de Produção documentados (Android ×4, Supabase ×2, Sentry ×4, PostHog ×2 — ver `docs/release/SECRETS.md`) | ✅ Documentado — 0 cadastrados |
| **Apple** | Conta Apple Developer Program | 🔴 Pendente |
| | `DEVELOPMENT_TEAM` configurado | 🔴 Pendente |
| | Certificados/Provisioning Profiles | 🔴 Pendente |
| | Build iOS validada num Mac real | 🔴 Pendente (nunca executada em nenhum ambiente) |
| | `PrivacyInfo.xcprivacy` validado no Xcode | 🟡 Parcial — rascunho pronto (`docs/apple/`), não validado |
| **Google** | Conta Google Play Console | 🔴 Pendente |
| | Build Android de Release validada | ✅ Concluído (BETA-10B — AAB gerado com sucesso) |
| | Keystore real gerada | 🔴 Pendente |
| **Assets** | Ícone/splash/logo | ✅ Concluído (IV-01 a IV-09) |
| | Ícone Google Play 512px | ✅ Concluído |
| | Screenshots Android/iPhone | 🔴 Pendente |
| | Feature Graphic | 🔴 Pendente |
| | App Preview (vídeo) | 🔴 Pendente (opcional) |
| **Store Listing** | Nome, descrições curta/completa | 🔴 Pendente |
| | Categoria/Tags | 🔴 Pendente |
| | Data Safety (Google) | 🟡 Parcial — inventário e texto prontos (BETA-08C/09B), formulário não preenchido |
| | App Privacy (Apple) | 🟡 Parcial — mesmo status |
| | Classificação indicativa/etária | 🔴 Pendente |
| | Preço/países | 🟡 Parcial — gratuito já definido, países não decididos |

## Resumo por status

- **✅ Concluído**: 11 itens — majoritariamente engenharia (Supabase, build Android, instrumentação, assets visuais).
- **🟡 Parcial**: 10 itens — documentação/arquitetura prontas, execução real pendente.
- **🔴 Pendente**: 20 itens — majoritariamente contas externas, conteúdo de marketing e assets de captura.

**Leitura geral**: a engenharia de plataforma está, na prática, concluída (Android validado de ponta a ponta, iOS auditado e pronto para a primeira tentativa real). O que resta é quase inteiramente operacional — contas (Apple/Google/Sentry/PostHog), hospedagem do domínio e produção de conteúdo/assets de loja — consistente com a avaliação já registrada ao final da BETA-10C1.
