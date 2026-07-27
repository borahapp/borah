# Hospedagem do Domínio Oficial — `appborah.com.br`

**Contexto:** BETA-10D. Nenhuma infraestrutura de hospedagem existe hoje neste repositório — confirmado por auditoria (nenhum `firebase.json`, `vercel.json`, workflow de Pages, ou pasta de site; `app/web/` é só o alvo padrão do `flutter create`, não usado como plataforma-alvo desde a decisão "mobile-only" do EX-01). Este documento propõe a arquitetura mais simples possível para publicar as 3 páginas já redigidas (`docs/legal/`) em `https://www.appborah.com.br`.

---

## 1. Comparação de soluções de hospedagem

| | GitHub Pages | Cloudflare Pages | Firebase Hosting | Vercel |
|---|---|---|---|---|
| Conta nova necessária | **Não** — já usamos GitHub para tudo | Sim | Sim (+ projeto Google Cloud) | Sim |
| Custo | Gratuito | Gratuito | Gratuito (tier baixo) | Gratuito (tier baixo) |
| Domínio customizado + HTTPS automático | ✅ Sim, nativo | ✅ Sim | ✅ Sim | ✅ Sim |
| Adequado para site 100% estático | ✅ Perfeito | ✅ Sim (mas oferece muito mais do que precisamos) | 🟡 Sim, mas acopla ao ecossistema Google sem necessidade | 🟡 Sim, mas seu diferencial é para apps dinâmicos/SSR |
| Deploy a partir do mesmo repositório do BORAH | ✅ Direto, via Actions ou pasta `docs/` | Precisa conectar o repo a uma conta separada | Precisa de CLI própria (`firebase deploy`) | Precisa conectar o repo a uma conta separada |
| Superfície de credenciais/contas adicional | Nenhuma | +1 conta/token | +1 conta/projeto | +1 conta/token |

## 2. Decisão

**Escolhida: GitHub Pages.**

### Justificativa técnica

1. **Zero conta nova** — o projeto já vive inteiramente no GitHub (código, Actions, Secrets, Environments). Adicionar Cloudflare, Firebase ou Vercel só para hospedar 5 páginas estáticas introduziria mais uma conta, mais um provedor de credenciais e mais uma superfície de risco, sem nenhum ganho técnico proporcional — mesma lógica já aplicada em rodadas anteriores para evitar dependências externas desnecessárias.
2. **O conteúdo é 100% estático** — Política de Privacidade, Termos de Uso e Suporte já existem como Markdown aprovado (`docs/legal/`), sem necessidade de servidor, função de borda, banco de dados ou build complexo. GitHub Pages foi desenhado exatamente para este caso de uso.
3. **Domínio customizado com HTTPS automático nativo** — um arquivo `CNAME` na pasta publicada + configuração de DNS (registro `CNAME`/`A` apontando para o GitHub Pages) resolve `www.appborah.com.br` com certificado TLS gerenciado automaticamente pelo GitHub, sem custo e sem renovação manual.
4. **Deploy a partir do mesmo lugar onde o conteúdo-fonte já vive** — nenhuma duplicação de infraestrutura de CI/CD; o site pode ser publicado a partir de um workflow de GitHub Actions próprio (`.github/workflows/pages.yml`, a ser criado numa rodada de implementação futura) ou diretamente de uma pasta do repositório, sem introduzir um pipeline de deploy paralelo em outro provedor.

### Alternativas descartadas

- **Cloudflare Pages** — CDN e capacidade de edge functions excelentes, mas nenhum dos dois é necessário para 5 páginas institucionais; exigiria uma conta nova só para isso.
- **Firebase Hosting** — acoplaria o projeto ao ecossistema Google (Firebase/GCP) sem nenhum motivo técnico, já que todo o backend do BORAH já é Supabase; redundante.
- **Vercel** — otimizado para aplicações com build/SSR (Next.js e afins); todo o seu diferencial (preview deployments por PR, funções serverless) é desnecessário para um site estático de conteúdo jurídico/institucional.

## 3. Arquitetura proposta (para implementação futura, não construída nesta rodada)

```
site/                          <- pasta nova, ainda não criada
├── index.html                 -> https://www.appborah.com.br/
├── privacidade/index.html     -> https://www.appborah.com.br/privacidade
├── termos/index.html          -> https://www.appborah.com.br/termos
├── suporte/index.html         -> https://www.appborah.com.br/suporte
├── contato/index.html         -> https://www.appborah.com.br/contato
└── CNAME                      -> conteúdo: appborah.com.br
```

- Cada página é HTML estático gerado a partir do Markdown já aprovado em `docs/legal/` (conversão simples, sem framework — mesmo texto, sem reescrever conteúdo jurídico já revisado).
- `/contato` é uma página nova (não redigida ainda — ver pendência no checklist), com o e-mail de suporte já definido (`Borahh.app@gmail.com`) e, opcionalmente, um formulário estático (ex.: `mailto:` direto, sem backend).
- Publicação via **GitHub Pages a partir da branch `main`, pasta `/site`** (configuração em Settings → Pages do repositório) ou via workflow de Actions dedicado — decisão de implementação para a rodada em que o site for de fato construído.

## 4. Configuração de DNS necessária (ação do proprietário, fora do repositório)

1. No provedor onde `appborah.com.br` foi registrado, criar um registro `CNAME` para `www` apontando para `<usuario-ou-organizacao>.github.io`.
2. Opcionalmente, registros `A` para o ápice do domínio (`appborah.com.br` sem `www`) apontando para os IPs públicos do GitHub Pages, documentados na documentação oficial do GitHub Pages.
3. Habilitar "Enforce HTTPS" em Settings → Pages assim que o certificado for emitido (automático, pode levar até 24h na primeira configuração).

## 5. Pendências desta proposta

- A pasta `site/` ainda não existe — esta rodada só documenta a arquitetura, não a implementa (fora do escopo de "somente documentação").
- O conteúdo de `/contato` ainda não foi redigido.
- A configuração de DNS depende de acesso ao painel do registrador do domínio (ação exclusiva do proprietário).
