# RC-03 — FASE 3: UI Audit

**Status:** Draft para aprovação do usuário — análise pura, nenhum código/schema/arquivo de produto foi alterado.
**Data:** 2026-08-04
**Objetivo desta fase:** não é comparar telas visualmente — é verificar se o aplicativo **transmite a identidade da marca BORAH** de forma estruturalmente consistente, telas reais comparadas com Manual da Marca/Biblioteca Visual/Componentes existentes, com classificação ✓/△/✗ por tela.
**Baseline:** este documento assume como verdade os achados do [`RC03_PRODUCT_AUDIT.md`](RC03_PRODUCT_AUDIT.md) e do [`RC03_UX_AUDIT.md`](RC03_UX_AUDIT.md) (pivô de produto, motores genéricos subutilizados, triggers sociais ausentes no cluster Grupos/Rolês) — não repete essa análise, foca exclusivamente em identidade visual e sistema de design.
**Fontes:** `rc03_design_inventory.md` (design system + identidade visual + docs UI/UX, já verificado), `docs/FASE 3 - UX_UI/UI-05` a `UI-08` (lidos integralmente nesta fase — não haviam sido lidos nas fases anteriores), histórico real de commits (`git log`, para resolver divergências entre documentação e código), e uma auditoria de código dedicada desta fase cobrindo as 44 páginas de `app/lib/features/**/presentation/pages/` uma a uma (imports, componentes usados, valores hardcoded, estados, acessibilidade).

---

## 1. Achado metodológico prévio — a documentação UI-06/07/08 é histórica e coerente, não contraditória

Antes de avaliar telas, uma verificação de proveniência era necessária: `rc03_design_inventory.md` (auditoria de código desta RC-03) não lista `AppFab`, `AppSecondaryButton`, `AppChip`, `AppBottomSheet`, `SkeletonLoader`, `ReviewCard` nem `AppShadows` como existentes hoje — mas `UI-06_COMPONENT_LIBRARY.md §16.3` os documenta como parte da "Component Library". Isso poderia ser um sinal de documentação desatualizada (como o pivô ET/UX/DV vs. código, achado central da FASE 1) — mas a verificação direta no histórico do Git mostra uma história diferente e **coerente**:

1. `24852c3`/`86e3154` — rodada **UI-02** (Component Library) criou 24 componentes novos, incluindo os 6 acima, nenhum ainda conectado a tela nenhuma (por decisão explícita do próprio UI-02: "nenhuma tela deve ser migrada").
2. `a1b83a8`/`ab24c1f` — rodada **UI-03** (Apply Design System) migrou 39 telas para consumir os componentes, mas **não todos os 24** — vários (incluindo os 6 citados) nunca chegaram a ser conectados a nenhuma tela real, ficando como "pendência para UI-03A" (`UI-06 §16.7`, `UI-07 §7`).
3. `bab29ff`/`84312de`/`73b064e`/`444747f` — rodada **UI-08** (Motion Design) aplicou animação a 16 telas usando 4 componentes de motion (`AppAnimatedSwitcher`, `AppAnimatedFraction`, `AppStaggeredListItem`, `AppPulseIcon`) + tokens (`AppMotion`).
4. `4d856b7` (1/ago/2026, **posterior e descendente de todos os commits acima**, confirmado via `git merge-base --is-ancestor`) — "chore(design-system): remove confirmed dead widgets" — removeu exatamente os 6 componentes + `AppShadows`, após "uma varredura exaustiva de referências em todo o repositório (produção + testes) encontrar zero pontos de uso fora da própria definição/barrel" de cada um.

**Conclusão:** não há contradição — é uma sequência real e bem documentada de construir → nunca conectar → confirmar que nunca foi usado → remover. O achado relevante para esta auditoria não é "a documentação mentiu", é: **a Component Library documentada (UI-06) e a Component Library que existe hoje divergem em 7 itens, e a divergência é legítima (limpeza de código morto), não um erro de processo.** Toda comparação abaixo usa a Component Library **atual** (confirmada por `rc03_design_inventory.md` e pela auditoria desta fase), não a lista original do UI-06.

---

## 2. Design System — auditoria de fundação (Foundations)

### 2.1 Cores

Fonte única de verdade: `BrandColors` (`design_system/brand/brand_colors.dart:18-28`) → `AppColors` (`design_system/tokens/app_colors.dart:17-78`) → `ColorScheme` via `ColorScheme.fromSeed` (`core/theme/app_theme.dart:27-61`). Roxo BORAH `#5B2EFF`, Verde BORAH `#B8FF3B`, Preto Uva `#0B0714` — valores idênticos ao Manual da Marca (confirmado, `rc03_design_inventory.md §2.2`, LEIA-ME da Biblioteca Visual Oficial). Dark theme usa `roxoBorahLight #9477FF` como `primary` por contraste WCAG, decisão documentada e correta (`app_theme.dart:42-47`). Contrastes calculados e registrados: branco/roxo 6.40:1, preto-uva/verde 16.50:1 — ambos acima do mínimo WCAG AA (4.5:1).
**Veredito: ✓ Compatível.** Única fonte, sem duplicação, cores de marca exatas.

### 2.2 Tipografia

`Fredoka` (títulos, 600/700) + `Manrope` (corpo/interface, 400/600/700), fontes variáveis bundladas localmente (`pubspec.yaml:169-183`), escala Material 3 completa de 15 estilos (`app_typography.dart:24-121`). **Achado documentado no próprio `UI-04_TYPOGRAPHY.md §3`**: a fonte original recomendada era Inter (substituída por Fredoka/Manrope) — mudança já registrada como decisão consciente ("Atualizado na FASE 7A"), não uma divergência não-intencional.
**Veredito: ✓ Compatível**, com uma ressalva: `UI-03B §9.1` (achado da própria auditoria interna anterior) confirma que, antes da rodada UI-08B1/B2, a tipografia "herói" (`headlineLarge`/`displayX`) tinha **zero usos** em qualquer tela — só passou a ser usada a partir da Splash/Login na rodada UI-03B (`headlineLarge` no "BORAH" do painel-herói do Login, `UI-07 §9.4`). Isso precisa ser reconfirmado tela a tela nesta fase (ver §4).

### 2.3 Espaçamento (`AppSpacing`) e Radius (`AppRadius`)

Grid de 8px consistente com `UI-01_DESIGN_SYSTEM.md §6` (valores idênticos: 4/8/12/16/24/32/40/48/64). Radius em 6 categorias (`xs=4` a `pill=999`). **Achado documentado pela própria auditoria interna (`UI-03B §9.1`)**: antes da rodada UI-03B, os tokens existiam mas **nenhuma tela usava `AppSpacing.*`** — todo espaçamento era número cru, com padrões inconsistentes entre telas irmãs. A UI-03B corrigiu isso em 39 arquivos. **Esta auditoria (FASE 3) precisa reconfirmar se isso permanece corrigido após o merge do bundle RC-02D**, já que o bundle introduziu ~15 telas novas (Grupos/Rolês/EventReviews/GroupRanking) que nunca passaram pela rodada UI-03/UI-03B (essas rodadas são anteriores ao bundle na timeline de commits) — ver §4 e §6.

### 2.4 Elevação e Sombras

`AppElevation` (5 níveis, `Elevation 0-4`) permanece; `AppShadows` foi removido como código morto (`4d856b7`, §1) — "companion to AppElevation, never consumed, all current widgets use Material's native `elevation`". Isso não é uma lacuna: o Material 3 nativo já resolve sombra a partir de `elevation` + `ColorScheme.shadow`/`surfaceTint`, então `AppShadows` era uma camada redundante nunca necessária.
**Veredito: ✓ Compatível** (a remoção foi a decisão correta, não uma lacuna).

### 2.5 Ícones

`UI-05_ICONOGRAPHY.md` especifica: biblioteca Material Symbols/Material Icons Outlined, estilo outlined consistente, escala de 5 tamanhos (16/20/24/32/48px), cores só via token (nunca fixas), área mínima de toque 48×48px, "ícones proprietários" como evolução futura (nunca implementados — confirmado, não existe nenhum arquivo de ícone proprietário do BORAH além dos assets SVG pontuais de marca: medalhas, expressões, localização — nenhum sistema de ícone customizado). Não existe `design_system/icons/app_icons.dart` centralizando os ícones (a estrutura sugerida pelo próprio UI-05 §10) — os ícones são `Icons.xxx` do Material usados diretamente em cada tela, sem indireção central.
**Veredito: △ Parcialmente compatível.** O app usa consistentemente Material Icons (sem mistura de estilos filled/outlined visível no inventário), mas não há nenhuma centralização/constante de ícones — cada tela referencia `Icons.xxx` diretamente, o que é um risco de inconsistência silenciosa (ex.: duas telas usando `Icons.delete` vs. `Icons.delete_outline` para a mesma ação, sem nenhum mecanismo que impeça isso). Verificação por tela na §4.

### 2.6 Motion

`AppMotion` (`design_system/animations/app_motion.dart:13-48`) — tokens de duração (150/200/300/500ms) e curva, com `scaled()` respeitando "reduzir movimento" do SO. **Correção de hipótese inicial desta auditoria**: antes da auditoria de código tela a tela (§4), presumi que o cluster pós-pivô (Grupos/Rolês/EventReviews/GroupRanking) ficaria fora da cobertura de motion por razão cronológica (o bundle foi mesclado depois das rodadas UI-08). **A auditoria de código mostrou o oposto**: `AppAnimatedSwitcher`/`AppStaggeredListItem`/`AppPulseIcon`/`AppAnimatedFraction` estão de fato presentes em `groups_list_page`, `group_detail_page`, `events_list_page`, `event_detail_page`, `group_ranking_page` e `gamification_profile_page` — 20 das 44 telas auditadas usam ao menos um componente de motion. A lacuna real não é cronológica/por cluster de produto — está concentrada quase inteiramente em **Administração** (6 páginas + `admin_guard`, nenhuma usa `AppAnimatedSwitcher` apesar de todas terem estados Loading/Error/Empty/Loaded distintos) mais `group_stats_page.dart`, `ranking_users_page.dart` e a etapa 1 (busca de restaurante) de `create_event_page.dart`.
**Veredito: △ Parcialmente compatível** — sistema robusto, bem fundamentado e com adoção real em quase metade das telas (não superficial); a lacuna remanescente é pontual e concentrada (Administração + 2 telas de ranking + 1 sub-fluxo), não estrutural.

### 2.7 Tema (Theme)

`AppTheme.light`/`AppTheme.dark` (`app_theme.dart:173-205`) — suporte completo a dark mode via `ColorScheme.fromSeed`, `FilledButtonThemeData` fixo em `BrandColors.purple` (decisão de marca, não de tema, correta), `InputDecorationTheme`/`CardThemeData`/`AppBarThemeData`/`DialogThemeData`/`ChipThemeData` todos definidos. `ChipThemeData` permanece definido mesmo sem `AppChip` (aplica a qualquer `Chip` nativo do Material, decisão explícita registrada em `4d856b7`).
**Veredito: ✓ Compatível.**

### 2.8 Responsividade

`UI-01 §9`/`UI-06 §9` pedem adaptação a tablets como "futuro" — não implementado (nem esperado nesta fase; nenhuma tela usa `LayoutBuilder`/breakpoints, confirmado ausência no inventário Flutter, nenhum widget responsivo citado em nenhuma das 44 páginas). O app é smartphone-only hoje, o que é consistente com o escopo documentado (tablets é "futuro", não uma lacuna atual).
**Veredito: ✓ Compatível com o escopo atual documentado** (não é uma lacuna, é escopo não alcançado ainda por decisão).

---

## 3. Existe um Design System consistente, ou existem componentes isolados?

**Resposta direta: existe um Design System real e consistente na fundação (tokens/tema), com aplicação real e comprovada em pelo menos 39 telas — mas com uma fratura cronológica clara entre o cluster "pré-pivô" (Auth/Users/Restaurants/Reviews/Rankings/Favorites/Social/Gamificação/Notificações/Administração, todas migradas nas rodadas UI-02/03/03A/03B/08) e o cluster "pós-pivô" (Grupos/Rolês/EventReviews/GroupRanking, introduzidas pelo bundle depois dessas rodadas).**

Isso não é uma opinião — é uma consequência direta e verificável da ordem dos commits: as rodadas de aplicação de design system (`86e3154`, `ab24c1f`, `444747f`) são todas ancestrais de `84d0f0a` (HEAD atual de `develop`), mas o cluster Grupos/Rolês entrou via o merge do `bundle-import` (`e67ed42`), que não passou pelas mesmas 3 rodadas de refinamento visual. A pergunta "essas telas novas seguem o Design System?" não tem resposta a priori — precisa ser verificada tela a tela, o que a §4/§5 fazem.

---

## 4. Classificação por tela

**Metodologia desta classificação**: como nenhuma cor hardcoded foi encontrada em nenhuma das 44 telas (confirmado por 2 agentes independentes, checagem cruzada) — toda cor vem de `Theme.of(context).colorScheme.*` —, a marca (paleta) está **universalmente correta**. A classificação ✓/△/✗ abaixo, portanto, não mede "está fora da paleta BORAH" (nenhuma tela está), mede **consistência estrutural com a Component Library**: uso de componente dedicado vs. `ListTile`/`Container` cru, tokens de espaçamento vs. números soltos, cobertura de estados (Loading/Empty/Error/Sucesso) via o padrão estabelecido (`AppAnimatedSwitcher` + `LoadingScreen`/`ErrorState`/`EmptyState`), e acessibilidade (tooltip em ícone interativo).

✓ = Compatível (sem gaps relevantes) · △ = Parcialmente compatível (1-2 gaps concretos, base sólida) · ✗ = Não compatível (múltiplos gaps ou padrão predominantemente cru)

### Autenticação

| Tela | Classificação | Justificativa |
|---|---|---|
| `splash_page.dart` | ✓ | Único elemento é `BorahSplashLoader`, já usa `AppGradients.purple`; nenhum gap. |
| `login_page.dart` | ✓ | Único uso de `AppGradients.purple` em tela de feature (fora da Splash); todos os campos via `AppTextField`/`AppPasswordField`; `SizedBox(height:48)` da logo é o único literal, sem token equivalente (tamanho de box de logo, não espaçamento). |
| `signup_page.dart` | ✓ | 100% tokenizado, `AppTopBar`, sem gaps. |
| `password_reset_page.dart` | ✓ | Estados form↔sucesso via `AppAnimatedSwitcher`; único literal é `size:48` do ícone decorativo (sem token de tamanho de ícone no DS, ver §6). |
| `new_password_page.dart` | ✓ | 100% tokenizado, sem gaps. |
| `email_verification_page.dart` | △ | **Sem `AppTopBar`/AppBar nenhuma** — único caminho de volta é um `AppTextButton` de texto, sem seta de retorno; gap de affordance de navegação, não de estilo. |

### Perfil / Usuário

| Tela | Classificação | Justificativa |
|---|---|---|
| `profile_page.dart` | △ | Bloco de atalhos (Gamificação/Rankings/Notificações) é `Card` + 3× `ListTile` crus — o próprio comentário do código admite ser "mesmo padrão já usado em `SettingsPage`", ou seja, um padrão cru conhecido e repetido, não um esquecimento isolado. |
| `edit_profile_page.dart` | ✓ | Formulário 100% tokenizado. |
| `change_avatar_page.dart` | △ | Preview da imagem recém-selecionada usa `CircleAvatar` cru (`MemoryImage`), contorna `UserAvatar`/`ProfileAvatar` — `UserAvatar` não suporta `MemoryImage` hoje. |
| `settings_page.dart` | ✗ | A tela inteira é uma `ListView` de 4 `ListTile` crus, sem nenhum wrapper de componente — é a tela mais "não migrada" da auditoria fora do cluster Administração. |
| `account_deletion_dialog.dart` (widget) | △ | Usa `AppDialog`/`AppTextButton`/`AppPasswordField` corretamente, mas 4 valores de espaçamento hardcoded (`SizedBox`/`EdgeInsets` numéricos, sem importar `AppSpacing`). |

### Social

| Tela | Classificação | Justificativa |
|---|---|---|
| `feed_page.dart` | ✓ | 4 estados via `AppAnimatedSwitcher`, `EmptyState`/`ErrorState`; o único cru é herdado do widget de item reutilizado (`ReviewSummaryTile`, ver §5/§6). |
| `comments_page.dart` | △ | `ListTile`+`PopupMenuButton` crus por comentário (sem `tooltip` no menu); pelo resto, cobertura de DS excelente (`AppDialog`, `ConfirmationDialog`, `AppTextField`, `AppIconButton` com tooltip, 4 estados). |
| `follow_list_page.dart` | △ | `ListTile` cru por linha; estados 100% cobertos via `AppAnimatedSwitcher`/`EmptyState`/`ErrorState`. |
| `public_profile_page.dart` | ✗ | Estado de erro do perfil é `Center(child: Text(...))` cru, **contornando `ErrorState` inteiramente** (sem botão de retry); a subseção de avaliações também usa `Text` cru para erro/vazio em vez de `ErrorState`/`EmptyState` — é a tela com o padrão de estado mais quebrado da auditoria. |

### Restaurantes

| Tela | Classificação | Justificativa |
|---|---|---|
| `restaurants_search_page.dart` | △ | `ListTile` cru por restaurante **apesar de `RestaurantCard` já existir e estar pronta** — não-adoção confirmada de um componente que resolveria exatamente este caso. |
| `restaurant_detail_page.dart` | ✓ | `AppCard`, `AppOutlinedButton`, `AppPulseIcon` no favoritar, 3 estados completos; único literal é tamanho de ícone (18px, sem token). |
| `create_restaurant_page.dart` | ✓ | Formulário 100% tokenizado. |

### Avaliações (Reviews)

| Tela | Classificação | Justificativa |
|---|---|---|
| `reviews_list_page.dart` | △ | Usa `ReviewSummaryTile` (ver gap abaixo) + ícone decorativo de curtidas com tamanho hardcoded. |
| `review_detail_page.dart` | ✓ | A tela mais completa do cluster Reviews — `ScoreBubble`, `AppPulseIcon`, `ConfirmationDialog`, `AppOutlinedButton`/`AppTextButton`, 3 estados; único hardcode é dimensão da tira de fotos (sem token de tamanho de imagem). |
| `create_review_page.dart` | ✓ | Formulário 100% tokenizado. |
| `edit_review_page.dart` | ✓ | Formulário 100% tokenizado. |
| `review_summary_tile.dart` (widget) | ✗ | **Não importa nada do design system** — é 100% `ListTile` cru, e é o widget de item mais reutilizado do app (alimenta `feed_page`, `reviews_list_page`, `public_profile_page` simultaneamente). Mostra só o número da nota como `Text`, nunca usa `ScoreBubble` apesar de existir exatamente para isso. **Maior achado de dívida visual desta fase** (ver §6). |

### Rankings / Favoritos

| Tela | Classificação | Justificativa |
|---|---|---|
| `rankings_page.dart` | △ | Usa `RankingCard` corretamente (bom!), mas 2 valores de espaçamento hardcoded — arquivo nem importa `AppSpacing`. |
| `favorites_page.dart` | △ | `DropdownButton` cru para ordenação (sem componente DS equivalente, aceitável), **mas `ListTile` cru em vez de `RestaurantCard`** — mesmo gap de `restaurants_search_page.dart`. |

### Grupos

| Tela | Classificação | Justificativa |
|---|---|---|
| `groups_list_page.dart` | △ | `ListTile` cru por grupo — mas não há `GroupCard` no DS para usar (nunca foi construído, ver §6); pelo resto, cobertura excelente (`AppAnimatedSwitcher`, `AppStaggeredListItem`, 4 estados). |
| `create_group_page.dart` | ✓ | Formulário 100% tokenizado. |
| `edit_group_page.dart` | ✓ | Formulário 100% tokenizado. |
| `join_group_page.dart` | ✓ | Formulário 100% tokenizado. |
| `group_detail_page.dart` | △ | `ListTile` cru por membro + 2 `PopupMenuButton` crus sem tooltip explícito; usa `ProfileAvatar` (não `UserAvatar`) para avatar de membro. Pelo resto, cobertura muito forte (`AppBadge`, `ConfirmationDialog`, `AppAnimatedSwitcher` com reuso inteligente de chave para não reanimar em falha de ação). |

### Rolês (Events) / Avaliação Coletiva

| Tela | Classificação | Justificativa |
|---|---|---|
| `events_list_page.dart` | △ | `ListTile` cru por rolê — mesmo motivo de `groups_list_page` (sem `EventCard` no DS); `AppCard` usado corretamente nos cards de Memórias, `AppBadge`, estados completos. |
| `create_event_page.dart` | △ | Estado "nenhum restaurante encontrado" é `Center(Column(Text))` cru, não `EmptyState`; `ListTile` cru para seletores de data/hora (aceitável, sem componente DS de date-picker); busca não usa `AppAnimatedSwitcher`. |
| `event_detail_page.dart` | △ | `ListTile` cru para participantes e avaliações; subseção de avaliações usa `Text` cru para erro/vazio (mesmo padrão frágil de `public_profile_page`, em escala menor). Pelo resto, muito forte: 3× `AppBadge`, `ConfirmationDialog`, `AppAnimatedSwitcher` com reuso de chave. |
| `submit_event_review_page.dart` | ✓ | Formulário 100% tokenizado (os 5 campos numéricos são decisão de UX já discutida na FASE 2, não um gap visual). |

### Ranking de Grupo / Gamificação

| Tela | Classificação | Justificativa |
|---|---|---|
| `group_ranking_page.dart` | △ | Reaproveita `RankingCard` corretamente, mas 2 valores hardcoded, arquivo não importa `AppSpacing`. |
| `group_stats_page.dart` | △ | Sem `AppAnimatedSwitcher` apesar de ter estados distintos; `AppCard`×4/`SectionHeader`×4 usados corretamente; 1 `TextStyle` inline fora de `AppTypography`. |
| `gamification_profile_page.dart` | ✓ | **A tela com identidade de marca mais forte do app** — único lugar além do Login usando `AppGradients` (verde, na barra de XP), `AppAnimatedFraction`, `AppPulseIcon`, `AppBadge`; card de nível é `Container`/`Stack` cru em vez de `AppCard` e a lista de badges usa `ListTile` cru — únicos 2 gaps, ambos pequenos frente à força geral da tela. |
| `ranking_users_page.dart` | △ | Usa `RankingCard` corretamente, mas sem `AppAnimatedSwitcher`, `EdgeInsets.all(16)` hardcoded, arquivo não importa `AppSpacing`. |

### Notificações

| Tela | Classificação | Justificativa |
|---|---|---|
| `notifications_page.dart` | △ | `ListTile` cru + indicador de não-lida (`Container` 10×10 hardcoded) — pelo resto, cobertura completa (`AppAnimatedSwitcher`, `AppStaggeredListItem`, 4 estados, tooltips presentes). |
| `notification_detail_page.dart` | ✓ | `AppTopBar`/`AppOutlinedButton`, sem gaps. |
| `notification_preferences_page.dart` | ✓ | `SwitchListTile` cru é fallback razoável (sem componente DS de switch); pelo resto, `AppAnimatedSwitcher`/`LoadingScreen`/`ErrorState` corretos. |

### Administração — cluster consistentemente mais fraco

| Tela | Classificação | Justificativa |
|---|---|---|
| `admin_guard.dart` (widget) | △ | Estado "sem papel de admin" é `Center(Text(...))` cru; `LoadingScreen`/`ErrorState` usados corretamente nos outros 2 estados. |
| `admin_dashboard_page.dart` | ✗ | **10 valores de espaçamento hardcoded**, arquivo não importa `AppSpacing` nenhuma vez; sem `AppAnimatedSwitcher`. |
| `admin_users_page.dart` | ✗ | `EdgeInsets` hardcoded, `ListTile` cru, sem `AppAnimatedSwitcher` (apesar de ter `AppSearchField`/`EmptyState`/`ErrorState` corretos). |
| `admin_restaurants_page.dart` | △ | `EdgeInsets` hardcoded, `ListTile` cru, sem UI distinta para o estado "salvando" (colapsado com "carregado"); usa `AppBadge`/`AppTextButton` corretamente. |
| `admin_roles_page.dart` | △ | 3 valores hardcoded, `DropdownButton` cru (aceitável), `ListTile` cru, sem UI distinta para "salvando". |
| `moderation_page.dart` | △ | `ListTile` cru, sem UI distinta para "processando"; `AppTextButton`/`EmptyState`/`ErrorState` corretos. |
| `audit_log_page.dart` | △ | `ListTile` cru com formatação de data inline (não reaproveita o helper `_formatDateTime` já usado em `groups`/`events`) — é o admin mais limpo, mas ainda não livre de gap. |

### Shell / Infraestrutura (não são "telas" no sentido do usuário, mas fazem parte da identidade)

| Item | Classificação | Justificativa |
|---|---|---|
| `home_shell_page.dart` (bottom nav) | ✓ | Confirmado: usa `AppBottomNavigation` (componente do design system), não um `NavigationBar`/`BottomNavigationBar` cru. |
| `core/theme/app_theme.dart` | ✓ | `AppBarTheme`/`DialogTheme`/`ChipTheme` todos definidos e documentados; nenhum gap. |
| `core/router/app_router.dart` (transições) | △ | Apenas 1 das 47 rotas (a Splash) usa transição customizada via `AppMotion`; as outras 46 usam o padrão Material puro — o plano original do UI-08 (Fase A, "transição de página compartilhada... efeito em 100% da navegação") nunca foi executado além da Splash. |

### Resumo quantitativo

| Classificação | Contagem (telas + widgets de item relevantes) |
|---|---|
| ✓ Compatível | 20 |
| △ Parcialmente compatível | 21 |
| ✗ Não compatível | 5 |

Os 5 ✗ concentram-se em 2 grupos: **telas cruas por inteiro** (`settings_page.dart`, `review_summary_tile.dart`, `public_profile_page.dart`) e **Administração sem tokens de espaçamento** (`admin_dashboard_page.dart`, `admin_users_page.dart`). Nenhum ✗ está relacionado a cor/marca — todos são gaps estruturais de componentização, consistentes com o achado do §3.

---

## 5. Componentes — existe / reutilizado / duplicado / pode virar global / pode virar token

| Componente | Existe? | É reutilizado? | Está duplicado? | Pode virar componente global? | Pode virar Design Token? |
|---|---|---|---|---|---|
| `AppTopBar` | Sim | Sim — 33 das 34 telas com AppBar usam esta (só `login_page`/`splash_page`/`email_verification_page` não têm AppBar por design) | Não | Já é global | — |
| `AppPrimaryButton`/`AppOutlinedButton`/`AppTextButton`/`AppIconButton` | Sim | Sim — nenhum botão Material cru encontrado em toda a auditoria | Não | Já são globais | — |
| `AppTextField`/`AppSearchField`/`AppPasswordField` | Sim | Sim — nenhum `TextField`/`TextFormField` cru encontrado | Não | Já são globais | — |
| `EmptyState`/`ErrorState`/`LoadingScreen`/`LoadingIndicator` | Sim | Sim, majoritariamente — mas contornados por `Text`/`Center` cru em `public_profile_page.dart` (2×), `event_detail_page.dart` (nested), `create_event_page.dart` (busca vazia), `admin_guard.dart` | **Sim, por contorno** — 5 telas reimplementam informalmente o que esses componentes já resolvem | Já são globais — o problema não é o componente, é adoção | — |
| `AppCard` | Sim | Sim — `restaurant_detail_page`, `favorites_page`, `public_profile_page`, `events_list_page` (memórias), `group_stats_page`×4, `admin_dashboard_page` (KPI) | Não | Já é global | — |
| `RestaurantCard` | Sim | **Não** — existe mas não é usada em `restaurants_search_page.dart` nem `favorites_page.dart`, os 2 lugares exatos para os quais foi criada | **Sim, por não-adoção** — as 2 telas reimplementam o mesmo conteúdo (nome/categoria/nota) via `ListTile` cru em vez de usar o componente pronto | Já é global, subutilizada | — |
| `RankingCard` | Sim | Sim — `rankings_page`, `group_ranking_page`, `ranking_users_page` (3 telas de ranking distintas, mesmo componente) | Não — **este é o melhor exemplo de reuso confirmado da auditoria** | Já é global | — |
| `ScoreBubble` | Sim | Parcial — usada em `restaurant_detail_page`(via nota)/`review_detail_page`, mas **não usada em `review_summary_tile.dart`**, que mostra a nota como `Text` cru apesar de `ScoreBubble` existir exatamente para isso | **Sim, por não-adoção** no widget de maior reuso do app | Já é global, subutilizada | — |
| `AppBadge` | Sim | Sim — `group_detail_page`, `event_detail_page`×3, `admin_restaurants_page`, `gamification_profile_page` | Não | Já é global | — |
| `AppDialog`/`ConfirmationDialog` | Sim | Sim — todo diálogo de confirmação/formulário-modal encontrado usa um dos dois; zero `AlertDialog` cru em toda a auditoria | Não | Já são globais | — |
| `UserAvatar` (design system) vs. `ProfileAvatar` (feature) vs. `CircleAvatar` cru | Sim (os 2 primeiros) | **3 implementações paralelas do mesmo conceito** — `ProfileAvatar` (usado por `profile_page`, `group_detail_page`, `event_detail_page`, `follow_list_page`, `public_profile_page`) resolve URL assinada e delega a `UserAvatar`; `change_avatar_page.dart` usa `CircleAvatar` cru para o preview local (`UserAvatar` não suporta `MemoryImage`) | **Sim** — 3 formas de renderizar avatar no mesmo app | `ProfileAvatar` já cumpre esse papel (é a camada correta: resolve dado + delega estilo); o gap é só o preview local de `change_avatar_page` | — |
| `AppAnimatedSwitcher`/`AppStaggeredListItem`/`AppPulseIcon`/`AppAnimatedFraction` | Sim | Sim — 20 de 44 telas (ver §2.6) | Não | Já são globais, adoção real e crescente | — |
| `AppGradients`/`BrandGradients` | Sim | **Muito pouco** — só 2 telas (`login_page`, `gamification_profile_page`) usam `AppGradients`; `BrandGradients` nunca é referenciada diretamente em nenhuma tela (correto, por regra de camadas) | Não | Já é global, radicalmente subutilizado frente ao potencial de identidade de marca | — |
| Tipografia "herói" (`headlineLarge`/`displayLarge`/`displayMedium`/`displaySmall`) | Sim, como token | **Zero usos confirmados em toda a árvore `features/`** (grep exaustivo, 2 agentes independentes) | Não é duplicação — é abandono | Já é global, nunca usado | — |
| "Card de grupo" (linha de grupo em `groups_list_page`) | **Não existe** | — | `ListTile` cru reimplementado | **Sim — candidato direto a `GroupCard`**, já previsto em `UI-06_COMPONENT_LIBRARY.md §6` mas nunca construído | — |
| "Card de rolê" (linha de evento em `events_list_page`) | **Não existe** | — | `ListTile` cru reimplementado | **Sim — candidato direto a `EventCard`**, também já previsto em `UI-06 §6`, nunca construído | — |
| Tamanho de ícone (14/16/18/36/48/64/96px espalhados como literais) | **Não existe como token** | — | Cada tela reinventa o próprio número | Menos prioritário que os cards acima | **Sim — candidato direto a token**, `UI-05_ICONOGRAPHY.md §6` já especifica a escala (XS16/SM20/MD24/LG32/XL48), só nunca virou `Dart const` |
| Indicador de não-lida (ponto colorido em `notifications_page.dart`) | **Não existe como componente** | — | `Container` cru 10×10 | Baixa prioridade (uso único hoje) | Poderia reaproveitar `AppSpacing.xs` (4px) como base em vez de `10` cru, mas não é um padrão repetido o suficiente para justificar um componente novo agora |
| `AppFab`/`AppSecondaryButton`/`AppChip`/`AppBottomSheet`/`SkeletonLoader`/`ReviewCard`/`AppShadows` | **Não** (removidos, `4d856b7`) | N/A | N/A | Decisão já tomada e correta (código morto removido após confirmação de zero uso) — não recriar sem uma necessidade concreta nova | N/A |

---

## 6. Dívida Visual

### Inconsistências visuais
- **Tamanho de ícone sem token**: 14/16/18/36/48/64/96px aparecem como literais espalhados por pelo menos 9 arquivos (`login_page`, `password_reset_page`, `email_verification_page`, `restaurants_search_page`, `restaurant_detail_page`, `favorites_page`, `reviews_list_page`, `review_detail_page`, `change_avatar_page`, `follow_list_page`) — `UI-05_ICONOGRAPHY.md §6` já especifica a escala oficial (XS16/SM20/MD24/LG32/XL48), nunca foi implementada como token Dart.
- **`AppSpacing` importado inconsistentemente**: `rankings_page.dart`, `ranking_users_page.dart`, `group_ranking_page.dart`, `admin_dashboard_page.dart`, `admin_users_page.dart`, `admin_restaurants_page.dart`, `admin_roles_page.dart` — 7 arquivos não importam o token de espaçamento básico do próprio Design System.

### Componentes duplicados (ou não-adotados, o que produz o mesmo efeito de duplicação)
- `RestaurantCard` existe e está pronta, mas `restaurants_search_page.dart` e `favorites_page.dart` — exatamente as 2 telas para as quais foi criada — continuam usando `ListTile` cru.
- `ScoreBubble` existe e está pronta, mas `review_summary_tile.dart` (o widget de item mais reutilizado do app) mostra a nota como `Text` cru.
- 3 formas paralelas de renderizar avatar: `UserAvatar` (design system) → `ProfileAvatar` (feature, delega a `UserAvatar`) → `CircleAvatar` cru (`change_avatar_page.dart`, único ponto que foge do padrão, por limitação técnica real — `UserAvatar` não aceita `MemoryImage`).

### Padrões diferentes para o mesmo elemento
- **Estado vazio/erro**: o padrão estabelecido é `EmptyState`/`ErrorState`, mas 5 telas o contornam com `Text`/`Center` cru (`public_profile_page.dart`×2, `event_detail_page.dart` nested, `create_event_page.dart` busca vazia, `admin_guard.dart`) — o mesmo "problema" (nada encontrado) tem pelo menos 2 aparências visuais diferentes dependendo da tela.
- **Estado "salvando"/"processando"**: em `admin_restaurants_page.dart`, `admin_roles_page.dart` e `moderation_page.dart`, o estado de mutação em andamento é silenciosamente colapsado com o estado "carregado" (sem spinner/disable visível), diferente do padrão usado no resto do app (`AppPrimaryButton.isLoading` nos formulários).
- **Menu de ações**: `group_detail_page.dart` (2×) e `comments_page.dart` usam `PopupMenuButton` cru sem `tooltip` explícito — não há um componente de menu do design system, então cada tela monta o próprio, sem padronização de acessibilidade.

### Widgets que deveriam ser unificados
- **`review_summary_tile.dart` é o item de maior alavancagem de toda a auditoria**: zero import de design system, alimenta 3 telas (`feed_page`, `reviews_list_page`, `public_profile_page`) simultaneamente. Corrigir este único widget (usar `ScoreBubble`, e considerar migrar para `AppCard`/algo mais estruturado que `ListTile`) melhora 3 telas de uma vez — mesmo princípio de alavancagem já identificado no `RC03_UX_AUDIT.md §9` (Matriz de Eliminação) para os 3 uploads de imagem duplicados.
- O padrão de upload de imagem (avatar/capa de restaurante/foto de review), já identificado como dívida na FASE 2, também é dívida visual: são 3 telas com 3 implementações visuais ligeiramente diferentes da mesma ideia ("selecionar → validar → enviar").

### Telas com identidade antiga (baixa adoção do Design System)
`settings_page.dart`, `admin_dashboard_page.dart`, `admin_users_page.dart`, `admin_restaurants_page.dart`, `admin_roles_page.dart`, `moderation_page.dart`, `audit_log_page.dart`, `admin_guard.dart` — **o cluster Administração inteiro** permanece com qualidade visivelmente anterior às rodadas UI-03B/UI-08, e isso **não é um acidente**: o próprio `UI-07_APPLY_DESIGN_SYSTEM.md §9.4` já documentava essa decisão explicitamente — *"Demais telas administrativas: sem alteração (ferramenta interna, prioridade baixa por decisão do plano)"*. Ou seja, é dívida visual **conscientemente assumida**, não esquecida — mas 2 sessões de refinamento depois (UI-03B foi em 2026-07-31/08-01), essa dívida nunca foi paga.

### Telas alinhadas ao novo padrão
`gamification_profile_page.dart` (única tela, junto com o Login, a usar gradiente de marca; motion completo), `review_detail_page.dart`, `event_detail_page.dart`, `group_detail_page.dart`, `comments_page.dart`, `groups_list_page.dart`, `events_list_page.dart`, `feed_page.dart`, `rankings_page.dart`/`group_ranking_page.dart` — todas com cobertura de estado completa via `AppAnimatedSwitcher` e uso consistente de tokens, mesmo com pequenos gaps pontuais (`ListTile` cru em vez de um `GroupCard`/`EventCard` que ainda não existe).

### Achado adicional: a tipografia "herói" documentada nunca chegou ao código
`UI-07_APPLY_DESIGN_SYSTEM.md §9.4` documenta explicitamente: *"Login: painel-herói com gradiente + 'BORAH' em `headlineLarge` (primeiro uso real dessa tipografia)"*. A auditoria de código desta fase (2 agentes independentes, grep exaustivo em toda `features/`) **não encontrou nenhum uso de `headlineLarge`/`displayLarge`/`displayMedium`/`displaySmall` em lugar nenhum do app hoje** — o wordmark "BORAH" no Login é uma imagem SVG (`SvgPicture.asset`), não texto estilizado. Isso não invalida a documentação em geral (o resto do UI-07/UI-08 se confirmou consistentemente correto nesta auditoria) — é um ponto específico e isolado onde a implementação final divergiu do que foi documentado, ou regrediu depois. Vale registrar como o único caso, em toda a FASE 3, de uma claim documentada que a auditoria de código não conseguiu confirmar.

---

## 7. Estratégia

### Quais telas deveriam ser redesenhadas primeiro
1. **Cluster Administração completo** (`admin_dashboard_page`, `admin_users_page`, `admin_restaurants_page`, `admin_roles_page`, `moderation_page`, `audit_log_page`, `admin_guard`) — é o grupo mais distante do padrão atual, e a decisão de deixá-lo para depois (UI-07 §9.4) já tem duas rodadas de idade. Redesenhar como um bloco único é mais eficiente que ir tela por tela, porque o gap é o mesmo em todas (tokens de espaçamento + `AppAnimatedSwitcher` + substituição de `ListTile` cru).
2. **`settings_page.dart`** — tela de alto tráfego (todo usuário passa por ela), 100% `ListTile` cru, sem nenhuma camada de componente.
3. **`public_profile_page.dart`** — não é uma questão de "não usar componente algum", é usar o componente errado por contornar `ErrorState`/`EmptyState` com `Text` cru; conceitualmente mais simples de corrigir que o cluster Administração, mas prioritário porque é uma tela pública/social de alta visibilidade.

### Quais podem ser apenas refinadas (não redesenhadas)
- `restaurants_search_page.dart`/`favorites_page.dart` — trocar `ListTile` por `RestaurantCard` (componente já existe, é literalmente plugar o que já foi construído para este caso exato).
- `groups_list_page.dart`/`events_list_page.dart` — mesma lógica, mas dependem primeiro da criação de `GroupCard`/`EventCard` (ver abaixo).
- `notifications_page.dart` — componentizar o indicador de não-lida.
- `profile_page.dart` — trocar o bloco `Card`+`ListTile` dos atalhos por algo mais alinhado (mesma correção que `settings_page.dart` precisa, então as duas deveriam ser resolvidas juntas).
- `review_summary_tile.dart` — adotar `ScoreBubble`; é um único arquivo, mas de alto impacto (3 telas de uma vez).
- `comments_page.dart`/`group_detail_page.dart` — adicionar `tooltip` explícito aos `PopupMenuButton`s (correção pontual de acessibilidade, não redesenho).

### Quais praticamente já estão prontas
`gamification_profile_page.dart` (referência de melhor prática — deveria ser o exemplo a seguir para "como uma tela BORAH deve parecer", inclusive para orientar o redesenho da Administração), `review_detail_page.dart`, `event_detail_page.dart`, `group_detail_page.dart`, `login_page.dart`/`signup_page.dart`/`password_reset_page.dart`/`new_password_page.dart` (fluxo de autenticação), todos os formulários de criação/edição em todos os módulos (padrão consistente e limpo em ~12 telas), `rankings_page.dart`/`group_ranking_page.dart`/`ranking_users_page.dart` (uso correto de `RankingCard`, só faltam tokens de espaçamento — ajuste trivial).

### Quais componentes precisam ser criados antes de qualquer redesign
1. **`GroupCard`** — já especificada em `UI-06_COMPONENT_LIBRARY.md §6` (nome/integrantes/próximo evento/ranking), nunca construída. Pré-requisito para refinar `groups_list_page.dart` de verdade (não só trocar `ListTile` por `AppCard` genérico).
2. **`EventCard`** — mesma situação, especificada em `UI-06 §6` (restaurante/data/hora/participantes/status), nunca construída. Pré-requisito para `events_list_page.dart`.
3. **Token de tamanho de ícone** (`AppIconSize.xs/sm/md/lg/xl`, valores já definidos em `UI-05_ICONOGRAPHY.md §6`, só nunca viraram constante Dart) — resolve de uma vez os ~9 arquivos com tamanho de ícone hardcoded, sem precisar tocar em cada um individualmente para "inventar" um valor.
4. **Decisão sobre `review_summary_tile.dart`**: não é um componente novo, é decidir se ele deveria adotar `ScoreBubble` e/ou virar algo mais estruturado que `ListTile` — dado o alcance (3 telas), vale tratar como prioridade de decisão antes de qualquer redesign nas 3 telas que o consomem, para não corrigir 3 vezes o mesmo problema separadamente.

---

**Aguardando revisão do usuário antes de prosseguir para `RC03_DESIGN_GAP.md` (FASE 4).**
