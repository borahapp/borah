# Website Institucional — SEO, Analytics e Redes Sociais

**Contexto:** BETA-11B. Segue o mesmo padrão já estabelecido no restante do projeto para serviços externos: "preparado para, não conectado" — nenhuma credencial real ou ID de propriedade foi inserido, apenas a estrutura pronta para receber os valores reais quando existirem.

## 1. Meta tags (implementado em todas as 6 páginas)

Cada página tem: `<title>` único, `<meta name="description">` única, `<link rel="canonical">` apontando para `https://www.appborah.com.br<caminho>`, e o bloco completo de Open Graph (`og:title`, `og:description`, `og:type`, `og:url`, `og:image`) + `twitter:card`.

## 2. Imagem de Open Graph (`og-cover.png`) — pendência real

`site/assets/img/og-cover.png` é hoje uma **cópia interina do ícone do app (1024×1024)**, não uma imagem de Open Graph propriamente dita (proporção recomendada 1200×630). Isso garante que a tag `og:image` não aponte para um arquivo inexistente, mas o resultado visual ao compartilhar o link em redes sociais será o ícone do app centralizado, não um banner otimizado. **Recomendação para rodada futura:** produzir um banner 1200×630 seguindo `docs/design/feature_graphic.md` (mesma peça já especificada para a Google Play) e substituir o arquivo.

## 3. Favicon — pendência real

`site/assets/img/favicon.png` também é hoje uma cópia interina do ícone do app 1024×1024 (os navegadores fazem o downscale automaticamente para os tamanhos de aba/atalho). Não foi gerado um `favicon.ico` multi-resolução nem os tamanhos dedicados (16×16, 32×32, 180×180 para `apple-touch-icon`) por não haver, neste ambiente Windows, uma ferramenta de conversão de imagem disponível sem adicionar uma dependência nova. **Recomendação para rodada futura:** gerar o conjunto completo de favicons (ex.: via qualquer gerador de favicon a partir do `borah_app_icon_1024.png` já existente) e servir os tamanhos dedicados.

## 4. Sitemap e robots

- `site/sitemap.xml` — lista as 6 páginas com `changefreq`/`priority` (Home prioridade 1.0; Privacidade/Termos 0.3, atualização rara).
- `site/robots.txt` — libera todos os user-agents e referencia o sitemap.

## 5. Google Search Console — preparado, não conectado

Ainda não há uma propriedade registrada no Search Console para `appborah.com.br`. Duas formas de verificação estão previstas, ambas comentadas em `site/index.html` até que existam valores reais:
- Meta tag `google-site-verification` (comentada).
- Alternativa: o próprio `CNAME`/DNS já configurado para o GitHub Pages também serve para verificação de domínio via DNS no Search Console, sem precisar de meta tag.

**Ação necessária do proprietário:** criar a propriedade em https://search.google.com/search-console, obter o token de verificação, e descomentar/preencher a meta tag (ou usar a verificação por DNS).

## 6. Google Analytics (GA4) — preparado, não conectado

Snippet padrão do `gtag.js` incluído como comentário em `site/index.html`, com `G-XXXXXXXXXX` como placeholder explícito. **Ação necessária do proprietário:** criar uma propriedade GA4, obter o Measurement ID real, e descomentar o snippet (idealmente replicado nas demais 5 páginas quando ativado).

Nota: como o site não coleta nenhum dado pessoal via backend próprio (formulários são só `mailto:`), ativar o GA4 no futuro exigirá também atualizar `docs/legal/privacy_policy.md` para mencionar o uso de analytics no site institucional (hoje a Política de Privacidade cobre apenas o aplicativo).

## 7. Acessibilidade

- Navegação com `aria-current="page"` no link ativo.
- Botão de menu mobile com `aria-label`/`aria-expanded`.
- Perguntas do FAQ como `<button>` com `aria-expanded`, controlando um painel de resposta.
- Contraste de cor verificado visualmente contra os tokens do design system (texto `--ink`/`--ink-soft` sobre `--paper`/`--paper-alt`, texto branco sobre `--borah-black`/gradiente roxo).
- `prefers-reduced-motion: reduce` desativa transições/animações.
- Todas as imagens decorativas usam `alt=""`.

## 8. Performance

Sem framework, sem bundler, sem JavaScript de terceiros carregado por padrão — o único CSS e o único JS são arquivos locais próprios. Fontes variáveis (`Fredoka-Variable.ttf`, `Manrope-Variable.ttf`) carregadas via `@font-face` com `font-display: swap`, evitando bloqueio de renderização.
