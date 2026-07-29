# Website Institucional — Deploy e Configuração de Domínio

**Contexto:** BETA-11B. A decisão de hospedagem (GitHub Pages) já foi tomada e justificada em `docs/release/hosting.md` (BETA-10D) — este documento cobre apenas os passos operacionais de publicação, que **não foram executados nesta rodada** (a rodada termina com o site pronto para publicação, não publicado).

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

## 2. Passos de publicação (ação futura, fora desta rodada)

1. **Configurar GitHub Pages** no repositório: Settings → Pages → Source → escolher a branch (`main`, após merge do `develop`) e a pasta `/site`.
2. **Aguardar o certificado TLS automático** do GitHub Pages ser emitido para o domínio customizado (pode levar até 24h na primeira configuração).
3. **Habilitar "Enforce HTTPS"** em Settings → Pages assim que o certificado estiver disponível.
4. **Verificar que o arquivo `CNAME`** (já criado, conteúdo `appborah.com.br`) foi de fato publicado na raiz do site pelo GitHub Pages — ele é regenerado automaticamter a cada deploy a partir do arquivo em `site/CNAME`, então não deve ser removido do repositório.

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

## 6. Automação futura (fora do escopo desta rodada)

Um workflow de GitHub Actions dedicado (ex.: `.github/workflows/pages.yml`) pode rodar `node scripts/build-legal-pages.mjs` automaticamente e publicar `site/` a cada push na branch de produção, eliminando o passo manual acima. Não foi criado nesta rodada por não ter sido pedido e por envolver decisão adicional sobre gatilho/trigger do workflow.
