# Assets oficiais BORAH — organização

**Atualizado na IV-01.** A partir desta rodada, `identidade visual-borah/BORAH_Pacote_Implementacao_Claude` (na raiz do repositório, fora de `app/`) é a **única fonte de verdade** para logo, símbolo, ícone do app, cores, tipografia e demais componentes visuais da marca — substitui as entregas anteriores (`BORAH_Sistema_Animacoes_Oficial`/`BORAH_Biblioteca_Visual_Oficial`, que continuam no repositório só como material de marketing/redes sociais, fora de uso no app).

## Estrutura

```
assets/
  borah/
    logos/        4 variações (dark/light/white/black), SVG + PNG fallback
    symbol/       símbolo isolado, SVG + PNG 4096px transparente
    app_icon/     matriz oficial do ícone do app, SVG + PNG 1024px
    animations/   loading transparente (WebP + GIF fallback) — em uso (BorahSplashLoader)
  branding/        reservado — nenhum outro asset de marca aprovado para uso in-app ainda
  loading/         REMOVIDO na IV-01 — consolidado em assets/borah/animations/ (mesmo arquivo)
  icons/
    borah_location.png   ícone de localização (1024x1024) — em uso (telas de restaurante)
    borah_location.svg   fonte vetorial do mesmo ícone — organizado aqui, ainda fora do bundle
  illustrations/   reservado — nenhuma ilustração aprovada para uso in-app ainda
  fonts/           já existente desde o UI-01 (Fredoka/Manrope)
```

## O que está no `pubspec.yaml` e por quê

Só os arquivos efetivamente consumidos por um widget entram na lista `assets:` (mesma convenção da UI-03B):

- `assets/borah/logos/` — `borah_logo_white.svg` usado em `login_page.dart` (IV-04). As demais 3 variações (dark/light/black) ficam no bundle prontas para uso futuro (IV-06 em diante), já que declarar a pasta inteira é mais simples do que listar arquivo por arquivo e todas são pequenas.
- `assets/borah/animations/borah_loading_transparent.webp` — usado por `BorahSplashLoader` (`lib/design_system/components/feedback/loading_indicator.dart`). Mesmo arquivo que já estava em uso antes da IV-01 (confirmado byte-idêntico, 882.964 bytes), só reorganizado para o caminho oficial.
- `assets/icons/borah_location.png` — usado nas telas de restaurante (busca, favoritos, detalhes). Fora do escopo da IV-01/05, não alterado.

**Não** declarados no bundle, mas presentes no repositório (fonte para ferramentas de build, lidas diretamente do disco, não pelo mecanismo de assets do Flutter):

- `assets/borah/symbol/borah_symbol_4096.png` — fonte do splash nativo (`flutter_native_splash`, IV-03).
- `assets/borah/app_icon/borah_app_icon_1024.png` — fonte do ícone do launcher (`flutter_launcher_icons`, IV-02).
- `assets/borah/animations/borah_loading_transparent.gif` — fallback de compatibilidade do loading, mesmo critério já usado antes da IV-01 (só entra no bundle se um problema real de reprodução do WebP for observado em dispositivo real).
- `assets/borah/logos/*.svg` — os SVGs em si não precisam de declaração própria além da pasta já listada acima.

## Dependência nova

`flutter_svg` (IV-01, decisão de arquitetura aprovada explicitamente) — necessário para renderizar `borah_logo_white.svg` em `login_page.dart` e prepara a infraestrutura para os ativos de ranking/expressões/decorativos (IV-06/IV-07, ainda não implementados).

## Fora do escopo (não trazido para `assets/`)

Ícones de ranking/gamificação (`ui/ranking/`), expressões do símbolo (`ui/expressions/`), elementos decorativos (`ui/decorative/`) e vídeos de assinatura/marketing (`animations/marketing/`) do pacote oficial — existem na fonte (`identidade visual-borah/BORAH_Pacote_Implementacao_Claude`) mas só serão copiados para `assets/` quando as fases IV-06/IV-07 forem aprovadas e implementadas.
