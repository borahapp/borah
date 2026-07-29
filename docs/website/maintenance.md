# Website Institucional — Manutenção

**Contexto:** BETA-11B.

## 1. Regra de ouro: conteúdo jurídico nunca é editado em HTML

`site/privacidade/index.html` e `site/termos/index.html` são **gerados**. Qualquer alteração de texto jurídico deve ser feita em `docs/legal/privacy_policy.md` ou `terms_of_use.md`, seguida de:

```bash
node scripts/build-legal-pages.mjs
```

Editar o HTML gerado diretamente funciona até a próxima execução do script, quando a edição manual é silenciosamente sobrescrita.

## 1.1. Regra de ouro: nunca usar caminhos absolutos ("/…")

Todo novo `href`/`src` (asset ou link interno) deve ser relativo — ver `architecture.md`, seção 2.1, para o motivo (bug real de 404 no GitHub Pages, corrigido no BETA-11D.2). Ao adicionar uma página nova ou um novo asset, confirmar com:

```bash
grep -rn 'href="/\|src="/' site/*.html site/*/index.html
```

Sem resultado = sem regressão. As únicas exceções esperadas são `canonical`/`og:url`/`og:image` (sempre absolutos ao domínio de produção) e as URLs dentro de `sitemap.xml`/`robots.txt`.

## 2. Atualizando conteúdo das demais páginas

Home, Sobre, Suporte e Contato são HTML autoral — editar diretamente os arquivos em `site/`. Ao alterar qualquer um deles, replicar manualmente qualquer mudança de navegação ou rodapé nas demais páginas (não há um sistema de includes/templating para essas 4 páginas, diferente das 2 páginas geradas).

## 3. Atualizando o design system do site

`site/assets/css/style.css` reflete os tokens de `app_lib/design_system/brand/*.dart`. Se a identidade visual do app mudar (cores, tipografia, espaçamento), replicar manualmente os novos valores nas variáveis `:root` do CSS — não há import automático entre o projeto Flutter e o site.

## 4. Atualizando o FAQ

- FAQ da Home: 4 perguntas mais gerais, resumo do FAQ completo.
- FAQ do Suporte: espelha `docs/legal/support.md`. Ao atualizar `support.md`, replicar as mudanças relevantes no HTML de `/suporte/`.
- FAQ de loja (`docs/store/faq.md`, 20 perguntas): fonte usada como referência para as perguntas mais orientadas a conversão na Home — não é 1:1 com o FAQ do site.

## 5. Adicionando novas fotos/screenshots reais do app

Quando o BORAH estiver publicado nas lojas e houver screenshots reais, substituir as ilustrações decorativas (`symbol_celebrating.svg` no hero, etc.) por mockups reais do app, seguindo as especificações já documentadas em `docs/design/screenshots_spec.md` e `storyboard.md`.

## 6. Revisando a waitlist do Beta (BETA-11C)

A lista agora vive na tabela `beta_waitlist` do Supabase — sem painel administrativo no app, a curadoria (marcar `status` como `invited`/`confirmed`/`declined`, preencher `invited_at`/`confirmed_at`) é feita manualmente via Supabase Studio. Ver `docs/website/forms.md`, seção 6, para a semântica completa de cada status.

## 7. Checklist de revisão antes de qualquer deploy

1. `node scripts/build-legal-pages.mjs` (garante que as páginas jurídicas refletem `docs/legal/` mais recente).
2. Abrir cada uma das 6 páginas localmente e verificar links do menu/rodapé.
3. Confirmar que `FUNCTIONS_URL` (`site/assets/js/main.js`) e o `data-sitekey` do Turnstile (3 formulários) foram trocados pelos valores reais — ver `docs/website/forms.md`, seção 8.
4. Testar os 2 formulários (Beta e Contato) em pelo menos um navegador desktop, incluindo o caso de e-mail duplicado.
5. Verificar responsividade (menu mobile, grids colapsando) abaixo de 900px e 760px.
6. `supabase secrets list` para confirmar que `TURNSTILE_SECRET_KEY` está configurado antes do deploy da Edge Function.
7. Rodar novamente a checklist de `deploy.md`, seção 4, após qualquer publicação.
