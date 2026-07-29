# Website Institucional — Manutenção

**Contexto:** BETA-11B.

## 1. Regra de ouro: conteúdo jurídico nunca é editado em HTML

`site/privacidade/index.html` e `site/termos/index.html` são **gerados**. Qualquer alteração de texto jurídico deve ser feita em `docs/legal/privacy_policy.md` ou `terms_of_use.md`, seguida de:

```bash
node scripts/build-legal-pages.mjs
```

Editar o HTML gerado diretamente funciona até a próxima execução do script, quando a edição manual é silenciosamente sobrescrita.

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

## 6. Revisando a waitlist do Beta

O mecanismo atual (`mailto:`) não tem persistência nem contagem de inscritos — cada envio chega como um e-mail individual em `Borahh.app@gmail.com`. Se o volume de interessados crescer a ponto de tornar isso impraticável, a migração recomendada (tabela Supabase dedicada ou serviço de formulário de terceiros) está documentada em `architecture.md`, seção 4.

## 7. Checklist de revisão antes de qualquer deploy

1. `node scripts/build-legal-pages.mjs` (garante que as páginas jurídicas refletem `docs/legal/` mais recente).
2. Abrir cada uma das 6 páginas localmente e verificar links do menu/rodapé.
3. Testar os 2 formulários (`mailto:`) em pelo menos um navegador desktop.
4. Verificar responsividade (menu mobile, grids colapsando) abaixo de 900px e 760px.
5. Rodar novamente a checklist de `deploy.md`, seção 4, após qualquer publicação.
