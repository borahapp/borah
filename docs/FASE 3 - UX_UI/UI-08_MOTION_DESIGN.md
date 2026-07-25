# UI-08 — Motion Design do BORAH

**Versão:** 1.3
**Status:** UI-08B2 implementada — aguardando próxima autorização
**Documento:** UI-08_MOTION_DESIGN.md
**Branch:** feature/ui-08-motion-design (base: develop @ ab24c1f)

---

# 1. Objetivo

Definir o sistema de Motion Design do BORAH: quando, onde e por quê animar, com tokens de duração/curva concretos, um conjunto pequeno de componentes reaproveitáveis e um inventário completo de oportunidades por tela — sem implementar nada nesta rodada.

Cada animação proposta tem um propósito funcional explícito (orientar o usuário, indicar mudança de estado, melhorar percepção de velocidade, reforçar identidade de marca ou aumentar a sensação de qualidade) — nenhuma é só estética.

---

# 2. Baseline (o que existe hoje)

Levantamento feito sobre toda a árvore `lib/` antes de qualquer proposta:

- **Nenhuma tela usa API de animação do Flutter.** Busca em todo `lib/` por `AnimatedContainer`, `AnimatedSwitcher`, `AnimatedOpacity`, `Hero(`, `AnimatedList`, `TweenAnimationBuilder`, `RepaintBoundary` — zero ocorrências fora de um único componente (`SkeletonLoader`).
- **`design_system/animations/`** já existe como pasta reservada (só `.gitkeep`) desde o UI-02 — este round a popula pela primeira vez.
- **UI-01_DESIGN_SYSTEM.md §12 ("Motion")** já continha a diretriz solta: duração 150–300ms, curvas suaves, evitar excesso, priorizar feedback funcional, mais uma lista de microinterações (botões, check-in, badges, XP, ranking, curtidas) — nunca virou token concreto.
- **`SkeletonLoader`** (`design_system/components/feedback/skeleton_loader.dart`) já tem animação própria (`AnimationController` de 900ms + `FadeTransition`) mas **zero usos** em qualquer tela.
- **`ConfirmationDialog`** e **`AppBottomSheet`** existem prontos na Component Library, também **zero usos**.
- **Router** (`core/router/app_router.dart`): toda rota é `GoRoute` puro, sem `pageBuilder`/`CustomTransitionPage` — transição 100% default do Material. `app_theme.dart` não define `pageTransitionsTheme`.
- **`feed_page.dart`** é a única tela com `RefreshIndicator` (pull-to-refresh) hoje.
- **Nenhum pacote de animação** no `pubspec.yaml` (sem `flutter_animate`, `lottie`, `rive`, `shimmer`).
- Achado mais concreto: a barra de XP da Gamificação (`gamification_profile_page.dart`) é um `FractionallySizedBox(widthFactor: progressToNextLevel)` que salta direto para o valor final — zero transição mesmo sendo o "momento herói" da tela (mesmo padrão que a UI-03B já tinha identificado e corrigido só a opacidade do trilho, não o preenchimento).

---

# 3. Restrições confirmadas com o usuário

- **Só APIs nativas do Flutter** nesta fase. Nenhuma dependência nova sem aprovação explícita (ver §9 — Exceções).
- **Escopo estritamente de motion.** `ConfirmationDialog`/`AppBottomSheet` não serão conectados a fluxos que hoje não os usam — isso é mudança de UX/fluxo, documentada à parte em §10 (Melhorias Futuras), fora do escopo desta rodada.

---

# 4. Tokens de Motion

Novo arquivo `design_system/animations/app_motion.dart`, mesmo padrão arquitetural de `AppSpacing`/`AppRadius`/`AppElevation`.

| Token | Valor | Uso |
|---|---|---|
| `AppMotion.fast` | 150ms | micro-interações (toggle de ícone, ripple) |
| `AppMotion.base` | 200ms | crossfade padrão (troca de estado) |
| `AppMotion.slow` | 300ms | transição de página, entrada de dialog/bottom sheet |
| `AppMotion.celebratory` | 500ms | barra de XP, desbloqueio de badge (únicos 2 usos) |
| `AppMotion.standard` | `Curves.easeInOut` | crossfades gerais |
| `AppMotion.emphasized` | `Curves.easeOutCubic` | entradas |
| `AppMotion.decelerate` | `Curves.easeOut` | saídas/dismiss |
| `AppMotion.bounce` | `Curves.elasticOut` | só o desbloqueio de badge |

Helper de acessibilidade central:
```dart
static Duration scaled(BuildContext context, Duration base) =>
    MediaQuery.of(context).disableAnimations ? Duration.zero : base;
```

---

# 5. Componentes-base reaproveitáveis

Quatro blocos genéricos cobrem quase todo o inventário (em vez de animar cada tela isoladamente):

1. **Crossfade de estado** — `AnimatedSwitcher` (duration `AppMotion.base`, curve `AppMotion.standard`) envolvendo só a região do `switch (status) {...}`, nunca o `Scaffold` inteiro. Resolve o padrão mais repetido do app (~15 telas com Loading/Empty/Error/Loaded).
2. **Barra/valor animado** — `TweenAnimationBuilder<double>` (`AppMotion.celebratory` / `AppMotion.emphasized`) para a barra de XP.
3. **Entrada escalonada de lista** — fade+slide-up com atraso incremental por índice (`AppMotion.fast` + ~30ms por item, limitado a ~8-10 itens visíveis).
4. **Ícone com pulso** — `AnimatedScale` (`AppMotion.fast` / `AppMotion.bounce` suave) para favoritar/curtir.

`AnimatedList` fica reservado só para listas que **realmente** inserem/removem item a item com a tela montada: tira de fotos da avaliação, lista de comentários, lista de favoritos (via `FavoritesSyncing`).

**Transição de página**: uma função `AppPageTransition` (fade, `AppMotion.slow`/`AppMotion.standard`) usada por todas as rotas via um `pageBuilder` compartilhado no router — mudança concentrada em 1 ponto, efeito em 100% da navegação.

**Diálogos/Bottom Sheets**: `AppDialog`/`AppBottomSheet` recebem duração/curva explícitas (`AppMotion.slow`/`AppMotion.emphasized`) preparando os componentes para quando forem conectados a telas (decisão de onde usá-los fica fora de escopo).

**Não aplicável hoje**: Hero/Shared Element (sem imagem compartilhada entre lista e detalhe de restaurante — revisitar se/quando cover-image for exibida na view), FAB (nenhuma tela usa), Ripple (já é padrão Material em toda a Component Library, nada a fazer), Snackbars (já usam animação default do `ScaffoldMessenger`, duração adequada).

---

# 6. Inventário completo por tela

Legenda: 🔴 Alta · 🟡 Média · 🟢 Baixa/opcional

| Tela | Animação hoje | Oportunidade | Componente Flutter | Prioridade | Impacto visual | Risco técnico |
|---|---|---|---|---|---|---|
| Splash | Loop do mascote (asset) | Nenhuma nova — já é o maior momento de marca | — | — | — | — |
| Login | Nenhuma | Crossfade de estado | AnimatedSwitcher | 🟢 | Baixo | Baixo |
| Cadastro | Nenhuma | Crossfade de estado | AnimatedSwitcher | 🟢 | Baixo | Baixo |
| Recuperação de senha | Nenhuma | Corte seco formulário→confirmação (jump-cut mais visível do funil) | AnimatedSwitcher | 🔴 | Alto | Baixo |
| Perfil | Nenhuma | Crossfade + Skeleton no loading | AnimatedSwitcher + SkeletonLoader | 🟡 | Médio | Baixo |
| Perfil Público | Nenhuma | Crossfade no botão Seguir | AnimatedSwitcher | 🟡 | Médio | Baixo |
| Restaurantes (busca) | Nenhuma | Crossfade + Skeleton + entrada escalonada + pull-to-refresh | AnimatedSwitcher + SkeletonLoader + stagger | 🔴 | Alto | Médio (lista reconstrói a cada busca) |
| Detalhes do Restaurante | Nenhuma | Crossfade + Skeleton + pulso no favoritar | AnimatedSwitcher + SkeletonLoader + AnimatedScale | 🔴 | Alto | Baixo |
| Reviews (lista) | Nenhuma | Crossfade + Skeleton + entrada escalonada | AnimatedSwitcher + SkeletonLoader + stagger | 🟡 | Médio | Baixo |
| Reviews (detalhe) | Nenhuma | Crossfade + pulso no curtir + AnimatedList na tira de fotos | AnimatedSwitcher + AnimatedScale + AnimatedList | 🔴 | Alto | Médio (exige `GlobalKey<AnimatedListState>`) |
| Rankings | Nenhuma | Entrada escalonada (sem add/remove reativo) | stagger | 🟡 | Médio | Baixo |
| Gamificação | Nenhuma | Preenchimento animado da barra de XP + pop de badge | TweenAnimationBuilder + AnimatedScale/AnimatedSwitcher | 🔴 | Alto | Baixo |
| Favoritos | Nenhuma | Crossfade + AnimatedList (remoção real via `FavoritesSyncing`) | AnimatedSwitcher + AnimatedList | 🟡 | Médio | Médio |
| Notificações | Nenhuma | Transição lida/não-lida por item (ponto + peso de fonte) | AnimatedContainer + AnimatedDefaultTextStyle | 🟡 | Médio | Baixo |
| Social (Feed/Comentários/Seguidores) | `RefreshIndicator` só no Feed | Crossfade de estado; AnimatedList real em Comentários (adiciona/remove) | AnimatedSwitcher + AnimatedList | 🟡/🟢 | Médio | Baixo/Médio |
| Administração | Nenhuma | Só o crossfade de estado herdado do componente-base | AnimatedSwitcher | 🟢 | Baixo | Baixo |

---

# 7. Performance

- `RepaintBoundary` em: itens de lista animados (stagger/AnimatedList), card de nível da Gamificação (contém o `TweenAnimationBuilder` que repinta a cada frame), `BorahSplashLoader` (já isola o asset).
- Wrapper de crossfade de estado envolve só a região que troca — nunca `Scaffold`/`AppBar`.
- `TweenAnimationBuilder`/`AnimatedScale` como widgets-folha (mesmo padrão já usado em `SkeletonLoader`), sem reconstruir os pais.
- Entrada escalonada limitada a ~8-10 itens visíveis, para não acumular atraso em listas longas.

# 8. Acessibilidade

- Toda duração passa por `AppMotion.scaled(context, ...)` — com "Reduzir movimento" ativo no SO, duração colapsa para `Duration.zero` (o conteúdo troca do mesmo jeito, só sem transição).
- Feedback funcional nunca depende de animação para ser percebido.
- Nenhuma animação bloqueia navegação/interação.
- Durações entre 150-500ms; nada em loop contínuo além do `BorahSplashLoader` (asset de marca já aprovado).

# 9. Exceções (dependência externa)

Nenhuma. Único candidato avaliado (celebração de badge/XP) é coberto por `TweenAnimationBuilder` + `Curves.elasticOut` nativo.

# 10. Melhorias Futuras (fora do escopo da UI-04)

| Componente sugerido | Telas afetadas | Benefício | Impacto UX | Impacto em testes |
|---|---|---|---|---|
| `ConfirmationDialog` | `review_detail_page.dart` (Excluir avaliação), `comments_page.dart` (Excluir comentário) | Previne exclusão acidental | Adiciona 1 passo ao fluxo | Quebra `integration_test/reviews/delete_test.dart` (assume exclusão direta) — precisa atualizar o teste antes |
| `AppBottomSheet` | Sem uso ainda; candidato: filtros de busca (Restaurantes) ou ações rápidas (Reviews) | Padrão mais mobile-nativo para ações secundárias | Muda a interação | Nenhum teste cobre hoje (seria novo) |

# 11. Cronograma recomendado

1. **Fase A — Fundação** (baixo risco, alto alcance): `AppMotion` tokens, wrapper de crossfade de estado, transição de página no router.
2. **Fase B — 🔴 Alta prioridade**: Recuperação de senha, Restaurantes (busca + detalhes), Reviews (detalhe), Gamificação.
3. **Fase C — 🟡 Média prioridade**: Perfil, Perfil Público, Reviews (lista), Rankings, Favoritos, Notificações, Social.
4. **Fase D — 🟢 Baixa prioridade / polimento**: Login, Cadastro, Administração.

Cada fase valida com `flutter analyze` + `dart format --set-exit-if-changed .` + `flutter test` (243/243) + validação visual via golden test (mesmo método da UI-03B).

---

# 12. Arquivos a criar/alterar (quando aprovada a implementação — nenhum tocado nesta rodada)

- `app/lib/design_system/animations/app_motion.dart` (novo)
- Pequenos wrappers reaproveitáveis em `design_system/components/feedback/`
- `app/lib/core/router/app_router.dart` (transição de página compartilhada)
- `app/lib/design_system/components/dialogs/app_dialog.dart`, `bottom_sheets/app_bottom_sheet.dart`
- ~15 arquivos de tela em `lib/features/**/presentation/pages/`

---

# 13. UI-08A — Fundação (implementada)

Escopo executado: `AppMotion` (tokens de duração/curva + `scaled()`) e os 4 componentes-base do §5 (`AppAnimatedSwitcher`, `AppAnimatedFraction`, `AppStaggeredListItem`, `AppPulseIcon`), todos em `design_system/`, exportados pelo barrel (`components.dart`/`design_system.dart`), **sem nenhum uso ainda em nenhuma tela** — exatamente o que o UI-08A pedia ("não aplicar animações nas telas ainda").

**Ajuste arquitetural em relação ao plano original**: o plano (§3/§11, Fase A) previa incluir nesta etapa a transição de página compartilhada no router e a duração/curva explícita de `AppDialog`/`AppBottomSheet`. Na implementação, adiei os dois para o UI-08B pelo seguinte motivo: `comments_page.dart` **já usa** `AppDialog` hoje (`_ReportDialog`) — mudar sua transição, ou trocar a transição de página do router (que afeta toda navegação do app), alteraria comportamento visual visível em telas reais agora, contrariando a instrução explícita desta etapa ("sem alterar o comportamento visual das telas", "não aplicar animações nas telas ainda"). Os 4 componentes-base construídos são novos e não conectados a nada, então não têm esse problema. Router e dialog/bottom-sheet ficam no início do UI-08B.

Arquivos criados:
- `app/lib/design_system/animations/app_motion.dart`
- `app/lib/design_system/components/feedback/app_animated_switcher.dart`
- `app/lib/design_system/components/feedback/app_animated_fraction.dart`
- `app/lib/design_system/components/feedback/app_staggered_list_item.dart`
- `app/lib/design_system/components/feedback/app_pulse_icon.dart`

Arquivos modificados:
- `app/lib/design_system/components/components.dart` (export dos 4 novos componentes)
- `app/lib/design_system/design_system.dart` (export de `animations/app_motion.dart`)
- `app/lib/design_system/animations/.gitkeep` removido (pasta deixou de estar vazia)

Validação: `flutter analyze` limpo, `dart format --set-exit-if-changed .` sem alterações, `flutter test` **243/243** (inalterado — nenhuma tela tocada, como esperado).

---

# 14. UI-08B1 — Aplicação nas 5 telas prioritárias (implementada)

Escopo: Splash, Recuperação de senha, Busca de Restaurantes, Detalhes do Restaurante, Gamificação. Só os 5 componentes autorizados (`AppAnimatedSwitcher`, `AppAnimatedFraction`, `AppStaggeredListItem`, `AppPulseIcon`, `AppMotion`), nenhum componente novo, nenhuma dependência nova.

| Tela | O que mudou |
|---|---|
| Splash | Transição de página (fade, `AppMotion.slow`/`standard`) só na rota `/` — entrada/saída da própria Splash, sem tocar a transição de `/login`/`/home` |
| Recuperação de senha | `AppAnimatedSwitcher` no corpo — formulário↔confirmação deixou de ser corte seco |
| Busca de Restaurantes | `AppAnimatedSwitcher` no corpo (Loading/Erro/Vazio/Carregado) + `AppStaggeredListItem` em cada linha da lista |
| Detalhes do Restaurante | `AppAnimatedSwitcher` no corpo + `AppPulseIcon` no ícone de favoritar |
| Gamificação | `AppAnimatedSwitcher` no corpo + `AppAnimatedFraction` na barra de XP (preenche animado em vez de saltar) + `AppPulseIcon` no badge ao mudar conquistado/bloqueado |

## Ajuste arquitetural: chave por "grupo visual", não por subtipo exato de estado

Ao aplicar `AppAnimatedSwitcher`, um primeiro rascunho dava a cada *branch* do `switch` uma `Key` baseada no subtipo exato do status (`ValueKey(status.runtimeType)`). Isso quebraria de duas formas:

1. **Teste** (`restaurants_search_page_test.dart`/`restaurant_detail_page_test.dart`, "estado de carregamento mostra indicador"): o controller passa por `Initial` → `Loading` (ambos renderizam `LoadingScreen`) entre o primeiro frame e o `pump()` do teste. Com chaves distintas por subtipo, o `AnimatedSwitcher` trataria isso como troca de conteúdo e animaria uma transição — deixando **dois** `CircularProgressIndicator` na árvore simultaneamente durante o cross-fade, quebrando `findsOneWidget`.
2. **Comportamento**: a barra de XP/o pop do badge (Gamificação) só fazem sentido se o `_ProfileView` for atualizado **no lugar** quando os dados mudam (ex.: XP subiu), não recriado do zero a cada `GamificationProfileLoaded`. Se a chave mudasse a cada carregamento, o `AppAnimatedFraction`/`AppPulseIcon` reiniciariam do zero a cada rebuild em vez de animar a partir do estado anterior.

Correção: a `Key` de cada *branch* reflete o **grupo visual** já definido pelo próprio `switch` (`'loading'`, `'error'`, `'empty'`, `'loaded'`), não o subtipo exato — `Initial`/`Loading`/`Searching`/`Filtering` compartilham `ValueKey('loading')`, por exemplo. `AnimatedSwitcher` só cross-fadeia quando o *grupo* muda de fato, e dados atualizados dentro do mesmo grupo (`'loaded'`) só re-renderizam o conteúdo, permitindo os componentes internos animarem corretamente a partir do valor anterior.

## Validação

- `flutter analyze`: limpo.
- `dart format --set-exit-if-changed .`: sem alterações.
- `flutter test`: **243/243** (nenhuma regressão).
- Validação visual (golden test temporário, removido ao final): confirmado layout íntegro nas 5 telas — Splash (gradiente inalterado), Recuperação de senha (formulário e confirmação), Busca de Restaurantes (spinner + card de filtro + lista com item), Detalhes do Restaurante (ícone de favorito no estado final, cartão de descrição), Gamificação (barra de XP preenchida corretamente após o assentamento, badges com pílulas coloridas corretas). A transição em si é temporal e não aparece num PNG estático — o que se confirma é ausência de regressão de layout.

Arquivos modificados: `core/router/app_router.dart`, `features/authentication/presentation/pages/password_reset_page.dart`, `features/restaurants/presentation/pages/restaurants_search_page.dart`, `features/restaurants/presentation/pages/restaurant_detail_page.dart`, `features/gamification/presentation/pages/gamification_profile_page.dart`.

---

# 15. UI-08B2 — Aplicação nas telas de prioridade média (implementada)

Escopo: Perfil, Perfil Público, Reviews (lista e detalhe), Rankings, Favoritos, Notificações (central e preferências), Social (comentários, seguidores, feed) — 11 telas. Só os 5 componentes autorizados (`AppMotion`, `AppAnimatedSwitcher`, `AppAnimatedFraction`, `AppStaggeredListItem`, `AppPulseIcon`), nenhum componente novo, nenhuma dependência nova.

| Tela | O que mudou |
|---|---|
| Perfil | `AppAnimatedSwitcher` no corpo (Loading/Erro/Carregado) |
| Perfil Público | `AppAnimatedSwitcher` em 3 regiões independentes: corpo (carregando/erro/dados), botão Seguir (troca de rótulo) e seção Avaliações |
| Reviews (lista) | `AppAnimatedSwitcher` no corpo + `AppStaggeredListItem` em cada `ReviewSummaryTile` |
| Reviews (detalhe) | `AppAnimatedSwitcher` no corpo + `AppPulseIcon` no ícone de curtir + `AppStaggeredListItem` na tira de fotos |
| Rankings | `AppAnimatedSwitcher` no corpo + `AppStaggeredListItem` em cada `RankingCard` |
| Favoritos | `AppAnimatedSwitcher` no corpo (`FavoritesSyncing`/`FavoritesLoaded` share a mesma chave) + `AppStaggeredListItem` na lista |
| Notificações (central) | `AppAnimatedSwitcher` no corpo + `AppStaggeredListItem` em cada notificação |
| Notificações (preferências) | `AppAnimatedSwitcher` no corpo (tela mínima, só o toggle) |
| Comentários | `AppAnimatedSwitcher` no corpo + `AppStaggeredListItem` em cada comentário |
| Seguidores/Seguindo | `AppAnimatedSwitcher` no corpo + `AppStaggeredListItem` em cada linha |
| Feed | `AppAnimatedSwitcher` no corpo (`FeedRefreshing`/`FeedLoaded` compartilham chave, preservando o `RefreshIndicator` sem interrupção) + `AppStaggeredListItem` em cada `ReviewSummaryTile` |

## Ajuste arquitetural: reafirmação do padrão "chave por grupo visual"

O mesmo padrão estabelecido na UI-08B1 (chave por *grupo visual*, não por subtipo exato do status) se mostrou necessário de novo, com um caso adicional relevante: em `favorites_page.dart`, `FavoritesSyncing`/`FavoritesLoaded` **precisam** compartilhar a mesma chave (`'loaded'`) porque o teste `favorites_page_test.dart` verifica, com um único `pump()` (sem `pumpAndSettle`), que o restaurante favoritado **continua visível** durante uma sincronização em segundo plano (`FavoritesSyncing` preserva a lista anterior por design, DV-06 §10/§11) — chaves distintas disparariam um cross-fade nesse instante e arriscariam deixar dois `ListTile` iguais na árvore simultaneamente. O mesmo raciocínio se aplica a `FeedRefreshing`/`FeedLoaded` em `feed_page.dart`, garantindo que o gesto de pull-to-refresh (`RefreshIndicator`) nunca seja interrompido por uma transição.

## Limitações encontradas (dentro do escopo desta rodada)

- **Sem `AnimatedList` de verdade**: 3 listas identificadas no plano original como candidatas a inserção/remoção reativa real (tira de fotos em `review_detail_page.dart`, comentários em `comments_page.dart`, item removido de favoritos com a tela aberta) receberam apenas **entrada escalonada** (`AppStaggeredListItem`) em vez de uma transição real de inserção/remoção — `AnimatedList` não está na lista de 5 componentes autorizados nesta rodada. O efeito visual nesses 3 pontos é mais simples do que o previsto originalmente no plano.
- **Sem transição por item lida/não-lida em Notificações**: o plano original prescrevia `AnimatedContainer`/`AnimatedDefaultTextStyle` para o ponto colorido e o peso da fonte mudarem suavemente quando uma notificação é marcada como lida — nenhum dos dois widgets está na lista de 5 componentes autorizados, então essa transição específica não foi implementada; a tela recebeu apenas o cross-fade de estado e a entrada escalonada da lista.
- **`AppDialog` (diálogo de denúncia em `comments_page.dart`) continua com a transição padrão do Flutter** — mesma decisão já registrada no UI-08A (§13): mexer na transição do componente em si está fora dos 5 componentes autorizados desta rodada.

## Validação

- `flutter analyze`: limpo.
- `dart format --set-exit-if-changed .`: sem alterações.
- `flutter test`: **243/243** (nenhuma regressão).
- Validação visual (golden test temporário, removido ao final): confirmado layout íntegro nas 11 telas — identidade/avaliações no Perfil Público, card de ranking com posição, filtro+lista de favoritos com pílula de nota, notificação não lida com o ponto colorido, preferências com o switch, comentário+campo de envio, seguidor com avatar, item de feed. Ausência de regressão de layout confirmada; a transição em si é temporal e não aparece num PNG estático.

Arquivos modificados: `features/users/presentation/pages/profile_page.dart`, `features/social/presentation/pages/public_profile_page.dart`, `features/reviews/presentation/pages/reviews_list_page.dart`, `features/reviews/presentation/pages/review_detail_page.dart`, `features/rankings/presentation/pages/rankings_page.dart`, `features/favorites/presentation/pages/favorites_page.dart`, `features/notifications/presentation/pages/notifications_page.dart`, `features/notifications/presentation/pages/notification_preferences_page.dart`, `features/social/presentation/pages/comments_page.dart`, `features/social/presentation/pages/follow_list_page.dart`, `features/social/presentation/pages/feed_page.dart`.
