# IV-01 a IV-05 — Integração da Identidade Visual Oficial

**Data:** 2026-07-26
**Branch:** `feature/iv-01-05-brand-identity`
**Status:** Implementado — fases IV-01 a IV-05 concluídas; IV-06 a IV-09 explicitamente fora de escopo, tratadas em rodada futura
**Escopo:** substituir a identidade visual provisória do BORAH pela identidade oficial (`identidade visual-borah/BORAH_Pacote_Implementacao_Claude`, única fonte de verdade). Nenhuma regra de negócio alterada, nenhuma arquitetura modificada além da camada de apresentação/assets.

---

## 1. Objetivo

Executar, fase por fase e com validação a cada etapa, o plano de implementação já apresentado e aprovado na auditoria de identidade visual (ver seção 4 daquele documento): IV-01 (preparação), IV-02 (ícone do launcher), IV-03 (splash nativo), IV-04 (logo nas telas de autenticação) e IV-05 (reconciliação do gradiente oficial).

---

## 2. Decisão de arquitetura aprovada

**Dependência nova: `flutter_svg: ^2.3.0`** (mantida pela publisher verificada `flutter.dev`). Aprovada explicitamente antes da implementação, com justificativa registrada: pacote consolidado no ecossistema, necessário para consumir os ativos oficiais sem duplicar cada um também em PNG, e prepara a infraestrutura para IV-06/IV-07 (ranking, gamificação, expressões do símbolo — todos SVG-only no pacote oficial, sem fallback em PNG).

---

## 3. IV-01 — Preparação e organização dos assets

- Copiados de `identidade visual-borah/BORAH_Pacote_Implementacao_Claude/.../assets/borah/` para `app/assets/borah/`: `logos/` (4 variações × SVG+PNG), `symbol/` (SVG + PNG 4096px), `app_icon/` (SVG + PNG 1024px), `animations/borah_loading_transparent.{webp,gif}`.
- **Não copiados nesta rodada** (fora do escopo IV-01-05): `ui/ranking/`, `ui/expressions/`, `ui/decorative/`, `animations/marketing/`, `platform/` (ícones pré-gerados — optou-se pela rota do gerador a partir da matriz 1024px, ver IV-02, em vez de integrar os conjuntos prontos, conforme a regra do próprio material oficial de "não misturar as duas rotas").
- **Consolidação**: `app/assets/loading/borah_loading.webp` (em uso desde a UI-03B, confirmado byte-idêntico ao novo arquivo) foi removido — `BorahSplashLoader` agora aponta para `assets/borah/animations/borah_loading_transparent.webp`. Pasta `assets/loading/` removida por estar vazia após a consolidação.
- `assets/icons/borah_location.png` **não foi tocado** — fora do escopo desta rodada (IV-06/IV-07).
- `pubspec.yaml`: `flutter_svg` adicionado; lista `assets:` reorganizada para declarar só o que é efetivamente consumido por um widget nesta rodada (`assets/borah/logos/`, `assets/borah/animations/borah_loading_transparent.webp`, `assets/icons/borah_location.png`) — `symbol/` e `app_icon/` existem no repositório como fonte para as ferramentas de build (IV-02/IV-03, que leem direto do disco) mas não entram no bundle, mesma convenção já usada desde a UI-03B.
- `app/assets/ASSETS.md` atualizado para documentar a nova estrutura e a razão de cada escolha.

---

## 4. IV-02 — Launcher Icons

- `flutter_launcher_icons` reconfigurado: `image_path` de `assets/icon/borah_icon.png` (caminho provisório da RC-04D, nunca preenchido) para `assets/borah/app_icon/borah_app_icon_1024.png` (matriz oficial).
- `dart run flutter_launcher_icons` executado com sucesso — ícone do launcher substituído em todas as densidades Android (`mipmap-*`) e em todo o conjunto `AppIcon.appiconset` do iOS (incluindo tamanhos legados `50x50`/`57x57`/`72x72`, adicionados automaticamente pela ferramenta).
- **Confirmado visualmente**: o ícone agora é o símbolo oficial (verde, mordida característica) sobre fundo, substituindo o logo padrão do Flutter.
- Efeito colateral incidental, sem risco: a ferramenta também atualizou `app/web/index.html`/`app/web/splash/` — a pasta `web/` existe no projeto desde o `flutter create` original mas não é uma plataforma alvo (decisão do EX-01, "mobile-only"); a mudança é inofensiva (só reflete a mesma marca) e não foi revertida.

---

## 5. IV-03 — Native Splash

- `flutter_native_splash` reconfigurado: `image` de `assets/icon/borah_icon.png` (provisório) para `assets/borah/symbol/borah_symbol_4096.png` (símbolo isolado, PNG transparente em alta resolução — a peça indicada pelo próprio material oficial para este uso). Fundo mantido em `#FFFFFF`, o mesmo já usado por `scaffoldBackgroundColor` no Light Theme.
- `dart run flutter_native_splash:create` executado com sucesso — splash estático e rápido em Android (incluindo variante Android 12+/`styles.xml` novos) e iOS (`LaunchScreen.storyboard`, `LaunchImage.imageset`).
- **Confirmado visualmente**: o splash nativo agora mostra o símbolo oficial sobre fundo branco, substituindo a tela branca lisa (placeholder do template Flutter).

---

## 6. IV-04 — Logo nas telas de autenticação

- `login_page.dart`: `Text('BORAH', ...)` (estilizado com Fredoka, mas não a logo oficial) substituído por `SvgPicture.asset('assets/borah/logos/borah_logo_white.svg', semanticsLabel: 'BORAH', fit: BoxFit.contain)`.
- **Decisão de contraste registrada**: o pacote oficial nomeia as variações "dark"/"light" pelo fundo em que devem ser aplicadas ("logo sobre fundo escuro"/"logo sobre fundo claro"), mas ambas são a versão **colorida** (roxo + verde) do logo — inspecionadas visualmente, `logo_dark.png` e `logo_light.png` são a mesma arte. O roxo dessa versão colorida é muito próximo ao roxo do gradiente de fundo já usado no cabeçalho do Login (`AppGradients.of(context).purple`), o que faria as letras do logo perderem contraste contra esse fundo especificamente. Optou-se por `logo_white` (aplicação branca de uma cor, confirmada via inspeção do SVG: `fill="#FFFFFF"`), que preserva contraste sobre qualquer fundo saturado — em linha com a regra do próprio material oficial de "preservar contraste" acima da escolha literal dark/light.
- Único ponto de uso de texto "BORAH" estilizado encontrado em toda a base (`app.dart`'s `title: 'BORAH'` é apenas metadado do SO/task switcher, não um elemento visual, e não foi alterado).

---

## 7. IV-05 — Reconciliação do gradiente oficial

- `BrandGradients.purple` atualizado de `#6B2FFF → #4915D0` (2 tons, obtido por amostragem de pixel na FASE 7A/UI-01, já que o PDF do manual nunca listou hex para gradientes) para o valor exato agora disponível no `ASSET_MANIFEST.json` do pacote oficial: `#6C47FF → #5B2EFF → #3D19C7` (3 tons).
- Efeito automático nas duas telas que já consomem `AppGradients.of(context).purple` via `ThemeData.extensions`: `LoginPage` (cabeçalho) e `BorahSplashLoader` (Splash).
- `BrandGradients.green` mantido sem alteração — o pacote oficial não define um valor exato equivalente para reconciliar.

---

## 8. Fora de escopo nesta rodada (aprovado explicitamente como não incluído)

- **IV-06** — Símbolo e expressões em estados vazios/erro (`EmptyState`/`ErrorState`).
- **IV-07** — Medalhas, coroa, selos em Rankings e Gamificação.
- **IV-08** — Validação formal em Dark Mode de tudo que foi aplicado (o Dark Theme já existe e herda automaticamente os tokens de `BrandColors`/`BrandGradients`, mas uma validação visual dedicada fica para quando IV-06/07 também estiverem implementadas).
- **IV-09** — Ícone 512px do Google Play e demais assets de loja (ligado à futura publicação, RC-04D/FASE 7).

---

## 9. Arquivos criados

- `app/assets/borah/logos/borah_logo_{dark,light,white,black}.{svg,png}` (8 arquivos)
- `app/assets/borah/symbol/borah_symbol.svg`, `borah_symbol_4096.png`
- `app/assets/borah/app_icon/borah_app_icon.svg`, `borah_app_icon_1024.png`
- `app/assets/borah/animations/borah_loading_transparent.{webp,gif}`
- Ícones/splash gerados automaticamente pelas ferramentas (Android `mipmap-*`, `drawable*`, `values*-v31`; iOS `AppIcon.appiconset/*`, `LaunchImage.imageset/*`, `LaunchScreen.storyboard`) — não listados individualmente, ver `git status` para o diff completo.
- `docs/FASE 9 - Execution/IV-01_A_05_BRAND_IDENTITY_INTEGRATION.md` (este documento)

## 10. Arquivos modificados

- `app/pubspec.yaml` — dependência `flutter_svg`, lista `assets:` reorganizada, `flutter_launcher_icons`/`flutter_native_splash` apontando para os caminhos oficiais.
- `app/assets/ASSETS.md` — reescrito para a nova estrutura.
- `app/lib/design_system/components/feedback/loading_indicator.dart` — novo caminho do WebP de loading.
- `app/lib/design_system/brand/brand_gradients.dart` — gradiente roxo reconciliado.
- `app/lib/features/authentication/presentation/pages/login_page.dart` — logo oficial em vez de texto.
- `app/test/widget/authentication/login_page_test.dart`, `app/test/widget/widget_test.dart` — asserts atualizados de `find.text('BORAH')` para `find.byType(SvgPicture)`.
- `app/ios/Runner/Info.plist`, `app/ios/Runner.xcodeproj/project.pbxproj` — atualizados automaticamente por `flutter_native_splash` (status bar).
- `app/web/index.html` — atualizado automaticamente por `flutter_launcher_icons`/`flutter_native_splash` (efeito colateral inofensivo, ver seção 4).

## 11. Resultado dos testes

- `flutter analyze`: **sem nenhum problema**.
- `dart format --set-exit-if-changed .`: **352 arquivos, 0 alterados**.
- `flutter test`: **503/503** — nenhuma regressão em relação à baseline da RC-04E.

## 12. Pendências para as próximas fases

- **IV-06/IV-07**: aguardando aprovação explícita para copiar `ui/ranking/`, `ui/expressions/`, `ui/decorative/` para `assets/borah/` e aplicá-los nas telas correspondentes.
- **IV-09**: ícone 512px do Google Play, ligado à futura publicação.
- Esta rodada resolve, para o BORAH, duas pendências já registradas em `RC-04D_RELEASE_READINESS.md` §12 ("Ícone de app" e "Splash screen", antes marcadas 🔴 por falta do asset-fonte) — atualizado nesta rodada para refletir a conclusão.
