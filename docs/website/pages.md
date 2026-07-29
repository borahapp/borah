# Website Institucional — Estrutura de Páginas

**Contexto:** BETA-11B.

| Página | Caminho | Fonte de conteúdo |
|---|---|---|
| Home | `/` (`site/index.html`) | Autoral, tagline/proposta de valor de `docs/store/branding.md`, FAQ resumida de `docs/store/faq.md` |
| Sobre | `/sobre/` (`site/sobre/index.html`) | Autoral (propósito, missão, visão, valores) |
| Suporte | `/suporte/` (`site/suporte/index.html`) | FAQ e canais de `docs/legal/support.md` |
| Contato | `/contato/` (`site/contato/index.html`) | Autoral (formulário + e-mail) |
| Privacidade | `/privacidade/` (`site/privacidade/index.html`) | **Gerado** de `docs/legal/privacy_policy.md` — não editar à mão |
| Termos | `/termos/` (`site/termos/index.html`) | **Gerado** de `docs/legal/terms_of_use.md` — não editar à mão |

## Home (`/`)

- **Hero**: eyebrow "Beta Fechado em breve", headline (tagline oficial), descrição curta, CTA primário "Quero participar do Beta" (âncora para `#beta`) e CTA secundário "Conhecer o BORAH" (→ `/sobre/`).
- **Funcionalidades**: 3 cards — avaliações (nota/comentário/fotos), ranking do grupo, gamificação (XP/nível/conquistas).
- **Como funciona**: 5 passos (criar conta → seguir amigos → avaliar → acompanhar ranking → subir de nível), refletindo exatamente as funcionalidades reais listadas em `docs/store/branding.md` (nenhum passo menciona convites/referral, que não existem no app).
- **Beta Fechado (`#beta`)**: formulário nome (opcional) + e-mail, protegido por Cloudflare Turnstile + honeypot, gravado em `beta_waitlist` via a Edge Function `website-form-submit` (BETA-11C — ver `docs/website/forms.md`), mensagem de sucesso/erro inline.
- **FAQ**: 4 perguntas mais relevantes para quem ainda não conhece o app, com link para a lista completa em `/suporte/`.
- **Rodapé completo**: reaproveitado em todas as páginas (ver `renderFooter()` em `scripts/build-legal-pages.mjs` para a versão das páginas geradas, e replicado manualmente nas páginas autorais).

## Sobre (`/sobre/`)

Propósito, missão, visão e 3 valores (grupo em primeiro lugar, avaliações que valem a pena, privacidade por padrão), fechando com uma chamada para a lista de espera do Beta.

## Suporte (`/suporte/`)

FAQ completo de `docs/legal/support.md` (6 perguntas: recuperação de senha, nota de avaliação, edição/exclusão de avaliação, denúncia, exclusão de conta, cópia de dados) + 2 perguntas gerais (gratuidade, idade mínima) + formulário de contato (nome/e-mail/mensagem, gravado em `contact_messages` via a mesma Edge Function do Beta).

## Contato (`/contato/`)

Formulário simples (nome/e-mail/mensagem, mesmo mecanismo do Suporte) + e-mail direto + link de volta para a Central de Ajuda.

## Privacidade e Termos

Gerados por `node scripts/build-legal-pages.mjs` a partir do Markdown já aprovado. **Nunca editar o HTML dessas duas páginas diretamente** — qualquer alteração de conteúdo deve ser feita em `docs/legal/privacy_policy.md`/`terms_of_use.md` e o script deve ser executado novamente antes do deploy.

## Navegação e rodapé

Todas as páginas compartilham o mesmo cabeçalho (logo + 6 links, com toggle de menu mobile abaixo de 760px) e o mesmo rodapé (4 colunas: marca/tagline, Produto, Legal, Contato — 2 colunas abaixo de 760px).
