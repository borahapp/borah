# RC-02A — Infrastructure Report

**Data:** 2026-08-02
**Escopo:** auditoria da infraestrutura necessária para publicar o BORAH em produção e abrir o Beta fechado. Nenhuma alteração de código nesta etapa (só 2 correções de documentação desatualizada, mesma classe de achado já corrigida na RC-01 — ver §"Nota metodológica").

## Nota metodológica — o que esta sessão pode e não pode verificar

Esta sessão **não tem acesso a nenhum painel externo real**: não há login no Google Play Console, App Store Connect, Dashboard do Supabase, Sentry ou PostHog. Tudo abaixo marcado como referente a contas/projetos externos é baseado no que está **documentado no repositório** (relatórios de rodadas anteriores, `docs/launch/production_inventory.md`), não em uma verificação ao vivo feita agora. Onde isso importa, é dito explicitamente. Não vou fingir ter verificado algo que não pude verificar.

---

## Achado principal — conflito real com o critério de aceite da RC-02

**"Push Notifications funcionando" não é uma pendência operacional — é uma funcionalidade que nunca foi implementada.**

Confirmado por dois ângulos:
1. `app/pubspec.yaml` não tem `firebase_messaging`, `flutter_local_notifications`, nem nenhum pacote equivalente de push — zero dependência.
2. Já está documentado explicitamente em `docs/FASE 9 - Execution/RC-04D_RELEASE_READINESS.md`: *"Nenhuma capability adicional (Push Notifications, Sign in with Apple, etc.) está habilitada hoje, consistente com o app não ter nenhuma dessas funcionalidades implementadas."*

O que existe hoje (BLOCO 8) é um sistema de **notificações in-app** — registros na tabela `notifications` do Supabase, criados por triggers de banco (convite de grupo, novo rolê, resposta de presença), exibidos numa tela/badge dentro do app. Isso é real e funciona, mas **não é push** — não chega nada ao dispositivo com o app fechado ou em background.

**Isso é responsabilidade de Desenvolvimento, não Operacional**, e conflita diretamente com a instrução "não desenvolver nenhuma funcionalidade nova" que guiou a RC-01. Implementar push de verdade exigiria, no mínimo: escolher um provedor (Firebase Cloud Messaging é o caminho natural dado que o resto do projeto já usa GCP-adjacent tooling, ou um serviço unificado tipo OneSignal), adicionar o SDK, um fluxo de registro/renovação de token por usuário, uma Edge Function ou job para disparar o push a partir dos mesmos triggers que já criam a notificação in-app, e testar em dispositivo real nas duas plataformas. Não é um ajuste de configuração — é uma sprint própria.

**Decisão do proprietário (2026-08-02): fora do escopo do Beta fechado.** O sistema de notificações in-app já cobre a necessidade imediata de avisar o usuário dentro do app. O critério de aceite da RC-02 foi ajustado — "Push Notifications funcionando" passa para pós-Beta, não bloqueia mais esta sprint. Push real (FCM/APNs) fica registrado como funcionalidade a especificar e construir numa rodada própria, depois do primeiro Beta.

---

## Checklist completo

| Item | Status | Responsável | Verificável por mim agora? |
|---|---|---|---|
| Google Play Console | 🔴 Pendente — nenhuma conta criada | Operacional | Não |
| Apple Developer Program | 🔴 Pendente — nenhuma conta criada | Operacional | Não |
| Supabase Produção (projeto) | ✅ OK — `borah-production` (`uscheppbwhuuwkskhfos`, `sa-east-1`), 30/30 migrations, paridade com Dev confirmada (BETA-05) | — | Não (baseado em `docs/launch/production_inventory.md`, não verificado ao vivo agora) |
| Supabase Produção (secrets no GitHub) | 🔴 Pendente — `SUPABASE_PROD_URL`/`SUPABASE_PROD_ANON_KEY` não cadastrados | Operacional | Sim (ausência de secret é verificável só indiretamente — nenhuma ferramenta desta sessão lista secrets reais do GitHub; baseado em documentação) |
| Storage (buckets/políticas) | ✅ OK — `avatars`/`restaurants`/`review-photos`, RLS revisada na QA-15B sem gaps | — | Sim (código/migrations) |
| Auth (código) | ✅ OK — login/cadastro/recuperação de senha extensivamente testados (QA-01/02) | — | Sim |
| Auth — Redirect URL de produção | 🔴 Pendente — `borah://password-recovery` precisa ser cadastrado em Authentication → URL Configuration no Dashboard do projeto de Produção (achado já documentado na RC-04E) | Operacional | Não |
| OAuth / Google Sign-In (Android) | ✅ OK — fluxo nativo, sem configuração de manifest pendente | — | Sim |
| OAuth / Google Sign-In (iOS) | 🔴 Bloqueado — `Info.plist` ainda com placeholder `PENDENTE-GOOGLE-IOS-CLIENT-ID` | Operacional (Google Cloud Console) | Sim |
| **Push Notifications** | 🔜 **Fora do escopo do Beta fechado** (decisão do proprietário, 2026-08-02) — não implementado, registrado para pós-Beta | Desenvolvimento (futuro) | Sim (ver achado principal acima) |
| Secrets (inventário) | ✅ Documentado, 🔴 0 de 12 cadastrados | Operacional | Sim (`docs/release/SECRETS.md`) |
| GitHub Actions | ✅ OK (config revisada e corrigida na RC-01D) — nunca executada de fato num runner real | — | Sim (código); Não (execução real) |
| Sentry | 🔴 Pendente — projeto de Produção nunca criado; integração no app já pronta (RC-03A) | Operacional | Não (conta); Sim (código) |
| Analytics (PostHog) | 🔴 Pendente — projeto de Produção nunca criado; instrumentação de eventos já pronta (RC-03C/BETA-08A) | Operacional | Não (conta); Sim (código) |
| Domínio (`appborah.com.br`) | 🔴 Pendente — arquitetura de hospedagem decidida (GitHub Pages, `docs/release/hosting.md`), site nunca construído, DNS não configurado | Operacional | Não |
| Deep Links | ✅ OK no código (Android + iOS registrados) — 🔴 pendente o cadastro no Dashboard (mesmo item de "Auth — Redirect URL" acima) | Misto | Sim (código) |
| Ícones | ✅ OK — gerados a partir de arte real, Android e iOS | — | Sim |
| Splash | ✅ OK — gerado a partir de arte real, Android e iOS | — | Sim |
| Versionamento | ✅ OK — `1.0.0+1`, fonte única, documentado em `docs/release/VERSIONING.md` | — | Sim |
| Privacy Policy | 🟡 Parcial — conteúdo pronto (`docs/legal/privacy_policy.md`), não publicado em URL real | Operacional | Sim (conteúdo); Não (publicação) |
| Terms of Service | 🟡 Parcial — mesmo status (`docs/legal/terms_of_use.md`) | Operacional | Sim (conteúdo); Não (publicação) |

## Housekeeping desta auditoria

Corrigidas 2 inconsistências em `docs/launch/production_inventory.md` (mesma classe de achado já corrigida na RC-01 em 3 outros documentos): a tabela de Sentry ainda dizia "nenhum plugin `io.sentry.android.gradle` configurado" e o resumo de secrets ainda contava 9 em vez de 12 — ambos desatualizados desde a rodada OBS-01A, que veio depois deste documento ter sido escrito.

## Resumo por responsável

- **Desenvolvimento:** nenhum bloqueador de código restante — Push Notifications foi movido para pós-Beta (decisão do proprietário).
- **Operacional (a grande maioria):** contas (Google Play, Apple, Sentry, PostHog), 12 secrets, Redirect URL de produção, Google Client ID iOS real, domínio/hospedagem, publicação de Privacy Policy/Terms.
- **Já OK, nada a fazer:** Supabase (projeto), Storage, Auth (código), OAuth Android, ícones, splash, versionamento, GitHub Actions (config).

## Resposta objetiva

**O BORAH pode entrar em Beta fechado hoje? Ainda não, mas não por nenhum motivo de código.** Com Push Notifications fora do escopo desta sprint (decisão registrada acima), todo bloqueador restante é operacional — contas, secrets, e a execução real dos builds em um ambiente com SDK Android/macOS (nenhum disponível nesta sessão, ver `RC01_RELEASE_READINESS.md`). Nada aqui exige uma decisão de produto adicional — só ação.
