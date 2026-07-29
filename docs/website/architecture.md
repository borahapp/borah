# Website Institucional — Arquitetura

**Contexto:** BETA-11B. Documenta a implementação do site institucional em `site/`, construído a partir das decisões já aprovadas em `docs/release/hosting.md` (BETA-10D) e do conteúdo já aprovado em `docs/legal/` (BETA-09B1) e `docs/store/` (BETA-10E).

---

## 1. Decisão de tecnologia

**HTML/CSS/JS estático, sem framework, com um único script Node.js de build para as páginas jurídicas.**

### Justificativa técnica

O repositório já tinha um documento (`docs/FASE 8 - Marketing/MK-02_LANDING_PAGE.md`) propondo Next.js/Astro + Cloudflare Pages/Vercel + GA4/GTM/Meta Pixel/Hotjar para a landing page. **Esta rodada diverge deliberadamente dessa proposta** pelos seguintes motivos:

1. **`docs/release/hosting.md` (BETA-10D) já é uma decisão mais recente e mais bem fundamentada no contexto real do projeto** — pessoa física, sem verba de marketing, zero contas de terceiros criadas até aqui (Sentry e PostHog são as únicas exceções, já auditadas e necessárias para observabilidade do app). MK-02 é um documento de planejamento anterior, mais aspiracional ("máquina de marketing versão 2.0"), escrito antes da decisão de hospedagem ter sido tomada.
2. **O site tem 6 páginas, todas de conteúdo estático** (Home, Sobre, Suporte, Contato, Privacidade, Termos). Não há necessidade de SSR, roteamento dinâmico, API routes ou build incremental — exatamente o caso de uso para o qual frameworks como Next.js/Astro adicionam complexidade sem benefício proporcional.
3. **Zero dependências novas** — nenhum `package.json`, `node_modules`, ou build step além de um script Node.js de ~250 linhas sem nenhum pacote npm (usa apenas `node:fs`, `node:path`, `node:url` da biblioteca padrão). Isso elimina uma superfície inteira de risco (supply chain de dependências JS) que um framework completo introduziria.
4. **Consistência com a hospedagem já decidida (GitHub Pages)** — GitHub Pages serve arquivos estáticos diretamente; um framework com build step exigiria um workflow de Actions adicional só para gerar o output, quando o objetivo é publicar arquivos HTML já prontos.
5. **Zero contas de terceiros novas** — Cloudflare Pages/Vercel exigiriam uma nova conta e um novo provedor de credenciais, replicando o mesmo raciocínio já aplicado em BETA-10D para descartar essas opções para hospedagem.

Essa divergência de MK-02 é intencional e documentada aqui para que futuras rodadas não tratem MK-02 como a decisão vigente — `docs/release/hosting.md` e este documento são as fontes de verdade atuais para a arquitetura do site.

### Por que um script de build para as páginas jurídicas (e só para elas)

`docs/legal/privacy_policy.md` e `terms_of_use.md` já são conteúdo jurídico redigido e aprovado (BETA-09B1). Copiar esse texto manualmente para HTML criaria duas fontes de verdade que podem divergir silenciosamente com o tempo (ex.: uma atualização de política feita só no `.md`, esquecida no `.html`). `scripts/build-legal-pages.mjs` resolve isso gerando `site/privacidade/index.html` e `site/termos/index.html` diretamente do Markdown aprovado, a cada execução. As demais páginas (Home, Sobre, Suporte, Contato) não têm uma fonte "de verdade" separada em Markdown — são HTML autoral, então não passam por esse script.

## 2. Estrutura de pastas

```
site/
├── index.html              -> https://www.appborah.com.br/
├── sobre/index.html        -> /sobre/
├── suporte/index.html      -> /suporte/
├── contato/index.html      -> /contato/
├── privacidade/index.html  -> /privacidade/  (GERADO — não editar à mão)
├── termos/index.html       -> /termos/       (GERADO — não editar à mão)
├── CNAME                   -> domínio customizado do GitHub Pages
├── robots.txt
├── sitemap.xml
└── assets/
    ├── css/style.css       -> design system (tokens de docs/design/design_system.md)
    ├── js/main.js          -> menu mobile, acordeão de FAQ, formulários via mailto
    ├── fonts/              -> Fredoka e Manrope (mesmas fontes do app, cópia local)
    └── img/                -> logo, símbolo, ilustrações, ícone, favicon (cópias de app/assets/)

scripts/
└── build-legal-pages.mjs   -> gera site/privacidade e site/termos a partir de docs/legal/
```

## 3. Identidade visual reutilizada (não recriada)

Todos os tokens em `site/assets/css/style.css` vêm diretamente de `app/lib/design_system/brand/{brand_colors,brand_gradients,brand_typography}.dart` e `app/lib/design_system/tokens/{app_spacing,app_radius}.dart` — mesmos valores exatos usados no aplicativo Flutter (roxo `#5B2EFF`, verde `#B8FF3B`, preto "Preto Uva" `#0B0714`, gradiente roxo oficial `#6C47FF → #5B2EFF → #3D19C7`, fontes Fredoka/Manrope, grid de espaçamento de 8px). Nenhum valor foi inventado.

Os ícones/ilustrações (`bite_shape.svg`, `burst_shape.svg`, `curved_arrow.svg`, `symbol_smiling.svg`, `symbol_celebrating.svg`, `borah_symbol.svg`, logos) são cópias somente-leitura dos assets já existentes em `app/assets/` — usados no lugar de screenshots reais do app, que ainda não existem (o app não está publicado nas lojas).

## 4. Waitlist do Beta Fechado e formulário de Contato (BETA-11C)

**Histórico:** na rodada BETA-11B (site 100% estático, proibida qualquer alteração em Supabase/backend), os dois formulários usavam um mecanismo `mailto:` interino. A rodada **BETA-11C** substituiu isso pela integração real com o Supabase, descrita em detalhe em `docs/website/forms.md`. Resumo:

```
Browser → Cloudflare Turnstile → Edge Function (website-form-submit, service_role) → INSERT
```

O papel `anon` **não** recebe nenhum privilégio em `beta_waitlist`/`contact_messages` — mantém a invariante já documentada em `supabase/migrations/20260720130000_grant_authenticated_privileges.sql` ("anon não recebe nada"). Todo INSERT passa por uma única Edge Function (`website-form-submit`), que valida o Turnstile, o honeypot e o tempo mínimo de preenchimento antes de gravar usando `service_role`. Ver `docs/website/forms.md` para o desenho completo (schema, RLS, fluxo de erro, secrets necessários).

## 5. Restrições respeitadas

Conforme instrução explícita do usuário para esta rodada: nenhuma alteração foi feita em `app/` (Flutter), nenhuma alteração em `supabase/`, nenhum novo backend, nenhuma nova conta de terceiros criada. Todas as mudanças estão contidas em `site/`, `scripts/build-legal-pages.mjs` e `docs/website/`.
