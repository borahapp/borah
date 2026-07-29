# RC-01 — Auditoria Completa do Aplicativo BORAH

**Data:** 2026-07-25
**Branch auditada:** `develop` @ `444747f`
**Tipo:** Auditoria somente-leitura (nenhum código, branch, commit, merge ou push foi realizado nesta rodada)
**Método:** 8 agentes de exploração paralelos, cada um cobrindo um recorte do app (fluxos de Autenticação/Perfil, fluxos Sociais/Notificações/Gamificação/Admin/Home, Restaurantes/Reviews/Favoritos/Rankings, uso do Design System, consistência de Motion Design, Performance, Qualidade de Código/Arquitetura/Testes), com citação de arquivo:linha em cada achado.

---

## 1. Resumo Executivo

O BORAH chega à RC-01 com uma base sólida: arquitetura em camadas aplicada sem desvios em 10 features, Design System com adoção praticamente completa (zero widgets Material crus para botões/diálogos/bottom sheets/app bars em `lib/features/`), tipografia 100% centralizada, e Motion Design (UI-08) conectado a 14 das 16 telas onde se aplica. Não foram encontrados problemas de segurança, de regra de negócio ou de arquitetura de dados — o escopo desta auditoria (UX, UI, Motion, Performance, Acessibilidade, Código, Testes) não toca nesses pontos, e nada do que foi encontrado exige mudança de modelo de dados ou de contrato de API.

Os problemas mais relevantes encontrados **não são bugs de regra de negócio**, e sim lacunas de conexão entre camadas que já existem:

- **Paginação construída e nunca usada**: `loadNextPage()` existe em 3 controllers (`favorites`, `rankings`, `reviews`) e nunca é chamado pelas telas; `restaurants` nem tem o método, apesar do modelo de filtros já suportar `page`/`limit`. Listas grandes são truncadas silenciosamente.
- **Sincronização em tempo real construída e nunca usada**: `FavoritesController.refresh()`/`FavoritesSyncing` existe, citando explicitamente "tempo real" no comentário, mas nunca é acionado por nenhum gesto na tela de Favoritos.
- **Sem opção de reenvio de e-mail de verificação**: conta pode ficar permanentemente presa se o e-mail de confirmação não chegar.
- **Logout sem confirmação e sem feedback de erro**: `SettingsPage` não observa `authControllerProvider`, então uma falha ao sair da conta passa silenciosamente, parecendo travamento do app.
- **Upload de foto em Reviews substitui a tela inteira por um spinner**: perde-se o contexto (nota, comentário, fotos já enviadas) a cada foto adicionada — o ponto de fricção de motion mais visível do app.
- **Padrão repetido de erro sem retry**: praticamente toda tela usa `Center(child: Text(message))` como estado de erro, sem botão de tentar novamente — um componente `ErrorState` (análogo ao `EmptyState` já existente) resolveria isso de uma vez em ~15 telas.
- **Cobertura de testes desigual**: 23 de 33 páginas sem teste de widget; `administration`, `notifications`, `rankings`/`gamificação` sem nenhuma cobertura de integração.

Nenhum desses pontos bloqueia o lançamento por si só, mas juntos formam uma lista clara de prioridades para o próximo ciclo. O documento abaixo detalha cada fluxo, cada achado transversal (Design System, Motion, Performance, Código/Testes) e propõe uma priorização objetiva para decisão do usuário.

---

## 2. Pontos Fortes

- **Arquitetura**: as 10 features seguem `domain/data/application/presentation` sem nenhum desvio de camada detectado (nenhum widget em `domain/`, nenhuma regra de negócio em `presentation/`). Migração de `core/widgets/` para `design_system/components/` (UI-03A) está 100% completa.
- **Design System**: zero ocorrências de `Card(`, `AlertDialog(`, `showModalBottomSheet(`, `ElevatedButton(`, `TextButton(`, `OutlinedButton(`, `IconButton(`, `AppBar(` cru, `showDialog(` ou `BottomSheet(` genérico em `lib/features/` — adoção completa para essas categorias. `BorderRadius.circular(` cru: 0 ocorrências (100% via `AppRadius`). Tipografia: 0 literais de `fontFamily`/`fontSize` fora de `design_system/typography/`. Cor: apenas 1 ocorrência de `Colors.` cru em todo `lib/features/`.
- **Motion Design (UI-08)**: tokens (`AppMotion`) e os 4 componentes reaproveitáveis (`AppAnimatedSwitcher`, `AppAnimatedFraction`, `AppStaggeredListItem`, `AppPulseIcon`) aplicados consistentemente em 14-15 telas, com zero overrides de duração/curva (nenhum drift de token). `AppMotion.scaled()` corretamente invocado em todos os 4 componentes para respeitar `disableAnimations`.
- **Telas de referência**: `public_profile_page.dart` e `gamification_profile_page.dart` são os melhores exemplos do app — múltiplos `AppAnimatedSwitcher` aninhados com `ValueKey`s granulares, `AppAnimatedFraction`/`AppPulseIcon` usados corretamente, sem gambiarra.
- **Código**: nenhum TODO/FIXME/HACK real encontrado; comentários seguem a convenção "só WHY" (exceções corretas: `auth_controller.dart:45-54`, `follower_repository_impl.dart:71-72`, `rankings_controller.dart:7-13`); higiene de imports boa (nenhuma tela de feature importa o barril completo do Design System, só `components/components.dart` ou arquivos individuais).
- **Testes**: 24 de 26 controllers com teste unitário; suíte de testes usa `Completer` para controlar estados assíncronos (evita `Duration` arbitrário/flakiness clássica); checagens de acessibilidade/responsividade presentes sistematicamente nos testes de widget existentes.
- **Componentes bem desenhados**: `AppStaggeredListItem` já embrulha em `RepaintBoundary`; `AdminGuard` limpo e correto; `AppPulseIcon` aplicado de forma consistente em favoritar/curtir/badge desbloqueado.

---

## 3. Revisão por Fluxo

Para cada fluxo: pontos positivos, possíveis melhorias, problemas encontrados e prioridade (🔴 Alta · 🟡 Média · 🟢 Baixa).

### Splash
- **Positivos**: separação limpa (`splash_page.dart:25-35`), `BorahSplashLoader` sobre gradiente de marca, única transição `CustomTransitionPage` (fade) do router.
- **Melhorias**: falta `Semantics`/label no asset de loading; falha de rede em `restoreSession()` (não apenas ausência de sessão) leva ao `/login` sem nenhum feedback.
- **Problema encontrado**: o loop animado do mascote (WebP multi-frame via `Image(AssetImage(...))`) não respeita `disableAnimations` — com "Reduzir movimento" ativo no SO, é a única animação do app que continua rodando.
- **Prioridade**: 🟢 Baixa.

### Login
- **Positivos**: tokens de gradiente/spacing no cabeçalho, `listenForAuthErrors` compartilhado, `AppPrimaryButton` se autodesabilita durante loading.
- **Melhorias**: "Esqueci minha senha"/"Criar conta" continuam habilitados durante `isLoading`, permitindo navegar para fora enquanto `signIn` ainda está em andamento.
- **Problema encontrado**: `login_page.dart:69` usa `Colors.white` cru em vez de um token de cor (ex. `colorScheme.onPrimary`) — único ponto do app fora do padrão de cor 100% tokenizada.
- **Prioridade**: 🟡 Média.

### Cadastro
- **Positivos**: `AppTopBar` com voltar, reaproveita `validatePassword`.
- **Melhorias**: sem campo de confirmação de senha — um erro de digitação só é pego pela validação do backend (ou nunca).
- **Problemas**: nenhum novo além da melhoria acima.
- **Prioridade**: 🟡 Média.

### Recuperação de senha
- **Positivos**: único fluxo de autenticação já usando `AppAnimatedSwitcher` corretamente (form↔enviado, com `ValueKey`s distintas).
- **Melhorias**: estado "enviado" não tem CTA explícito (ex. "Voltar para o login"), diferente do padrão usado em verificação de e-mail.
- **Prioridade**: 🟢 Baixa.

### Verificação de e-mail
- **Positivos**: CTA claro de volta ao login.
- **Problema encontrado (dead-end real)**: não existe nenhuma ação de "reenviar e-mail" — `AuthController` não expõe `resendVerificationEmail`; se o e-mail nunca chega, a conta fica presa (nem é possível recriar o cadastro com o mesmo e-mail).
- **Prioridade**: 🔴 Alta.

### Home
- Confirmado como placeholder já documentado e intencionalmente fora de escopo (`_BootstrapPlaceholderPage`, `app_router.dart:274-320`) — sem navegação por abas ainda. Não é um achado novo, apenas registrado para contexto.
- **Prioridade**: N/A (gap já conhecido).

### Restaurantes — Busca
- **Positivos**: `AppAnimatedSwitcher`/`AppStaggeredListItem` corretos; busca e filtro de cidade combinados em um único `AppCard`.
- **Melhorias**: filtro só aplica no Enter dos campos, sem botão explícito "Buscar"; `EmptyState` não usa `icon`/`action` (poderia oferecer "Cadastrar restaurante").
- **Problema encontrado**: `RestaurantsController` não tem `loadNextPage`, mesmo com o modelo de filtros já suportando paginação e o repositório já calculando `hasNextPage` — buscas com mais de 20 resultados são truncadas silenciosamente. Sem pull-to-refresh.
- **Prioridade**: 🟡 Média.

### Restaurantes — Detalhes / Cadastro / Alterar capa
- **Positivos**: `AppPulseIcon` no favoritar, tratamento de erro de imagem com `SnackBar`.
- **Melhorias**: não há indicação visual de "sem foto de capa"; troca de capa aciona `LoadingScreen` de tela inteira em vez de indicador local no botão.
- **Problema encontrado**: `create_restaurant_page.dart` reaproveita o mesmo `restaurantDetailControllerProvider` (não `autoDispose`) usado por `RestaurantDetailPage` — acoplamento frágil entre duas telas de propósitos distintos (não quebra hoje, mas é risco latente).
- **Prioridade**: 🟢 Baixa.

### Reviews — Lista / Detalhes / Criação / Edição
- **Positivos**: reaproveita `ReviewSummaryTile`, `AppStaggeredListItem`; boa composição de ações no detalhe (curtir com `AppPulseIcon`, compartilhar, comentários, editar/excluir).
- **Melhorias**: nota digitada em campo de texto livre em vez de estrelas/slider; validação só roda no submit, sem feedback incremental; `EmptyState` sem `icon`/`action`.
- **Problemas encontrados**:
  - `ReviewsController.loadNextPage()` existe e nunca é chamado — mesma lacuna de paginação órfã. Sem pull-to-refresh.
  - **Upload de foto substitui a tela inteira por `LoadingScreen`** (`review_detail_controller.dart:114`) — nota, comentário e fotos já enviadas somem por ~1s a cada foto adicionada. Maior ponto de fricção de motion encontrado no app.
  - `create_review_page.dart` e `edit_review_page.dart` duplicam quase integralmente a mesma árvore de formulário (nota + comentário + botão) — candidato claro a um `_ReviewForm`/`ReviewFormScaffold` compartilhado.
  - `_ReportDialog` (em Comentários, mas mesmo padrão de review) fecha imediatamente ao denunciar e dispara a chamada de rede sem feedback próprio de sucesso/erro — risco de duplicidade de envio.
- **Prioridade**: 🔴 Alta (upload de foto) / 🟡 Média (demais).

### `ReviewSummaryTile` (componente compartilhado)
- **Problema encontrado**: deriva visual entre os 3 consumidores — `reviews_list_page` adiciona `trailing` de curtidas, `feed_page` não passa nada, `public_profile_page` zera o padding — mesmo componente com 3 tratamentos diferentes sem justificativa aparente.
- **Prioridade**: 🟢 Baixa.

### Perfil / Editar Perfil / Alterar Foto / Configurações
- **Positivos**: `switch` exaustivo sobre `UserProfileStatus` dentro de `AppAnimatedSwitcher`, reaproveitando a mesma view para `Updating`/`UpdateSuccess` (evita flash de loading); prefill guardado por flag em Editar Perfil.
- **Melhorias**: Bio/Cidade/Estado sem `validator`/`maxLength` (limite só aparece após round-trip); sair da tela de Alterar Foto com imagem já escolhida não pede confirmação de descarte.
- **Problemas encontrados**:
  - `change_avatar_page.dart`: ao escolher uma imagem, a prévia usa `CircleAvatar`/`MemoryImage` cru em vez do componente compartilhado `ProfileAvatar` usado no restante da tela — única tela onde a prévia de avatar não usa o componente do Design System.
  - **`SettingsPage`: "Sair" dispara `signOut()` direto no `onTap`, sem confirmação** — logout acidental é fácil.
  - **`SettingsPage` nunca observa `authControllerProvider`** — `signOut()` pode falhar (`AuthLoading`→`AuthError`) sem nenhum spinner ou mensagem de erro, parecendo travamento do app.
- **Prioridade**: 🔴 Alta (Configurações) / 🟡 Média (Alterar Foto) / 🟢 Baixa (validação de campos).

### Perfil Público / Seguidores / Seguindo
- **Positivos**: melhor tela do app em termos de motion — múltiplos `AppAnimatedSwitcher` aninhados (perfil/botão seguir/reviews) com `ValueKey`s granulares; `EmptyState` contextual e `AppStaggeredListItem` em Seguidores/Seguindo.
- **Melhorias**: `FollowError` mostra texto no lugar do botão sem opção de tentar novamente; mensagem de erro genérica ao carregar perfil ignora o objeto de erro real; `ListTile` cru em Seguidores/Seguindo (não existe `AppListTile`, então não é trocável hoje).
- **Prioridade**: 🟡 Média.

### Comentários
- **Positivos**: bom uso de `AppDialog`/`AppTextField`/`AppIconButton` com tooltip, `ref.listen` centralizado para erros, `AppStaggeredListItem`.
- **Melhorias**: `PopupMenuButton<String>` sem tooltip/label.
- **Problema encontrado**: `_ReportDialog` fecha antes da resposta de rede (ver seção Reviews acima) — sem feedback próprio, risco de denúncia duplicada.
- **Prioridade**: 🟡 Média.

### Favoritos
- **Positivos**: filtros de busca/cidade/ordenação bem agrupados em um único `AppCard`.
- **Problemas encontrados**:
  - `DropdownButton<FavoriteSortBy>` cru do Material, sem rótulo visível ("Ordenar por") nem `Semantics`.
  - **`FavoritesController.refresh()`/estado `FavoritesSyncing` existem (citando "tempo real" no comentário) mas nunca são chamados pela tela** — sem pull-to-refresh, funcionalidade pronta e não conectada.
  - `loadNextPage()` também não é usado — mesma lacuna de paginação das demais listas.
  - `EmptyState` sem `icon`/`action`.
- **Prioridade**: 🔴 Alta (sync/refresh não conectado) / 🟡 Média (demais).

### Feed
- **Positivos**: `AppAnimatedSwitcher`/`AppStaggeredListItem` corretos, `RefreshIndicator` nativo (único lugar do app com pull-to-refresh hoje).
- **Melhoria**: erro em texto plano sem retry (padrão repetido em quase todo o app).
- **Prioridade**: 🟢 Baixa.

### Rankings (restaurantes) / Ranking de Usuários
- **Positivos** (rankings de restaurantes): usa `RankingCard`, componente real do Design System.
- **Problemas encontrados**:
  - `rankings_page.dart`: `EdgeInsets.all(16)`/`SizedBox(height: 12)` hardcoded em vez de `AppSpacing.lg`/`AppSpacing.md`; `loadNextPage()` não chamado; sem pull-to-refresh; `EmptyState` sem `icon`/`action`.
  - **`ranking_users_page.dart`: maior gap de consistência de motion do app** — não usa `AppAnimatedSwitcher` nem `AppStaggeredListItem`, diferente de toda tela irmã; `SegmentedButton` com padding hardcoded (`16` em vez de token).
- **Prioridade**: 🟡 Média.

### Gamificação (Perfil)
- **Positivos**: excelente uso de UI-08 — `AppAnimatedFraction` na barra de XP, `AppPulseIcon` em badges conquistados, `AppAnimatedSwitcher`; matemática de XP para o próximo nível clara.
- **Melhoria**: lista de badges usa `ListTile` dentro de `ListView` simples (não `.builder`), sem `AppStaggeredListItem` — única inconsistência de motion nesta tela, por lo demais exemplar.
- **Prioridade**: 🟢 Baixa.

### Notificações (Central / Detalhe / Preferências)
- **Positivos**: indicador de não-lida, `AppAnimatedSwitcher`+`AppStaggeredListItem` corretos, tooltips corretos.
- **Melhoria**: distinção lida/não-lida é só visual (ponto+negrito), sem `Semantics` para leitor de tela.
- **Problema encontrado**: `_navigateToTarget` só trata 3 tipos de notificação (`new_follower`/`new_comment`/`new_like`) — para qualquer outro tipo ou payload nulo, o botão "Ver" continua visível/habilitado mas não faz nada ao ser tocado.
- **Prioridade**: 🟡 Média.

### Administração (6 telas + `admin_guard.dart`)
- **Positivos**: `AdminGuard` limpo/correto; as 6 telas compartilham um esqueleto previsível (load+guard+topbar+switch+lista).
- **Problemas encontrados** (baixa prioridade por decisão de produto já tomada de investir menos visualmente em admin): `admin_roles_page.dart` usa `DropdownButton<String>` cru (sem equivalente no DS); nenhuma das 6 usa `AppAnimatedSwitcher`/`AppStaggeredListItem` (esperado); espaçamento hardcoded (`16`/`24`) nas 6 telas; forte duplicação estrutural entre as 6 (candidato a um `AdminListScaffold` genérico).
- **Prioridade**: 🟢 Baixa (por decisão de produto já registrada).

### Achado transversal de todos os fluxos
Praticamente toda tela usa `Center(child: Text(message))` como estado de erro, sem nenhuma ação de retry — repetido em Perfil, Perfil Público, Seguidores, Feed, Restaurantes, Reviews e outros. Não existe um componente `ErrorState` no Design System (só existe `EmptyState`). É o padrão mais repetido entre todos os fluxos auditados.

---

## 4. Problemas Encontrados — Transversais (Design System, Motion, Performance, Código)

### 4.1 Design System

| Achado | Impacto | Esforço | Risco | Prioridade |
|---|---|---|---|---|
| Componentes com **zero uso**: `SkeletonLoader`, `ConfirmationDialog`, `AppBottomSheet`, `AppChip`, `AppFab`, `RestaurantCard`, `ReviewCard`, `AppSecondaryButton`, `AppBottomNavigation` | Médio (código morto na biblioteca; `AppBottomNavigation` revela ausência de navegação por abas) | — | Baixo | 🟡 Média |
| `ConfirmationDialog` existe especificamente para exclusão, mas `review_detail_page.dart` chama `_delete()` direto no `onPressed`, sem confirmação — exatamente o cenário para o qual o componente foi criado | Médio (exclusão acidental de conteúdo do usuário) | Baixo | Médio (quebra teste de integração de exclusão existente) | 🟡 Média |
| 23 ocorrências de `EdgeInsets`/`SizedBox` com literais crus (não tokenizados), concentradas em `administration/` (~16) e mais 7 em telas de feature (`ranking_users_page.dart`, `rankings_page.dart`, `login_page.dart`, `favorites_page.dart`, `notifications_page.dart`, `restaurants_search_page.dart`, `reviews_list_page.dart`) | Baixo (valores já batem com a escala `AppSpacing`, é só sintaxe) | Baixo | Baixo | 🟢 Baixa |
| Único uso de cor cru: `login_page.dart:69` (`Colors.white`) | Baixo | Baixo | Baixo | 🟢 Baixa |
| `DropdownButton` cru do Material em 2 lugares (`favorites_page.dart`, `admin_roles_page.dart`) — sem componente equivalente no DS | Baixo-Médio (falta rótulo/Semantics) | Médio (criar `AppDropdown`) | Baixo | 🟡 Média |
| Nenhum componente `ErrorState`/`AppListTile`/`AppSegmentedButton` existe — 3 lacunas de cobertura da biblioteca reveladas pelo uso repetido do padrão cru equivalente | Médio (o `ErrorState` sozinho resolveria o achado mais repetido do app) | Médio | Baixo | 🔴 Alta (ErrorState) / 🟢 Baixa (demais) |

### 4.2 Motion Design

| Achado | Impacto | Esforço | Risco | Prioridade |
|---|---|---|---|---|
| `change_avatar_page.dart` e `ranking_users_page.dart` sem `AppAnimatedSwitcher`/`AppStaggeredListItem`, únicas exceções não documentadas fora do escopo original da UI-08 | Baixo-Médio (inconsistência perceptível ao alternar entre telas irmãs) | Baixo (mesmo padrão já usado em 14 outras telas) | Baixo | 🟡 Média |
| Transição de página (`CustomTransitionPage` fade) existe só na rota `/` (Splash); as ~30 rotas restantes usam o corte seco default do GoRouter/plataforma | Médio (quebra a "promessa de motion" fora do momento de bootstrap) | Médio (helper central de transição, toca `app_router.dart` uma vez) | Baixo | 🟡 Média |
| Loop animado do `BorahSplashLoader` não respeita `disableAnimations` (asset WebP nativo, fora do gate de `AppMotion.scaled`) | Baixo (gap de acessibilidade honesto, documentado como escolha de marca) | Médio (exigiria trocar o mecanismo de asset) | Baixo | 🟢 Baixa |
| Documentação dos 4 componentes de motion ainda diz "não conectado a nenhuma tela" apesar de estarem em uso em 14-15 telas | Baixo (só desatualização de comentário) | Trivial | Nenhum | 🟢 Baixa |
| `app_animated_fraction.dart` e `app_pulse_icon.dart` sem `RepaintBoundary` (diferente de `app_staggered_list_item.dart`, que já tem) | Baixo (uso pontual/raro) | Baixo | Baixo | 🟢 Baixa |

### 4.3 Performance

| Achado | Impacto | Esforço | Risco | Prioridade |
|---|---|---|---|---|
| `profile_avatar.dart`: `Future` criado inline dentro do `build()` — cada rebuild do pai dispara nova URL assinada de Storage, mesmo sem mudança de `avatarPath`; usado em listas (perfil público, comentários) | Alto (rede repetida sem necessidade, em telas de lista) | Baixo (extrair para `initState`/memoização) | Baixo | 🔴 Alta |
| `public_profile_page.dart`'s `Column` com `.map().toList()` dentro de `SingleChildScrollView` renderiza todas as reviews de uma vez, mesmo fora da tela — ao contrário de favoritos/busca/feed, que já usam `.builder` | Médio (cresce com o tempo, diferente da lista de badges que é naturalmente pequena) | Baixo (trocar por `ListView.builder`) | Baixo | 🟡 Média |
| `public_profile_provider.dart`: `FutureProvider.family` sem `.autoDispose` — cada `userId` visitado deixa uma instância de provider em cache para sempre | Médio (cresce com o uso, app social) | Baixo (adicionar `.autoDispose`) | Baixo | 🟡 Média |
| `assets/icons/borah_location.png` (fonte 1024×1024) renderizado via `Image.asset` sem `cacheWidth`/`cacheHeight` em 3 arquivos, exibido a 14-18px — decodifica ~4MB antes de reduzir | Médio (mesmo fix resolve os 3 lugares) | Trivial (`cacheWidth: 36`) | Nenhum | 🟡 Média |
| `review_detail_page.dart`'s tira de fotos via `Image.network` sem `cacheWidth`/`cacheHeight`, exibida a 96×96 | Baixo-Médio | Trivial | Nenhum | 🟢 Baixa |
| `restaurant_detail_page.dart` observa 2 providers no mesmo `build()`, reconstruindo o Scaffold inteiro ao favoritar | Baixo (widget leve) | Baixo | Baixo | 🟢 Baixa |
| `user_avatar.dart`'s `CircleAvatar(backgroundImage: NetworkImage(...))` sem controle de tamanho de decodificação | Baixo-Médio | Médio (exigiria `ResizeImage`) | Baixo | 🟢 Baixa |

### 4.4 Código, Arquitetura e Testes

| Achado | Impacto | Esforço | Risco | Prioridade |
|---|---|---|---|---|
| `lib/core/errors/failure.dart` e `lib/core/logger/app_logger.dart` — definidos, nunca referenciados em nenhum outro arquivo | Baixo (código morto) | Trivial (remover ou conectar) | Baixo | 🟢 Baixa |
| Barris de feature (`lib/features/*/*.dart`) fazem apenas `export` e nunca são importados — todo o app importa arquivos individuais direto | Baixo (manutenção morta) | Trivial | Nenhum | 🟢 Baixa |
| Duplicação de formulário entre `create_review_page.dart`/`edit_review_page.dart` (~40 linhas repetidas) | Médio (custo de manutenção — qualquer mudança de campo precisa ser replicada) | Médio (extrair `ReviewFormScaffold`) | Baixo | 🟡 Média |
| Duplicação de `ListTile`/card de busca entre `restaurants_search_page.dart` e `favorites_page.dart` | Médio | Médio (extrair `RestaurantListTile`/`RestaurantSearchFilterCard`) | Baixo | 🟡 Média |
| 6 páginas de admin com esqueleto quase idêntico (guard+topbar+busca+switch+lista) | Médio (boilerplate) | Médio-Alto (extrair `AdminListScaffold`) | Baixo | 🟢 Baixa (área já com decisão de baixo investimento) |
| **23 de 33 páginas sem teste de widget** (todas as 6 de admin, 3 de authentication, 2 de gamificação, todas as 3 de notifications, rankings, create_restaurant, 2 de reviews, 3 de social, 2 de users) | Alto (cobertura desigual, risco de regressão silenciosa) | Alto (23 arquivos de teste) | Nenhum (só adição) | 🟡 Média |
| **Zero cobertura de integration test** para administration, gamification, rankings, notifications | Alto (fluxos completos sem rede de segurança end-to-end) | Alto | Nenhum | 🟡 Média |
| 2 controllers sem teste unitário: `public_profile_provider.dart`, `user_reviews_controller.dart` | Médio | Baixo | Nenhum | 🟡 Média |
| **Padrão de teste frágil sistemático**: `find.byType(TextFormField).at(N)` usado em praticamente todos os testes de widget para localizar campos por posição em vez de `Key`/label — qualquer reordenação de campo quebra o teste errado, silenciosamente | Médio (fragilidade de toda a suíte, não um único teste) | Médio (adicionar `Key`s e trocar por `find.byKey`) | Baixo | 🟡 Média |
| Nenhum golden test existe (`test/golden/` vazio, sem dependência `golden_toolkit`) | Baixo (visual validado manualmente a cada rodada até aqui) | Alto (setup de infraestrutura golden) | Baixo | 🟢 Baixa |

---

## 5. Quick Wins (baixo esforço / alto impacto)

Itens que podem ser resolvidos rapidamente e isoladamente, com risco baixo e ganho perceptível:

1. **Conectar `FavoritesController.refresh()`/`FavoritesSyncing` ao gesto de pull-to-refresh em `favorites_page.dart`** — lógica e estado já prontos, só falta o `RefreshIndicator`. Impacto: Alto. Esforço: Baixo. Risco: Baixo.
2. **Trocar `Colors.white` por `colorScheme.onPrimary` em `login_page.dart:69`** — único ponto fora do padrão de cor tokenizada. Impacto: Baixo. Esforço: Trivial. Risco: Nenhum.
3. **Adicionar confirmação (`ConfirmationDialog`, já existe e não é usado) ao "Sair" em `settings_page.dart`** — evita logout acidental. Impacto: Médio-Alto. Esforço: Baixo. Risco: Baixo (nenhum teste cobre esse fluxo hoje).
4. **Fazer `SettingsPage` observar `authControllerProvider`** para mostrar spinner/erro durante `signOut()` — falha silenciosa vira feedback visível. Impacto: Alto. Esforço: Baixo. Risco: Baixo.
5. **`cacheWidth: 36` em `Image.asset('assets/icons/borah_location.png', ...)`** nos 3 arquivos que a usam — resolve decodificação de 1024×1024 desnecessária com uma linha repetida 3x. Impacto: Médio. Esforço: Trivial. Risco: Nenhum.
6. **Extrair o `Future` inline de `profile_avatar.dart` para fora do `build()`** (memoizar por `avatarPath`) — elimina refetch de URL assinada a cada rebuild em listas de avatares. Impacto: Alto. Esforço: Baixo. Risco: Baixo.
7. **Adicionar `.autoDispose` em `public_profile_provider.dart`**. Impacto: Médio. Esforço: Trivial. Risco: Baixo.
8. **Trocar `Column(...map().toList())` por `ListView.builder` em `public_profile_page.dart` (lista de reviews)**. Impacto: Médio. Esforço: Baixo. Risco: Baixo.
9. **Atualizar os comentários de doc dos 4 componentes de Motion Design** ("ainda não conectado" → refletir uso real). Impacto: Baixo. Esforço: Trivial. Risco: Nenhum.
10. **Aplicar `AppAnimatedSwitcher`/`AppStaggeredListItem` em `change_avatar_page.dart` e `ranking_users_page.dart`** — mesmo padrão já usado em 14 outras telas, só replicar. Impacto: Médio. Esforço: Baixo. Risco: Baixo.
11. **Tokenizar os `EdgeInsets`/`SizedBox` hardcoded em `rankings_page.dart`** (`16`→`AppSpacing.lg`, `12`→`AppSpacing.md`). Impacto: Baixo. Esforço: Trivial. Risco: Nenhum.

---

## 6. Melhorias Arquiteturais

1. **Criar componente `ErrorState`** (análogo a `EmptyState`, com `icon`/`message`/`action` de retry) e substituir o padrão repetido `Center(child: Text(message))` em ~15 telas. Maior alavancagem de esforço único vs. número de telas beneficiadas em toda a auditoria.
2. **Conectar a paginação já construída** (`loadNextPage()` em favorites/rankings/reviews; criar o método em restaurants) às telas correspondentes, com indicador de "carregando mais" ao fim da lista.
3. **Extrair `AdminListScaffold` genérico** (guard + topbar + busca opcional + switch de estado + lista) para as 6 páginas de administração — reduz duplicação estrutural significativa, mesmo mantendo a decisão de baixo investimento visual em admin.
4. **Extrair `ReviewFormScaffold`** compartilhado entre `create_review_page.dart`/`edit_review_page.dart`.
5. **Padronizar `ReviewSummaryTile`** entre os 3 consumidores (reviews_list, feed, public_profile) — decidir um padding/trailing únicos ou documentar a intenção da diferença.
6. **Adicionar transição de página consistente** (`CustomTransitionPage` central, reaproveitando `AppMotion`) a todas as rotas, não só à Splash.
7. **Adicionar `resendVerificationEmail` ao `AuthController`** e um botão de reenvio na tela de verificação de e-mail — fecha o único dead-end real de autenticação encontrado.

---

## 7. Melhorias Futuras (fora do escopo imediato)

- Implementar navegação por abas real (Home hoje é um placeholder documentado; `AppBottomNavigation` já existe no Design System e nunca foi conectado).
- Conectar `AppBottomSheet` a um fluxo real (candidato natural: filtros de busca de restaurantes ou ações rápidas de reviews) — mudança de UX, não só de motion.
- Avaliar `SkeletonLoader` como substituto do `LoadingScreen` cheio de tela em pontos de alta frequência (ex. troca de foto de capa/perfil, upload de foto de review) — resolveria a fricção reportada como Alta em Reviews sem exigir redesenho do fluxo.
- Investir em campo de nota com estrelas/slider em vez de texto livre nas telas de Review.
- Avaliar consolidar `RestaurantCard`/`ReviewCard` (hoje com 0 uso) — ou removê-los se a decisão de manter `ListTile` for definitiva, documentando a razão.
- Cobrir accessibility (Semantics) de forma mais sistemática: indicador de notificação lida/não-lida, asset de loading do Splash, ícones de ação sem tooltip pontuais (ex. `PopupMenuButton` de Comentários).
- Investir em infraestrutura de golden test formal (dependência + pasta `test/golden/` hoje vazia) caso o volume de regressões visuais justifique o custo de setup.

---

## 8. Priorização

### 🔴 Alta prioridade
| Item | Categoria | Esforço | Risco |
|---|---|---|---|
| Upload de foto em Reviews substitui tela inteira por spinner | UX/Motion (Reviews) | Médio | Baixo |
| `SettingsPage` sem confirmação de logout e sem observar erro de `signOut()` | UX (Perfil/Configurações) | Baixo | Baixo |
| Sem opção de reenvio de e-mail de verificação (dead-end de conta) | UX (Autenticação) | Baixo-Médio | Baixo |
| `FavoritesController.refresh()`/sync em tempo real não conectado | UX/Produto (Favoritos) | Baixo | Baixo |
| `profile_avatar.dart` refetch de URL assinada a cada rebuild | Performance | Baixo | Baixo |
| Criar componente `ErrorState` para eliminar o padrão de erro sem retry | Design System | Médio | Baixo |

### 🟡 Média prioridade
| Item | Categoria |
|---|---|
| Paginação órfã em restaurants/rankings/reviews (além de favoritos, já em Alta) | UX/Produto |
| Duplicação de formulário em create/edit review | Código |
| Duplicação de ListTile/busca entre restaurants_search e favorites | Código |
| `ranking_users_page.dart` sem Motion Design (`AppAnimatedSwitcher`/stagger) | Motion |
| Transição de página só na Splash | Motion |
| `ConfirmationDialog` não conectado à exclusão de review/comentário | Design System |
| `DropdownButton` cru em favoritos/admin sem rótulo/Semantics | Design System/Acessibilidade |
| 23 páginas sem teste de widget; zero integration test em admin/gamificação/rankings/notificações | Testes |
| Padrão de teste frágil (`find.byType(...).at(N)`) | Testes |
| `_ReportDialog` fecha antes da resposta de rede (Comentários/Reviews) | UX |
| `public_profile_page.dart`: lista de reviews sem `.builder`; provider sem `.autoDispose` | Performance |
| Cadastro sem confirmação de senha | UX (Autenticação) |
| `change_avatar_page.dart` bypassa `ProfileAvatar` na prévia | Design System |
| Ícone de localização (1024×1024) decodificado sem `cacheWidth` em 3 telas | Performance |
| Notificação com tipo desconhecido: botão "Ver" fica habilitado sem ação | UX (Notificações) |

### 🟢 Baixa prioridade
| Item | Categoria |
|---|---|
| Componentes com zero uso na biblioteca (`SkeletonLoader`, `AppChip`, `AppFab`, etc.) | Design System |
| Espaçamento hardcoded não-tokenizado (23 ocorrências, majoritariamente em admin) | Design System |
| Loop do Splash não respeita `disableAnimations` | Acessibilidade/Motion |
| Documentação desatualizada dos componentes de Motion Design | Código |
| `RepaintBoundary` ausente em `AppAnimatedFraction`/`AppPulseIcon` | Performance |
| Código morto (`failure.dart`, `app_logger.dart`, barris de feature não importados) | Código |
| Duplicação estrutural das 6 páginas de admin | Código (decisão de produto já aceita) |
| Deriva visual do `ReviewSummaryTile` entre 3 consumidores | Design System |
| Ausência de golden tests formais | Testes |
| Demais melhorias cosméticas por fluxo (ver seção 3) | UX |

---

## Observação metodológica

Um dos 8 agentes de auditoria dedicados a aspectos transversais não retornou um relatório de texto distinto ao final da coleta; seus achados relevantes de acessibilidade aparecem de forma espalhada dentro das demais seções (ex.: `Semantics` ausente em indicadores de notificação lida/não-lida, ausência de `Semantics` no asset de loading da Splash, gap de `disableAnimations` no loop do mascote, rótulos ausentes em `DropdownButton`). Acessibilidade não teve, portanto, uma seção isolada nesta versão do documento — está integrada a cada fluxo e à seção 4. Isso não indica ausência de problemas de acessibilidade, apenas que a cobertura veio embutida nos demais recortes em vez de isolada.
