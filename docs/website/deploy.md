# Website Institucional — Deploy e Configuração de Domínio

**Contexto:** BETA-11B, atualizado em BETA-11C e BETA-11D.1. A decisão de hospedagem (GitHub Pages) já foi tomada e justificada em `docs/release/hosting.md` (BETA-10D). O workflow de publicação (`.github/workflows/pages.yml`) foi criado no BETA-11D.1, mas **ainda não foi executado** — falta habilitar a fonte "GitHub Actions" nas Settings do repositório e autorizar o merge `develop` → `main`, ambos pendentes de ação/aprovação explícita do proprietário.

## 1. Pré-requisitos já atendidos por esta rodada

- Pasta `site/` completa com as 6 páginas, `CNAME`, `robots.txt`, `sitemap.xml` e todos os assets.
- Conteúdo jurídico gerado a partir da fonte aprovada (`scripts/build-legal-pages.mjs`).

## 1.1. Deploy da Edge Function e migrations (BETA-11C, ação futura)

Antes de publicar o site com os formulários reais, aplicar o backend:

```bash
supabase db push                          # aplica as 2 migrations novas
supabase functions deploy website-form-submit
supabase secrets set TURNSTILE_SECRET_KEY=<valor-real-do-cloudflare>
```

Depois, substituir os 3 placeholders descritos em `docs/website/forms.md`, seção 8 (`FUNCTIONS_URL` em `main.js`, `data-sitekey` nos 3 formulários) pelos valores reais, antes de publicar `site/`.

## 2. Passos de publicação

**BETA-11D.1** criou `.github/workflows/pages.yml`, que publica automaticamente o conteúdo de `site/` a cada push em `main`, usando as Actions oficiais do GitHub Pages (`actions/configure-pages`, `actions/upload-pages-artifact`, `actions/deploy-pages`). Por que um workflow em vez do modo "Deploy from a branch" das Settings: o GitHub Pages, nesse modo, só publica a partir da raiz do repositório ou de `/docs` — nenhuma das duas opções serve, já que o site vive em `site/` (e `docs/` já é usado para toda a documentação de engenharia do projeto). O workflow contorna essa limitação publicando exatamente a pasta `site/`, sem mover nada.

Passos restantes (ação futura, ainda não executados):

1. **Habilitar GitHub Pages com fonte "GitHub Actions"** no repositório: Settings → Pages → Source → `GitHub Actions` (não "Deploy from a branch" — o workflow já cuida disso). Isso só precisa ser feito uma vez.
2. **Fazer o merge `develop` → `main`** (aguardando autorização explícita separada — ver `docs/launch/rollback_plan.md`/decisão do proprietário) — o workflow só roda em push para `main`.
3. **Aguardar o certificado TLS automático** do GitHub Pages ser emitido para o domínio customizado (pode levar até 24h na primeira configuração).
4. **Habilitar "Enforce HTTPS"** em Settings → Pages assim que o certificado estiver disponível.
5. **Verificar que o arquivo `CNAME`** (já criado, conteúdo `appborah.com.br`, dentro de `site/`) foi de fato publicado na raiz do site pelo GitHub Pages — o `actions/upload-pages-artifact` inclui esse arquivo automaticamente por estar dentro do `path: "./site"`, então não deve ser removido do repositório.

## 3. Configuração de DNS (ação exclusiva do proprietário do domínio, fora do repositório)

Já documentada em `docs/release/hosting.md`, seção 4 — reproduzida aqui por conveniência:

1. Criar um registro `CNAME` para o subdomínio `www` apontando para `<usuario-ou-organizacao>.github.io`.
2. Opcionalmente, registros `A` para o ápice do domínio (`appborah.com.br` sem `www`) apontando para os IPs públicos do GitHub Pages (documentados na documentação oficial do GitHub Pages).
3. Aguardar propagação de DNS (pode levar de minutos a até 48h, dependendo do provedor).

## 4. Verificação pós-deploy (checklist para quando a publicação ocorrer)

- [ ] `https://www.appborah.com.br/` carrega com certificado HTTPS válido.
- [ ] Todas as 6 páginas acessíveis nos caminhos documentados em `pages.md`.
- [ ] `sitemap.xml` e `robots.txt` acessíveis nas URLs raiz.
- [ ] Links do rodapé/nav funcionando em todas as páginas (nenhum 404).
- [ ] Formulários (Beta e Contato) gravando corretamente em `beta_waitlist`/`contact_messages`, incluindo o caso de e-mail duplicado.
- [ ] Widget do Turnstile carregando e validando nos 3 formulários (verificar `data-sitekey` real, não o placeholder).
- [ ] Registrar a propriedade no Google Search Console (ver `seo.md`, seção 5) e submeter o sitemap.
- [ ] (Opcional, quando decidido) Conectar Google Analytics conforme `seo.md`, seção 6.

## 5. Fluxo de atualização de conteúdo jurídico após o deploy

Sempre que `docs/legal/privacy_policy.md` ou `terms_of_use.md` forem atualizados:

```bash
node scripts/build-legal-pages.mjs
```

Isso regenera `site/privacidade/index.html` e `site/termos/index.html`. Sem esse passo, o site publicado ficaria com uma versão desatualizada do texto jurídico.

## 6. Workflow de publicação (`.github/workflows/pages.yml`, BETA-11D.1)

```yaml
on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write
```

Só publica em push para `main` (ou disparo manual via `workflow_dispatch`) e usa `concurrency: { group: "pages", cancel-in-progress: false }` para nunca deixar duas publicações sobrepostas em andamento. As permissões seguem o mínimo exigido pelas Actions oficiais de Pages (`contents: read` para o checkout, `pages: write` para publicar, `id-token: write` para a Action assinar o deploy via OIDC) — esta é a primeira vez que um workflow do projeto declara um bloco `permissions:` explícito.

**Lacuna conhecida (não resolvida neste ajuste):** o workflow **não** roda `node scripts/build-legal-pages.mjs` antes de publicar — continua sendo um passo manual (seção 5) antes de qualquer merge para `main`. Se uma atualização em `docs/legal/*.md` for mesclada sem rodar o script antes, o site publicado ficará com uma versão desatualizada das páginas jurídicas. Automatizar esse passo dentro do workflow fica como melhoria futura, fora do escopo pedido para o BETA-11D.1 (que pediu especificamente as 3 Actions oficiais de Pages, sem alterar a estrutura do projeto).
