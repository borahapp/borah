# UI-07 — Aplicação do Design System (UI-03 + UI-03B)

**Versão:** 2.0
**Status:** Aguardando aprovação
**Documento:** UI-07_APPLY_DESIGN_SYSTEM.md
**Branch:** feature/ui-03-apply-design-system (base: develop @ 86e3154)

---

# 1. Objetivo

Registrar a aplicação da Component Library (UI-02) e dos Brand/Material Tokens (UI-01) em todas as telas do BORAH, executada na rodada UI-03, incluindo a migração arquitetural UI-03A (centralização definitiva de componentes em `design_system/components/`).

Somente a camada visual foi alterada. Regras de negócio, providers, controllers, estados, APIs, Supabase, autenticação e navegação foram integralmente preservados.

---

# 2. UI-03A — Component Migration

`AppPrimaryButton` e `AppTextField` foram movidos de `core/widgets/` para `design_system/components/buttons/` e `design_system/components/inputs/`, respectivamente. O diretório `core/widgets/` foi removido.

Todos os 15 arquivos de `lib/features/**/presentation/pages/` que importavam os componentes pelo caminho antigo foram atualizados para o novo caminho. `design_system/components/components.dart` passou a exportar os dois componentes.

---

# 3. Inventário Inicial (ETAPA 0)

Levantamento feito sobre as 39 telas de `lib/features/**/presentation/` antes de qualquer alteração.

| Widget | Ocorrências | Risco predominante |
|---|---|---|
| `AppBar` cru | 23 telas | Baixo |
| `IconButton` sem tooltip | ~12 | Baixo (acessibilidade) |
| `OutlinedButton`/`TextButton`/`ElevatedButton` crus | ~25 | Baixo (wrappers preservam o tipo real) |
| `TextField`/`TextFormField` já usando `AppTextField` | — | — (UI-02 já cobria) |
| `Center(child: CircularProgressIndicator())` | ~20 | Baixo |
| `Center(child: Text(...))` (estado vazio) | 13 mensagens distintas | Baixo |
| `Card` cru | 1 (`admin_dashboard_page.dart` `_KpiCard`) | Baixo |
| `AlertDialog` cru | 1 (`comments_page.dart` `_ReportDialog`) | Médio (stateful, controller próprio) |
| `ListTile` como ranking (`CircleAvatar` + posição) | 2 (`rankings_page.dart`, `ranking_users_page.dart`) | Baixo (sem cobertura de Integration Test) |
| `ListTile` como linha de restaurante | 2 (`restaurants_search_page.dart`, `favorites_page.dart`) | **Alto** — `find.widgetWithText(ListTile, nome)` é usado diretamente e transitivamente (via `openRestaurantByName`) por quase toda a suíte de Integration Test (QA-03) |
| Rating renderizado como `Text` cru | 5 lugares, formatação inconsistente | Variável — ver §5 |
| Bug real encontrado | `rankings_page.dart` renderizava a string literal `"null (3)"` quando `averageRating` era nulo (interpolação sem checagem de nulidade) | — |
| `CircleAvatar` com `MemoryImage` (preview local) | 1 (`change_avatar_page.dart`) | Médio — `UserAvatar` não suporta `MemoryImage` |
| Componentes duplicados | Padrão de ranking (`CircleAvatar` + posição) duplicado entre 2 arquivos; padrão de busca (`AppTextField` sem lupa/limpar) duplicado entre 2 arquivos | — |

---

# 4. Telas migradas

Todas as 39 telas de apresentação foram revisadas; a tabela abaixo resume o que mudou por feature.

| Feature | Telas | Migrações aplicadas |
|---|---|---|
| authentication | login, signup, password_reset, email_verification, splash | `AppTopBar`, `AppTextButton`, `AppPasswordField`, `LoadingScreen` |
| users | profile, edit_profile, change_avatar, settings, `profile_avatar` (widget) | `AppTopBar`, `AppIconButton`, `AppOutlinedButton`, `AppTextButton`, `LoadingScreen`, `UserAvatar` |
| restaurants | restaurants_search, restaurant_detail, create_restaurant | `AppTopBar`, `AppIconButton`, `AppSearchField`, `AppOutlinedButton`, `LoadingScreen`, `EmptyState`, `ScoreBubble` (parcial — ver §5) |
| reviews | reviews_list, review_detail, create_review, edit_review | `AppTopBar`, `AppIconButton`, `AppOutlinedButton`, `AppTextButton`, `LoadingScreen`, `EmptyState`, `ScoreBubble` |
| favorites | favorites_page | `AppTopBar`, `AppSearchField`, `LoadingScreen`, `EmptyState`, `ScoreBubble` |
| social | feed, public_profile, comments, follow_list | `AppTopBar`, `AppOutlinedButton`, `AppTextButton`, `AppIconButton`, `AppDialog`, `LoadingScreen`/`LoadingIndicator`, `EmptyState` |
| rankings | rankings_page | `AppTopBar`, `LoadingScreen`, `EmptyState`, **`RankingCard`** (corrige o bug `"null (3)"`) |
| gamification | gamification_profile, ranking_users | `AppTopBar`, `AppIconButton`, `LoadingScreen`, `EmptyState`, **`RankingCard`** |
| notifications | notifications, notification_detail, notification_preferences | `AppTopBar`, `AppIconButton`, `AppOutlinedButton`, `LoadingScreen`, `EmptyState` |
| administration | admin_dashboard, admin_users, admin_restaurants, admin_roles, moderation, audit_log, `admin_guard` | `AppTopBar`, `AppOutlinedButton`, `AppTextButton`, `AppSearchField`, `AppCard`, `LoadingScreen`, `EmptyState` |
| core/router | `_BootstrapPlaceholderPage` (Home provisório) | `AppTextButton` nos 8 links de navegação (isolado — sem alteração da arquitetura de navegação) |

---

# 5. Decisões de risco e itens adiados

## 5.1 Preservado por acoplamento com Integration Test (QA-03)

- **`restaurants_search_page.dart`, `favorites_page.dart`** — a linha de restaurante continua `ListTile` (não migrada para `RestaurantCard`). `find.widgetWithText(ListTile, nome)` é usado diretamente e, via `integration_test/helpers/ui_flows.dart` (`openRestaurantByName`), por quase toda a suíte. Apenas o `trailing` (nota) foi trocado por `ScoreBubble`, preservando o `ListTile`.
- **`restaurant_detail_page.dart`** — o texto da nota (`'${rating} (${total} avaliações)'`) foi mantido como `Text` cru, não migrado para `ScoreBubble`. Motivo: `test/widget/restaurants/restaurant_detail_page_test.dart` verifica o texto exato `"4.5 (8 avaliações)"` — uma tentativa inicial de usar `ScoreBubble` (formato `"4.5 (8)"`, sem a palavra "avaliações") quebrou esse teste; foi revertida antes da validação final.
- **`review_detail_page.dart`, `review_summary_tile.dart`** — o botão "Excluir" continua `AppTextButton` simples (sem `ConfirmationDialog`), preservando o fluxo de exclusão direta que `integration_test/reviews/delete_test.dart` assume. `review_summary_tile.dart` (usado por `ReviewsListPage`, `FeedPage` e `PublicProfilePage`) não foi alterado — é o widget mais acoplado a Integration Tests da base (`delete_test.dart`, `edit_test.dart`, `feed_test.dart`, `feed_update_test.dart` dependem do `Text(rating)` exato e de comparação de posição vertical).
- **`change_avatar_page.dart`** — o preview local (`CircleAvatar` com `MemoryImage`) foi mantido; `UserAvatar` não suporta `MemoryImage`, apenas `NetworkImage`/ícone padrão.

## 5.2 Sem componente equivalente na Library (mantidos crus, por regra "não criar novos componentes")

`PopupMenuButton` (`comments_page.dart`), `SwitchListTile` (`notification_preferences_page.dart`), `SegmentedButton` (`ranking_users_page.dart`), `DropdownButton` (`favorites_page.dart`, `admin_roles_page.dart`), `ListTile` de ação administrativa (3 arquivos — apenas o botão interno foi migrado, não a linha).

## 5.3 Bug corrigido

`rankings_page.dart` renderizava `"null (3)"` quando `averageRating` era nulo. A migração para `RankingCard` (que usa `trailingLabel: String?`, omitido quando nulo) elimina a string literal `"null"`.

## 5.4 Correção de acessibilidade colateral (fora do escopo original, corrigida por necessidade)

O botão de sufixo de `AppTextField` (usado por `AppSearchField`/`AppPasswordField` desde o UI-02) não tinha `tooltip`, violando a diretriz mínima de acessibilidade (`Tappable widgets should have a semantic label`) — só foi detectado ao rodar `flutter test` completo, quebrando `login_page_test.dart` e `signup_page_test.dart` ("atende às diretrizes básicas de acessibilidade"). Adicionado o parâmetro `suffixIconTooltip` em `AppTextField`, propagado por `AppPasswordField` ("Mostrar senha"/"Ocultar senha") e `AppSearchField` ("Limpar busca").

---

# 6. Validação executada

- `flutter analyze`: sem ocorrências.
- `dart format --set-exit-if-changed .`: sem alterações pendentes.
- `flutter test`: **243/243** (nenhuma regressão).
- Validação visual em emulador Android e execução da suíte de Integration Test do QA-03: **não executadas nesta rodada** — o ambiente atual não tem um emulador Android disponível (`flutter devices` lista apenas Windows desktop, Chrome e Edge), a mesma limitação de ferramental já registrada no EX-01. Fica pendente para quando o ambiente com emulador estiver disponível.

---

# 7. Pendências para UI-04

- Migração de `RestaurantCard` em `restaurants_search_page.dart`/`favorites_page.dart` (hoje `ListTile`) — depende de atualizar antes os finders de Integration Test que dependem de `ListTile`.
- Migração de `ScoreBubble` em `restaurant_detail_page.dart` e `review_summary_tile.dart` — depende de atualizar antes os testes/finders que verificam o texto exato da nota.
- `ConfirmationDialog` nos fluxos de exclusão de avaliação/comentário (hoje sem confirmação) — mudança de comportamento, fora do escopo "somente visual" desta rodada.
- Restruturação do Home (`_BootstrapPlaceholderPage` em `core/router/app_router.dart`) para uma navegação por abas real — adiado desde o UI-02, continua exigindo uma nova arquitetura de navegação, não uma troca mecânica de componente.
- Rodar a suíte de Integration Test do QA-03 e a validação visual em emulador Android assim que o ferramental estiver disponível.

---

# 8. Métricas da migração

- Telas revisadas: 39.
- Arquivos com `AppTopBar` aplicado: 30 (31 ocorrências — `password_reset_page.dart` tem 2).
- Ocorrências de `AppIconButton` aplicadas: 10 (todas com `tooltip`; algumas antes não tinham nenhum).
- Ocorrências de `LoadingScreen` aplicadas: 24.
- Ocorrências de `EmptyState` aplicadas: 14.
- Ocorrências de `RankingCard` aplicadas: 2 (corrige o bug `"null (3)"`).
- Ocorrências de `ScoreBubble` aplicadas: 3 (`restaurants_search_page.dart`, `favorites_page.dart`, `review_detail_page.dart`).
- `AlertDialog` cru substituído por `AppDialog`: 1.
- `Card` cru substituído por `AppCard`: 1.
- Arquivos de componente do Design System corrigidos/estendidos (fora da lista de migração original): 3 (`app_text_field.dart`, `app_search_field.dart`, `app_password_field.dart` — correção do `suffixIconTooltip`).

---

# 9. UI-03B — Refinamento Visual

Rodada de aprofundamento sobre o resultado do UI-03: a migração de componentes (acima) trocou os widgets pelo equivalente do Design System, mas não revisou hierarquia visual, espaçamento, composição ou uso real de cor/marca. A UI-03B faz essa segunda passada, telas que permanecem no produto final (a Home, por ser `_BootstrapPlaceholderPage` — placeholder que será substituído por navegação em abas — ficou fora do escopo por decisão explícita).

## 9.1 Achados da auditoria prévia

- Tokens de spacing/radius/elevation existem e são específicos, mas **nenhuma tela usava `AppSpacing.*`** — todo espaçamento era número cru, com padrões inconsistentes entre telas irmãs.
- `BrandGradients`/`AppGradients` (definidos desde o UI-01) tinham **zero usos** em `features/` — o gradiente oficial nunca aparecia em nenhuma tela.
- Tipografia "herói" (`headlineLarge`/`displayX`) tinha **zero usos** em qualquer lugar do app.
- `app_theme.dart` não definia `AppBarTheme`/`DialogTheme`/`ChipTheme` — tudo caía no padrão Material 3 puro.
- `AppChip`/`AppBadge` (Component Library, UI-02) existiam e tinham **zero usos**.
- Um bug real foi encontrado e não corrigido no UI-03: nenhum, mas 2 assets oficiais de marca (loop de loading e ícone de localização) chegaram via os pacotes `BORAH_Sistema_Animacoes_Oficial.zip`/`BORAH_Biblioteca_Visual_Oficial.zip` — a maior parte de ambos os pacotes é material de marketing (vídeos de assinatura/Reels, patterns, selos, stickers para redes sociais) sem uso no app; só o loop de loading e o ícone de localização foram aprovados e trazidos para `assets/` (ver §9.2 e `assets/ASSETS.md`).

## 9.2 Assets oficiais organizados

Nova estrutura em `assets/` (documentada em `assets/ASSETS.md`): `branding/` e `illustrations/` reservados (sem asset aprovado ainda), `loading/borah_loading.webp` (+ `.gif` de fallback, fora do bundle) e `icons/borah_location.png` (+ `.svg` fonte, fora do bundle). Vídeos de assinatura/encerramento de Reels e demais assets de marketing ficaram fora do repositório, por decisão explícita.

## 9.3 Tema global (`core/theme/app_theme.dart`)

- `AppBarThemeData`: `centerTitle: false` (documentado), `scrolledUnderElevation: AppElevation.level1` (troca o valor não-documentado do M3 pela escala BORAH).
- `DialogThemeData`: `shape` com `AppRadius.radiusXl` (24), substituindo o default M3 de 28 (fora da escala BORAH).
- `ChipThemeData`: formato pílula (`StadiumBorder`), `labelStyle` via `AppTypography`, cores via `ColorScheme` — prepara `AppChip`/`AppBadge` para uso (ainda sem tela usando `AppChip`).

## 9.4 Telas alteradas

| Área | Telas | O que mudou |
|---|---|---|
| Autenticação | splash, login, signup, password_reset, email_verification | Splash: gradiente oficial (`AppGradients.purple`) + loop de loading oficial (`BorahSplashLoader`, novo widget dedicado — `LoadingScreen` continua com o spinner padrão, usado por outras 5 telas cujos testes verificam `CircularProgressIndicator`). Login: painel-herói com gradiente + "BORAH" em `headlineLarge` (primeiro uso real dessa tipografia), formulário top-aligned (era `Center`). Password reset: ícone no estado de sucesso. Email verification: ícone antes do parágrafo. Todas: `AppSpacing.*` no lugar de números crus. |
| Perfil/Gamificação | profile, edit_profile, change_avatar, public_profile, gamification_profile | Gamificação: cartão de nível com `colorScheme.inverseSurface` + barra de XP em gradiente verde oficial + label "X XP para o próximo nível"; badges conquistados/bloqueados via `AppBadge` (existia, 0 usos) no lugar do ícone com `Colors.amber` cru. Perfil público: bloco de identidade (avatar/nome/bio/seguir) agrupado em `AppCard`, separado da lista de avaliações por um `SectionHeader`. `AppSpacing.*` em todos os 5 arquivos. |
| Restaurantes/Reviews | restaurants_search, restaurant_detail, create_restaurant, reviews_list, review_detail, create_review, edit_review | Detalhe do restaurante: descrição agrupada em `AppCard` (nota do rating manteve o `Text` cru — ver §9.5). Busca/favoritos: área de filtro agrupada em `AppCard` (linha do `ListTile` não tocada). Cadastro de restaurante: campos agrupados em 2 `SectionHeader` ("Informações do restaurante"/"Localização"). `AppSpacing.*`/`AppRadius.*` em todos. |
| Favoritos/Notificações/Social | favorites, notifications, notification_detail, notification_preferences, feed, public_profile, comments, follow_list | Notificações: indicador de não-lida (ponto colorido) além do `FontWeight.bold`. Lista de seguidores/seguindo: `ProfileAvatar` adicionado (não tinha nenhum). `AppSpacing.*` no restante. |
| Administração | admin_restaurants | Status "active"/"archived" (texto cru) → `AppBadge`. Demais telas administrativas: sem alteração (ferramenta interna, prioridade baixa por decisão do plano). |
| Ícone de localização | restaurant_detail, restaurants_search, favorites | `assets/icons/borah_location.png` adicionado antes do texto de localização/cidade — o `Text` em si não mudou (finders de teste continuam válidos). |

## 9.5 Decisões de risco desta rodada

- **`restaurant_detail_page.dart`**: uma primeira tentativa usou `ScoreBubble` para a nota (formato `"4.5 (8)"`), mas `test/widget/restaurants/restaurant_detail_page_test.dart` verifica o texto exato `"4.5 (8 avaliações)"` — revertido para `Text` cru antes da validação final (mesma decisão já registrada no UI-03, §5.1, reconfirmada).
- **`LoadingScreen` vs `BorahSplashLoader`**: uma primeira tentativa trocou `LoadingScreen` inteiro (usado em ~24 telas) pelo asset animado, quebrando 5 testes de widget que verificam `find.byType(CircularProgressIndicator)` para o estado de carregamento de listagens (`favorites_page_test.dart`, `restaurants_search_page_test.dart`, `restaurant_detail_page_test.dart`, `review_detail_page_test.dart`, `feed_page_test.dart`). Corrigido criando `BorahSplashLoader` como widget dedicado, usado só na Splash — o "loading do aplicativo" do material oficial é especificamente o momento de bootstrap, não cada spinner de lista.
- **`AppGradients.of(context)`**: o uso inicial de `Theme.of(context).extension<AppGradients>()!` quebrava `login_page_test.dart` (9 testes), cujo `_wrap()` monta um `MaterialApp.router` sem `AppTheme`. Em vez de alterar o teste, foi adicionado `AppGradients.of(context)` (cai em `AppGradients.brand` quando a extensão não está registrada — valor idêntico ao de produção, só resiliência de ambiente de teste).
- **Card de nível da gamificação**: a ideia inicial era um fundo "Preto Uva" fixo, mas isso ficaria invisível no Dark Theme (onde o fundo da página já é Preto Uva). Usado `colorScheme.inverseSurface`/`onInverseSurface` — sempre contrasta com a página, em ambos os temas, sem importar `BrandColors`/`AppColors` diretamente na tela (regra de camadas do UI-01 preservada).

## 9.6 Validação executada

- `flutter analyze`: sem ocorrências.
- `dart format --set-exit-if-changed .`: sem alterações pendentes.
- `flutter test`: **243/243** (nenhuma regressão, após as 2 correções de §9.5).
- Validação visual em emulador Android e suíte de Integration Test do QA-03: **não executadas** — mesma limitação de ferramental já registrada no UI-03/EX-01 (sem emulador Android neste ambiente).

## 9.7 Pendências

- `RestaurantCard`/`ScoreBubble` em telas acopladas a Integration Test/widget test (ver §5.1/§9.5) — mesma pendência do UI-03, ainda não resolvida.
- Rodar a suíte de Integration Test do QA-03 e a validação visual em emulador Android assim que houver ferramental disponível.
- Home (`_BootstrapPlaceholderPage`) permanece sem tratamento visual — fica para a fase de navegação em abas.
- `AppChip` continua sem nenhum uso em tela (tema já preparado em §9.3).
