# RC-03 — FASE 4: Design Gap

**Status:** Draft para aprovação do usuário — análise pura, nenhum código/schema/arquivo de produto foi alterado.
**Data:** 2026-08-04
**Objetivo desta fase:** não é só listar diferenças — é responder "**como o BORAH deve ser quando a RC-03 terminar?**", definindo a visão final de design que orienta todas as fases seguintes (Feature Gap, Roadmap, Implementação).
**Baseline (restrições oficiais de projeto, conforme confirmado pelo usuário):** [`RC03_PRODUCT_AUDIT.md`](RC03_PRODUCT_AUDIT.md) (pivô de produto, motores genéricos subutilizados), [`RC03_UX_AUDIT.md`](RC03_UX_AUDIT.md) (fluxos, automação, matriz de eliminação/reutilização), [`RC03_UI_AUDIT.md`](RC03_UI_AUDIT.md) (classificação de 44 telas — 20 ✓ / 21 △ / 5 ✗ —, dívida visual, `gamification_profile_page` como referência de qualidade, cluster Administração como maior dívida).

---

## 1. Comparação tela a tela

**Critério de profundidade**: telas classificadas como "Nenhuma alteração" ou "Refinamento" (já ✓/△ com gaps pequenos e isolados, `RC03_UI_AUDIT.md §4`) recebem tratamento tabular compacto — repetir prosa longa sobre o que já está praticamente pronto não eleva a qualidade do documento. Telas classificadas como "Redesign parcial" ou "Redesign completo" recebem tratamento expandido, porque é exatamente aí que a "visão final" precisa ser descrita em detalhe.

### 1.1 Nenhuma alteração (13 telas — já expressam o padrão final)

| Tela | Objetivo | Componentes envolvidos | Impacto de tocar | Prioridade |
|---|---|---|---|---|
| `splash_page.dart` | Transição de marca no boot | `BorahSplashLoader` (reutilizado) | — | — |
| `signup_page.dart` | Cadastro rápido | `AppTopBar`, `AppTextField`×2, `AppPasswordField`, `AppPrimaryButton` (todos reutilizados) | — | — |
| `new_password_page.dart` | Definir nova senha | mesmos componentes de formulário padrão (reutilizados) | — | — |
| `create_restaurant_page.dart` | Cadastrar restaurante | `SectionHeader`, `AppTextField`×6 (reutilizados) | — | — |
| `create_review_page.dart`/`edit_review_page.dart` | Avaliar/editar restaurante | formulário padrão (reutilizado) | — | — |
| `notification_detail_page.dart` | Ver detalhe e agir sobre uma notificação | `AppTopBar`, `AppOutlinedButton` (reutilizados) | — | — |
| `notification_preferences_page.dart` | Controlar categorias de notificação | `AppAnimatedSwitcher`, `LoadingScreen`, `ErrorState` (reutilizados) | — | — (ver §6 para a expansão de categoria, que é mudança de conteúdo, não de visual) |
| `create_group_page.dart`/`edit_group_page.dart`/`join_group_page.dart` | Criar/editar/entrar em grupo | formulário padrão (reutilizado) | — | — |
| `home_shell_page.dart` | Navegação principal | `AppBottomNavigation` (reutilizado) | — | — |
| `app_theme.dart` | Fundação de tema | tokens (reutilizados) | — | — |

### 1.2 Refinamento (17 telas — ajuste pontual, sem redesenho)

| Tela | Problema encontrado | Como deveria ficar | Componentes | Impacto | Prioridade |
|---|---|---|---|---|---|
| `login_page.dart` | `SizedBox(48)` sem token de tamanho de logo | Usar token de tamanho de ícone/logo (§3) | Reutilizado: `AppGradients`. Novo: token de tamanho | Baixo | P3 |
| `password_reset_page.dart` | Ícone com `size:48` sem token | Mesmo token de tamanho acima | Reutilizado: `AppAnimatedSwitcher`. Novo: token de tamanho | Baixo | P3 |
| `email_verification_page.dart` | Sem `AppTopBar`/seta de voltar | Adicionar `AppTopBar` com voltar; hoje só existe saída por texto | Reutilizado: `AppTopBar` | Médio (é affordance de navegação, não só estética) | P2 |
| `restaurant_detail_page.dart` | Ícone de localização com tamanho hardcoded | Token de tamanho de ícone | Novo: token de tamanho | Baixo | P3 |
| `review_detail_page.dart` | Tira de fotos com dimensão hardcoded (96px) | Token de tamanho de imagem (novo, ver §3) | Novo: token de tamanho de imagem | Baixo | P3 |
| `restaurants_search_page.dart` | `ListTile` cru em vez de `RestaurantCard` (já existe) | Trocar por `RestaurantCard` | Reutilizado: `RestaurantCard` | Médio-alto (visual mais rico, sem trabalho de construção) | **P1** |
| `favorites_page.dart` | Mesmo gap acima | Trocar por `RestaurantCard` | Reutilizado: `RestaurantCard` | Médio-alto | **P1** |
| `reviews_list_page.dart`/`feed_page.dart` | Consomem `review_summary_tile.dart` (sem DS, ver §1.3) | Resolvido corrigindo o widget compartilhado, não a tela | Reutilizado: `ScoreBubble` (via correção do widget) | Alto (2 telas de uma vez) | **P1** |
| `rankings_page.dart`/`ranking_users_page.dart`/`group_ranking_page.dart` | `EdgeInsets`/`SizedBox` hardcoded, 2 delas sem `AppAnimatedSwitcher` | Importar `AppSpacing`; envolver estados em `AppAnimatedSwitcher` | Reutilizado: `AppSpacing`, `AppAnimatedSwitcher` | Baixo | P2 |
| `notifications_page.dart` | Indicador de não-lida com `Container` 10×10 cru | Manter como está por ora (uso único não justifica componente novo) ou usar `AppSpacing.xs` como base da medida | Nenhum novo necessário | Baixo | P3 |
| `comments_page.dart`/`group_detail_page.dart` | `PopupMenuButton` sem `tooltip` explícito | Adicionar `tooltip` | Nenhum novo necessário | Baixo (acessibilidade) | P2 |
| `follow_list_page.dart` | `ListTile` cru (sem componente equivalente a criar — lista de pessoas é genuinamente simples) | Manter `ListTile`, mas padronizar com `ProfileAvatar` (já usa) | — | Baixo | P3 |
| `event_detail_page.dart` | Subseção de avaliações usa `Text` cru para erro/vazio | Trocar por `ErrorState`/`EmptyState` (versão compacta/inline) | Reutilizado: `ErrorState`/`EmptyState` | Médio | P2 |
| `create_event_page.dart` | Estado de busca vazia é `Center(Text)` cru | Trocar por `EmptyState` | Reutilizado: `EmptyState` | Médio | P2 |
| `edit_profile_page.dart` | Sem afordance de trocar avatar na própria tela | Adicionar avatar tocável no topo (ver §1.3, fusão com `change_avatar_page`) | Reutilizado: `ProfileAvatar` | Alto (elimina uma tela inteira) | **P1** |
| `submit_event_review_page.dart` | Visualmente correta; o gap real é de produto/UX (campos numéricos vs. estrelas), não de design system | Nenhuma mudança visual isolada — tratar junto com decisão de produto (Feature Gap, FASE 5) | — | — | — |

### 1.3 Redesign parcial (7 iniciativas, 8 arquivos — a "visão final" começa a aparecer aqui)

#### `groups_list_page.dart`
- **Tela atual:** `ListTile` cru por grupo — nome, sem foto de destaque, sem prévia de atividade.
- **Objetivo da tela:** ser a Home do app (confirmado, é a aba 0 da navegação principal) — primeira coisa que o usuário vê a cada abertura.
- **Problemas encontrados:** sendo a Home, é a tela com menor densidade de identidade visual do app hoje — não usa nenhum card dedicado, não mostra nenhum sinal de "vida" do grupo (próximo rolê, ranking, atividade recente).
- **Como deveria ficar:** cada grupo como um `GroupCard` com foto/cor de destaque, nome, contagem de membros, e um sinal de atividade recente (próximo rolê agendado, ou "sem rolês ainda" como convite implícito à ação) — a Home deveria comunicar imediatamente "isto está vivo", não só listar nomes.
- **Componentes necessários:** `GroupCard` (novo).
- **Componentes reutilizados:** `AppAnimatedSwitcher`, `AppStaggeredListItem`, `EmptyState`/`ErrorState`, `AppTopBar` (toda a base de estado já está correta, só falta o card).
- **Componentes novos:** `GroupCard` — já especificado em `UI-06_COMPONENT_LIBRARY.md §6` (nome/integrantes/próximo evento/ranking), nunca construído.
- **Impacto:** altíssimo — é a Home do app.
- **Prioridade: P0.**

#### `events_list_page.dart`
- **Tela atual:** `ListTile` cru por rolê, com os cards de "Memórias" (`AppCard`) já bem resolvidos no topo.
- **Objetivo da tela:** mostrar o histórico e o próximo encontro do grupo de forma que dê vontade de participar.
- **Problemas encontrados:** os cards de Memórias já têm identidade forte; a lista de rolês abaixo deles é visualmente pobre por comparação — quebra de consistência dentro da própria tela.
- **Como deveria ficar:** `EventCard` com restaurante, data/hora, contagem de confirmados e status (agendado/realizado/cancelado) visualmente distinto — para equilibrar com a força visual das Memórias já existentes.
- **Componentes necessários:** `EventCard` (novo).
- **Componentes reutilizados:** `AppCard` (Memórias), `AppBadge` (status), `AppAnimatedSwitcher`, `AppStaggeredListItem`.
- **Componentes novos:** `EventCard` — também especificado em `UI-06 §6`, nunca construído.
- **Impacto:** alto — é a porta de entrada para o fluxo mais profundo do app (Criar rolê, `RC03_UX_AUDIT.md §2.4`).
- **Prioridade: P0.**

#### `group_detail_page.dart`
- **Tela atual:** nome/descrição/código de convite bem resolvidos; lista de membros em `ListTile` cru.
- **Objetivo da tela:** ser o hub do grupo — de onde tudo (rolês, ranking, convite) é alcançado.
- **Problemas encontrados:** a lista de membros não comunica hierarquia social (quem é dono/admin) com força visual — hoje é texto de papel ao lado do nome, não um elemento visual diferenciado.
- **Como deveria ficar:** linha de membro com indicador visual de papel (ex.: `AppBadge` pequeno "Dono"/"Admin" já usado em outros lugares do app, aplicado aqui de forma consistente) + `tooltip` explícito nos menus de ação.
- **Componentes necessários:** nenhum novo — é reuso de `AppBadge` (já existe, já usado em outras telas) aplicado de forma mais consistente aqui.
- **Componentes reutilizados:** `AppBadge`, `ConfirmationDialog`, `AppAnimatedSwitcher` (já corretos).
- **Componentes novos:** nenhum.
- **Impacto:** médio.
- **Prioridade: P1.**

#### Unificação `group_ranking_page.dart` + `group_stats_page.dart` → **"Meu Grupo"**
- **Tela atual:** 2 telas separadas, atrás de um menu overflow sem rótulo (achado do `RC03_UX_AUDIT.md §2.8`, já confirmado como Oportunidade Estratégica #3 no UX Audit).
- **Objetivo:** ser o "momento WOW" do produto (nomeação do próprio `BORAH_BETA_PLAYBOOK.md §7`) — ranking, estatísticas e memórias do grupo em um único lugar, com destaque visual proporcional à sua importância emocional.
- **Problemas encontrados:** fragmentação (2 telas + navegação escondida) esvazia exatamente o momento que deveria ser o mais celebrado do app; nenhuma das 2 telas hoje usa gradiente ou qualquer elemento "herói" — tratam dados de conquista coletiva com o mesmo tom visual neutro de uma tela de formulário.
- **Como deveria ficar:** uma única tela "Meu Grupo", acessível por botão primário visível (não menu), com abas Ranking/Estatísticas/Memórias — e, diferente de hoje, com tratamento visual de destaque (o mesmo nível de energia que `gamification_profile_page.dart` já aplica à barra de XP: gradiente, motion, `AppBadge` para posições de destaque) porque este é, junto com a Gamificação, o momento que mais precisa transmitir "conquista", não só "informação".
- **Componentes necessários:** um componente de abas (`Tabs`, listado em `UI-06 §5` mas nunca construído no DS atual).
- **Componentes reutilizados:** `RankingCard`, `AppCard`, `AppGradients` (aplicado aqui pela primeira vez fora de Login/Gamificação).
- **Componentes novos:** componente de Tabs (novo, mas é wrapper fino sobre `TabBar`/`TabBarView` nativo do Material, baixo custo).
- **Impacto:** altíssimo — resolve simultaneamente um problema de UX (descoberta) e de identidade (o "momento WOW" hoje não parece um momento WOW).
- **Prioridade: P0.**

#### `gamification_profile_page.dart`
- **Tela atual:** já é a referência de qualidade do app (`RC03_UI_AUDIT.md §4`) — gradiente, `AppAnimatedFraction`, `AppPulseIcon`, `AppBadge`.
- **Objetivo:** comunicar evolução pessoal de forma celebratória.
- **Problemas encontrados:** **não é um problema visual, é um problema de conteúdo** — a tela está pronta para mostrar XP ganho em Grupos/Rolês, mas hoje esse XP nunca é gerado (achado do Product/UX Audit, Oportunidade Estratégica #1). O redesign "parcial" aqui não é trocar componente, é **adicionar uma seção** ("XP ganho em rolês recentes") que hoje não existe porque não há dado para mostrar.
- **Como deveria ficar:** manter a base visual atual (é a referência, não deve mudar) e adicionar uma seção de origem do XP — visualmente no mesmo padrão (gradiente/motion) já estabelecido — assim que a Oportunidade #1 (motor de gamificação conectado a Grupos/Rolês) for implementada.
- **Componentes necessários:** nenhum novo — reuso do próprio padrão já estabelecido nesta tela.
- **Componentes reutilizados:** `AppGradients`, `AppAnimatedFraction`, `AppBadge`, `AppPulseIcon`.
- **Componentes novos:** nenhum.
- **Impacto:** alto, mas **bloqueado por decisão de produto** (depende da FASE 5/6, não é uma tarefa de design isolada).
- **Prioridade: P1 (condicional à Oportunidade #1 do UX Audit).**

#### `public_profile_page.dart`
- **Tela atual:** bloco de identidade bem agrupado (`AppCard`), mas erro do perfil e erro/vazio das avaliações usam `Text` cru, contornando `ErrorState`/`EmptyState` por completo (`RC03_UI_AUDIT.md §4`, classificada ✗).
- **Objetivo:** ser o cartão de visita público de um usuário — motivar a seguir, ver avaliações, sentir a "presença" da pessoa no BORAH.
- **Problemas encontrados:** o padrão de estado quebrado é o problema principal; secundariamente, o bloco de identidade poderia comunicar mais (nível/badges resumidos, não só nome/bio) já que a Gamificação existe e tem esse dado pronto.
- **Como deveria ficar:** corrigir os 2 pontos de estado cru para `ErrorState`/`EmptyState`; considerar adicionar um resumo compacto de nível/badge no bloco de identidade (reuso direto de dado já existente em `GamificationProfileController`, sem trabalho de backend novo).
- **Componentes necessários:** nenhum novo.
- **Componentes reutilizados:** `ErrorState`, `EmptyState`, `AppBadge` (para o resumo de gamificação, se adotado).
- **Componentes novos:** nenhum.
- **Impacto:** médio-alto (tela pública, alta visibilidade social).
- **Prioridade: P1.**

### 1.4 Redesign completo (4 iniciativas, 11 arquivos)

#### `settings_page.dart`
- **Tela atual:** 100% `ListTile` cru, 4 itens (Editar perfil, Enviar feedback, Sair, Excluir conta), sem nenhuma camada de componente.
- **Objetivo:** dar controle claro sobre conta e sessão, com hierarquia visual clara entre ações neutras e destrutivas.
- **Problemas encontrados:** é a tela mais "não migrada" da auditoria fora do cluster Administração — nenhum componente do design system estrutura o conteúdo; ações destrutivas ("Sair"/"Excluir conta") têm o mesmo peso visual que ações neutras.
- **Como deveria ficar:** lista estruturada com agrupamento visual (ex.: seção "Conta" separada de "Sessão"), ações destrutivas com tratamento visual distinto (cor `error`, já definida no `ColorScheme`, hoje não aplicada aqui), ícones consistentes com o resto do app.
- **Componentes necessários:** nenhum novo — é 100% aplicação do que já existe (`AppCard`/`SectionHeader` para agrupar, cor `error` do tema para ações destrutivas).
- **Componentes reutilizados:** `AppCard`, `SectionHeader`, `ConfirmationDialog` (já usado para excluir conta).
- **Componentes novos:** nenhum.
- **Impacto:** alto — tela de alto tráfego, todo usuário passa por ela.
- **Prioridade: P0.**

#### `change_avatar_page.dart` → **eliminada, fundida em `edit_profile_page.dart`**
- **Tela atual:** tela própria, com preview via `CircleAvatar` cru (bypassa `UserAvatar`/`ProfileAvatar`).
- **Objetivo:** trocar a foto de perfil.
- **Problemas encontrados:** é uma tarefa mental única ("editar meu perfil") fragmentada em navegação sem motivo técnico — já identificado como Oportunidade Estratégica #9 do `RC03_UX_AUDIT.md`.
- **Como deveria ficar:** avatar tocável no topo de `edit_profile_page.dart`, abrindo o seletor de imagem inline, sem navegação para uma tela nova — **elimina uma tela inteira do app**, exatamente o tipo de simplificação que a §6 desta fase pede.
- **Componentes necessários:** nenhum novo.
- **Componentes reutilizados:** `ProfileAvatar` (a lógica de preview local precisa de um pequeno ajuste para aceitar `MemoryImage`, ou o preview continua sendo tratado como uma exceção documentada, mas dentro da mesma tela).
- **Componentes novos:** nenhum.
- **Impacto:** alto — elimina uma tela, não só melhora uma.
- **Prioridade: P0.**

#### `profile_page.dart`
- **Tela atual:** avatar/nome/localização/bio bem resolvidos; bloco de atalhos (Gamificação/Rankings/Notificações) em `Card`+`ListTile` cru — o próprio código admite ser o mesmo padrão problemático de `settings_page.dart`.
- **Objetivo:** ser o espelho do usuário no app — identidade pessoal + progresso + atalhos.
- **Problemas encontrados:** o bloco de atalhos trata "Gamificação" (que leva à tela mais bonita do app) com um `ListTile` neutro — desconexão entre a importância do destino e a apresentação do link.
- **Como deveria ficar:** atalhos como pequenos cards com prévia de dado (ex.: "Nível 3 · 340 XP" no atalho de Gamificação, não só o texto "Gamificação") — motiva o toque porque já mostra valor antes de navegar, e resolve o gap visual junto.
- **Componentes necessários:** nenhum novo — reuso de `AppCard` com conteúdo mais rico.
- **Componentes reutilizados:** `AppCard`, `ProfileAvatar`.
- **Componentes novos:** nenhum.
- **Impacto:** alto — segunda tela mais visitada do app depois da Home.
- **Prioridade: P0.**

#### Administração completa (`admin_dashboard_page`, `admin_users_page`, `admin_restaurants_page`, `admin_roles_page`, `moderation_page`, `audit_log_page`, `admin_guard`)
- **Tela atual:** cluster inteiro consistentemente atrás do resto do app — 2 telas ✗ (sem nenhum token de espaçamento), o resto △, nenhuma com `AppAnimatedSwitcher`, dívida **conscientemente assumida** em `UI-07_APPLY_DESIGN_SYSTEM.md §9.4` ("ferramenta interna, prioridade baixa") e nunca resgatada.
- **Objetivo:** ferramenta interna eficiente para moderação/administração — não precisa do mesmo nível de "encantamento" do produto consumidor, mas precisa de consistência estrutural mínima (tokens, estados) para não acumular bugs visuais silenciosos.
- **Problemas encontrados:** ver `RC03_UI_AUDIT.md §6` (dívida visual) — hardcoded em 7 arquivos, `ListTile` cru generalizado, sem `AppAnimatedSwitcher`, sem UI distinta para estados de "salvando"/"processando" (3 telas colapsam esse estado com "carregado", risco real de o usuário achar que uma ação não foi registrada).
- **Como deveria ficar:** aplicar exatamente o mesmo padrão já maduro no resto do app — `AppSpacing` em vez de números crus, `AppAnimatedSwitcher` envolvendo os estados, UI de "salvando" visível (reaproveitando o padrão já usado nos formulários do produto consumidor: `AppPrimaryButton.isLoading`). **Não precisa de nenhum componente novo, nem de tratamento "de marca" (gradiente/motion celebratório)** — é ferramenta interna, o objetivo é consistência e confiabilidade, não emoção.
- **Componentes necessários:** nenhum novo.
- **Componentes reutilizados:** `AppSpacing`, `AppAnimatedSwitcher`, `AppPrimaryButton.isLoading` (padrão já usado em todo formulário do produto consumidor).
- **Componentes novos:** nenhum.
- **Impacto:** médio (público interno, mas 7 telas de uma vez, e risco real de confusão operacional no estado "salvando" ausente).
- **Prioridade: P2** (menor que P0/P1 porque não é público-facing, mas deve ser tratado como bloco único, não pontualmente).

---

## 2. Comparação com a Identidade da Marca

**Achado central desta seção**: comparando as 44 telas com o Manual da Marca, a Biblioteca Visual Oficial e os achados do UX Audit, a resposta honesta é: **a maioria das telas está "corretamente dentro da paleta" mas não "visivelmente BORAH"**. Nenhuma tela usa cor fora do `ColorScheme` (confirmado, `RC03_UI_AUDIT.md §4`), então tecnicamente todas "respeitam a marca" no sentido mínimo — mas a Biblioteca Visual Oficial (`identidade visual-borah/`) é rica em elementos de personalidade (gradientes, medalhas, expressões do símbolo, selos de conquista, stickers) que hoje aparecem em **exatamente 2 das 44 telas** (`login_page.dart`, `gamification_profile_page.dart`, ambas usando `AppGradients`). O app hoje é, na maior parte, "Material Design corretamente retextured com cores BORAH" — funcionalmente correto, mas sem a energia "social, espontânea, divertida sem ser infantil" que o próprio `CLAUDE.md` do pacote de identidade visual define como personalidade da marca (`rc03_design_inventory.md §2.2`).

| Grupo de telas | Transmite identidade BORAH? | Por quê / o que falta |
|---|---|---|
| `login_page.dart`, `gamification_profile_page.dart` | **Sim** | Únicas 2 telas com gradiente de marca aplicado; `gamification_profile_page` também usa motion celebratório (`AppAnimatedFraction`/`AppPulseIcon`) — são o padrão-ouro. |
| Formulários de criação/edição (Grupos, Rolês, Restaurantes, Reviews — ~14 telas) | **Parcialmente** | Cor/tipografia corretas, mas visualmente indistinguíveis de qualquer app Material genérico — nenhum elemento de personalidade (nenhuma ilustração, nenhum tom de voz na UX writing além do texto funcional). Esperado para formulários (não deveriam ter gradiente), mas o "tom de voz" do Manual da Marca (`"Fale como alguém do grupo, não como uma plataforma"`) não aparece em nenhuma mensagem de erro/sucesso auditada — todas são funcionais/neutras ("Não foi possível carregar", não "Ops, algo travou aqui"). |
| Listas (`groups_list_page`, `events_list_page`, `restaurants_search_page`, `favorites_page`) | **Parcialmente, tendendo a Não** | `ListTile` cru é o elemento Material mais genérico que existe — nenhuma das 4 listas centrais do produto (Grupos, Rolês, Restaurantes, Favoritos) usa um card com identidade própria. É exatamente o padrão que o `RC03_UI_AUDIT.md` já sinalizou como dívida — a correção proposta em §1.3 (`GroupCard`/`EventCard`) resolve isso diretamente. |
| "Momento WOW" (Ranking do Grupo, Estatísticas, Memórias) | **Não** | Tratado com o mesmo tom neutro de uma tela de formulário, apesar de ser — por definição do próprio Beta Playbook — o momento mais emocional do produto. Nenhuma medalha/selo da Biblioteca Visual Oficial (existem SVGs prontos de medalhas 1º/2º/3º lugar, `assets/borah/ui/ranking/`, confirmados no inventário de Design) é usada fora de `RankingCard`'s ícones internos. |
| Administração (7 telas) | **Não se aplica** | Correto e esperado — ferramenta interna não precisa (nem deveria, por convenção de produto) carregar a mesma personalidade de marca do produto consumidor. |
| Estados vazios/erro (`EmptyState`/`ErrorState`, ~20 usos) | **Parcialmente** | Já usam ilustração da Biblioteca Visual Oficial (`symbol_smiling.svg`/`symbol_surprised.svg`, confirmado no `rc03_design_inventory.md`), o que é um ponto forte real — mas o texto que acompanha é sempre funcional/neutro, nunca no tom "alguém do grupo" do Manual da Marca. |

**Conclusão da comparação**: a identidade BORAH está presente na **fundação** (cores, tipografia, ilustrações de estado vazio/erro) mas ausente na **expressão** (gradientes, motion celebratório, tom de voz, cards com personalidade nas listas centrais). A visão final da RC-03 precisa fechar essa lacuna de expressão, não de fundação — a fundação já está correta.

---

## 3. Design System Final — decisão oficial

| Categoria | Decisão |
|---|---|
| **Componentes que permanecem, sem alteração** | `AppTopBar`, `AppPrimaryButton`/`AppOutlinedButton`/`AppTextButton`/`AppIconButton`, `AppTextField`/`AppSearchField`/`AppPasswordField`, `AppCard`, `RankingCard`, `ScoreBubble`, `EmptyState`/`ErrorState`/`LoadingScreen`/`LoadingIndicator`/`BorahSplashLoader`, `AppBadge`, `AppDialog`/`ConfirmationDialog`, `UserAvatar`, `SectionHeader`, `AppAnimatedSwitcher`/`AppAnimatedFraction`/`AppStaggeredListItem`/`AppPulseIcon`, `AppBottomNavigation`, `AppMotion`, todos os tokens (`AppColors`, `AppSpacing`, `AppRadius`, `AppElevation`, `AppTypography`, `AppGradients`/`BrandGradients`). |
| **Componentes que precisam ser criados** | `GroupCard` (nome/foto/integrantes/próximo rolê — já especificado em `UI-06 §6`), `EventCard` (restaurante/data/hora/participantes/status — já especificado em `UI-06 §6`), componente de Tabs (para a tela unificada "Meu Grupo", §1.3). |
| **Componentes que devem ser removidos** | Nenhum adicional — a limpeza já correta (`AppFab`, `AppSecondaryButton`, `AppChip`, `AppBottomSheet`, `SkeletonLoader`, `ReviewCard`, `AppShadows`, removidos em `4d856b7`) permanece válida; não recriar nenhum deles sem necessidade concreta nova. |
| **Componentes que precisam ser unificados** | `ProfileAvatar` + `CircleAvatar` cru (`change_avatar_page.dart`) → um único caminho de avatar que aceite tanto URL assinada quanto preview local (`MemoryImage`), eliminando a exceção. `review_summary_tile.dart` deve adotar `ScoreBubble` em vez de `Text` cru para a nota — não é um componente novo, é destravar o uso de um que já existe no widget de maior reuso do app. |
| **O que deve virar Design Token** | Tamanho de ícone (`AppIconSize.xs/sm/md/lg/xl` — valores já definidos em `UI-05_ICONOGRAPHY.md §6`, nunca implementados como `const`); tamanho de imagem/thumbnail (novo token, cobre os casos hoje hardcoded em `review_detail_page.dart` e outros: tira de fotos, avatar de preview). |
| **O que deve virar widget global** | O bloco de "atalho com prévia de dado" proposto para `profile_page.dart` (§1.4) — se funcionar bem lá, é candidato natural a um componente `AppShortcutCard` reutilizável em qualquer tela que precise de "link com prévia", não só o Perfil. |

---

## 4. Redesign necessário — resumo por tela

| Nível | Telas | Contagem |
|---|---|---|
| **Nenhuma alteração** | `splash_page`, `signup_page`, `new_password_page`, `create_restaurant_page`, `create_review_page`, `edit_review_page`, `notification_detail_page`, `notification_preferences_page`, `create_group_page`, `edit_group_page`, `join_group_page`, `home_shell_page`, `app_theme.dart` | 13 |
| **Refinamento** | `login_page`, `password_reset_page`, `email_verification_page`, `restaurant_detail_page`, `review_detail_page`, `restaurants_search_page`, `favorites_page`, `reviews_list_page`, `feed_page`, `rankings_page`, `ranking_users_page`, `group_ranking_page`(tokens — independente da fusão em §1.3), `notifications_page`, `comments_page`, `follow_list_page`, `event_detail_page`, `create_event_page`, `edit_profile_page`, `submit_event_review_page` | 19 |
| **Redesign parcial** | `groups_list_page`, `events_list_page`, `group_detail_page`, [`group_ranking_page`+`group_stats_page` → "Meu Grupo"], `gamification_profile_page`, `public_profile_page` | 6 iniciativas / 7 arquivos |
| **Redesign completo** | `settings_page`, `change_avatar_page` (eliminada), `profile_page`, Administração (7 arquivos) | 4 iniciativas / 10 arquivos |

Cada item acima está justificado em detalhe no §1. Nenhuma tela recebeu classificação sem justificativa correspondente.

---

## 5. Experiência Visual — o usuário percebe?

| Dimensão | O usuário percebe claramente hoje? | Onde funciona | Onde falha e como corrigir |
|---|---|---|---|
| **Progresso** | Parcialmente | `gamification_profile_page.dart` comunica progresso muito bem (barra de XP animada, nível). | Fora da Gamificação, progresso é invisível — criar um rolê, confirmar presença, avaliar coletivamente não geram nenhum sinal visual de progresso (raiz: não geram XP, achado do Product/UX Audit). **Correção**: depende da Oportunidade #1 (motor de gamificação conectado a Grupos/Rolês) — uma vez que o dado exista, a UI para mostrá-lo já está pronta (mesmo padrão de `gamification_profile_page`). |
| **Recompensa** | Parcialmente | Badges (`AppBadge`) e notificação de level-up já existem e funcionam para avaliações de restaurante/curtidas/comentários. | Avaliar um rolê coletivamente não gera nenhuma recompensa visível (mesma raiz acima). **Correção**: mesma dependência da Oportunidade #1. |
| **Pertencimento ao grupo** | Não, hoje é fraco | `group_detail_page.dart` mostra membros, mas sem nenhuma linguagem visual de "time"/"clube". | Nenhuma tela comunica "isto é o SEU grupo" de forma emocional — sem foto de capa de grupo com destaque, sem cor/identidade por grupo. **Correção**: `GroupCard` (§1.3/§3) deveria incluir um elemento visual de identidade do grupo (foto grande, ou cor de destaque escolhida/derivada), não só texto. |
| **Descoberta de restaurantes** | Fraco | Busca funcional (`restaurants_search_page.dart`), mas sem nenhum elemento de "descoberta" — é busca, não exploração. | Nenhuma tela sugere "restaurantes que seu grupo ainda não visitou" ou "favoritos do grupo" (dado já mapeado como reuso possível no `RC03_UX_AUDIT.md §8`, Ação "Favoritar"). **Correção**: depende de trabalho de produto (exibir essa sugestão) mais do que de design puro — quando existir, o padrão visual de `RestaurantCard` já cobre a exibição. |
| **Competição saudável** | Parcialmente | `RankingCard`/`AppBadge` comunicam posição de forma clara e não-punitiva (medalhas, não "última colocação" em destaque negativo). | O Ranking do Grupo está escondido (menu overflow, achado do UX Audit) — não há como sentir competição em algo que não se vê. **Correção**: resolvido diretamente pela unificação "Meu Grupo" (§1.3), tornando o ranking visível e proeminente. |
| **Memória dos rolês** | Fraco | Cards de "Memórias" em `events_list_page.dart` já existem e têm identidade visual boa (`AppCard`), mas cobrem só 2 métricas ("mais visitado"/"campeão") de um conjunto maior prometido (gap já confirmado no Product Audit). | **Correção**: parte é decisão de produto (quais métricas adicionar, FASE 5), parte é design (a tela "Meu Grupo" unificada dá mais espaço para memórias ricas do que os 2 cards atuais permitem). |
| **Evolução pessoal** | Sim, bem resolvido | `gamification_profile_page.dart` é o melhor exemplo do app — nível, XP, badges, tudo com motion e gradiente. | Nenhuma correção necessária nesta dimensão isoladamente — só precisa se espalhar (ver Progresso/Recompensa acima). |

**Padrão que emerge**: as duas dimensões mais bem resolvidas (Progresso pessoal, Evolução pessoal) são exatamente as que já têm uma tela "herói" dedicada (`gamification_profile_page.dart`). As dimensões mais fracas (Pertencimento, Competição, Memória) são as que não têm — e a correção proposta em §1.3 (tela unificada "Meu Grupo" com o mesmo padrão visual de identidade forte) é desenhada precisamente para replicar, no nível de grupo, o que já funciona no nível pessoal.

---

## 6. Design orientado ao produto

Esta seção traduz, para decisões de design, as oportunidades já identificadas no `RC03_UX_AUDIT.md` (Matriz de Eliminação §9, Matriz de Automação §8) — o design não deveria construir "mais telas bonitas", deveria construir **menos telas, mais informativas**.

- **Reduzir telas**: `change_avatar_page.dart` eliminada (fundida em `edit_profile_page.dart`, §1.4); `group_ranking_page.dart`+`group_stats_page.dart` unificadas em "Meu Grupo" (§1.3) — de 44 telas auditadas, a visão final tem **42**, não 44+novas, mesmo com 2 componentes novos sendo criados.
- **Reduzir formulários**: fora do escopo desta fase de design pura (depende de Google Places, FASE 5/6), mas o design já deve prever o formulário de cadastro de restaurante como "confirmação de dados pré-preenchidos" em vez de "preenchimento do zero", uma vez que a integração exista.
- **Reduzir cliques**: `GroupCard`/`EventCard` com prévia de dado (próximo rolê, contagem de confirmados) reduzem a necessidade de entrar em cada item só para saber "o que tem lá dentro" — informação visível na lista já responde a pergunta mais comum sem navegação.
- **Reduzir decisões do usuário**: o atalho de Perfil com prévia de dado (§1.4) e o "Meu Grupo" unificado (§1.3) reduzem a decisão "qual desses 3 lugares eu deveria olhar" para "há só 1 lugar".
- **Aumentar automação**: o design não gera automação sozinho (é trabalho de trigger/backend, FASE 5), mas **prepara a superfície visual para quando ela existir** — a seção "XP ganho em rolês" de `gamification_profile_page.dart` (§1.3) é exatamente isso: a tela já está pronta, só espera o dado.
- **Aumentar reaproveitamento**: `GroupCard`/`EventCard` não são só para as listas principais — `EventCard` pode ser reutilizado dentro de "Meu Grupo" (aba Memórias), e `GroupCard` pode ser reutilizado em qualquer lugar que hoje mostra "grupo" de forma resumida (nenhum encontrado na auditoria atual, mas é a razão de construir como componente, não como widget local de uma tela só).

---

## 7. Matriz de Priorização

Cobre as iniciativas de "Redesign parcial"/"Redesign completo" (§1.3/§1.4) mais os refinamentos de maior impacto (§1.2) — os refinamentos triviais (tokens de espaçamento/ícone) não justificam uma linha própria nesta matriz, seu custo e risco são uniformemente baixos.

| Iniciativa | Valor usuário | Valor produto | Complexidade | Esforço | Dependências | Prioridade | Risco |
|---|---|---|---|---|---|---|---|
| `settings_page.dart` (redesign completo) | Médio | Médio | Baixa | Curto | Nenhuma | **P0** | Baixo |
| `change_avatar_page` → fundir em `edit_profile_page` | Médio | Baixo | Baixa | Curto | Nenhuma | **P0** | Baixo (elimina uma tela, não deveria quebrar nada) |
| `profile_page.dart` (atalhos com prévia) | Alto | Médio | Baixa-média | Curto-médio | Dados de Gamificação/Rankings já existem | **P0** | Baixo |
| `groups_list_page.dart` (`GroupCard`) | Alto | Alto | Média | Médio | Construir `GroupCard` primeiro | **P0** | Baixo-médio (é a Home, testar bem) |
| `events_list_page.dart` (`EventCard`) | Alto | Alto | Média | Médio | Construir `EventCard` primeiro | **P0** | Baixo-médio |
| "Meu Grupo" (unificação Ranking+Estatísticas+Memórias) | Alto | Altíssimo | Média-alta | Médio | Componente de Tabs (novo, baixo custo) | **P0** | Médio (mexe em navegação/rotas existentes) |
| `RestaurantCard` em `restaurants_search_page`/`favorites_page` | Médio-alto | Médio | Baixa | Curto | Nenhuma — componente já existe | **P1** | Baixo |
| `review_summary_tile.dart` (adotar `ScoreBubble`) | Médio | Médio | Baixa | Curto | Nenhuma | **P1** | Baixo (mas toca 3 telas — testar as 3) |
| `public_profile_page.dart` (corrigir estados crus) | Médio | Médio | Baixa | Curto | Nenhuma | **P1** | Baixo |
| `group_detail_page.dart` (papel visual dos membros) | Médio | Baixo-médio | Baixa | Curto | Nenhuma | **P1** | Baixo |
| `gamification_profile_page.dart` (seção "XP de rolês") | Alto | Alto | Baixa (visual) | Curto (visual) | **Bloqueado pela Oportunidade #1 do UX Audit (dado de XP em Grupos/Rolês precisa existir primeiro)** | P1, condicional | Baixo |
| Administração (7 telas, bloco único) | Baixo (interno) | Médio (confiabilidade operacional) | Baixa | Médio (7 arquivos, mas mecânico) | Nenhuma | **P2** | Baixo |

---

## 8. BORAH 2.0 — Visão Final

Quando a RC-03 estiver implementada, a experiência do BORAH deixa de ser "um conjunto de telas funcionalmente corretas" e passa a ser um produto que **mostra, a cada ação, que o grupo está vivo**.

**Descoberta de restaurantes** deixa de ser uma busca isolada e passa a ser guiada pelo histórico do próprio grupo: ao abrir a busca ou ao criar um rolê, o BORAH sugere lugares que o grupo já favoritou ou ainda não visitou, com dados ricos (foto, categoria, localização exata) vindos de uma fonte confiável — não mais um formulário em branco para preencher do zero.

**Criar um grupo** continua simples, mas o convite deixa de depender de copiar e colar um código: um link único leva direto à tela de entrada, e o grupo recém-criado aparece na Home (`groups_list_page.dart`) como um `GroupCard` com identidade própria — foto, cor, contagem de membros — não uma linha de texto entre outras.

**Organizar um rolê** parte de um atalho direto do grupo, com sugestão de restaurante e data baseada no histórico (quando o grupo já tem rolês anteriores) — reduzindo o fluxo hoje mais longo do app. Confirmar presença continua com a mesma fricção mínima de hoje (já é quase ideal), e ao ser realizado, o rolê passa a notificar automaticamente cada participante confirmado que a avaliação está liberada — fechando um loop que hoje depende inteiramente da memória do usuário.

**Compartilhar momentos** — avaliar um rolê coletivamente deixa de ser uma ação silenciosa: gera XP, pode desbloquear badge, atualiza o Ranking do Grupo e as Estatísticas em tempo real, e notifica o resto do grupo que uma nova avaliação chegou. O que hoje é uma ação isolada (registrar 5 números) passa a ser, visualmente e emocionalmente, parte de uma cadeia de reações — exatamente o padrão "uma ação, muitas consequências" que a FASE 2 (UX Audit) definiu como o principal objetivo de produto da RC-03.

**Crescer no ranking** deixa de exigir que o usuário abra um menu escondido para descobrir que existe: "Meu Grupo" — a tela unificada de Ranking, Estatísticas e Memórias — é alcançável por um botão visível a partir do grupo, com o mesmo tratamento visual celebratório (gradiente, motion, medalhas da Biblioteca Visual Oficial) que hoje só a tela de Gamificação pessoal tem. Ver a posição do grupo deixa de ser uma tarefa de descoberta e passa a ser um destino natural.

**Evoluir na gamificação** deixa de estar isolado das ações que o produto realmente pede que o usuário faça. Hoje, um usuário pode organizar dezenas de rolês, confirmar presença religiosamente e nunca subir de nível — depois da RC-03, cada participação real no grupo alimenta o mesmo motor de XP que já recompensa avaliações de restaurante, com a mesma tela "herói" (`gamification_profile_page.dart`) mostrando de onde cada ponto veio.

**Construir memórias** deixa de significar 2 cards fixos ("mais visitado", "campeão") e passa a ser um espaço mais rico dentro de "Meu Grupo" — com espaço visual para crescer conforme mais métricas (quem mais participou, quem mais escolheu bem) forem decididas e implementadas nas próximas fases, sem precisar de mais uma tela nova para cada métrica adicional.

**O aplicativo incentiva o retorno** não por obrigação, mas por reconhecimento: uma notificação avisa quando uma avaliação pode ser feita; o ranking do grupo muda e fica visível o suficiente para dar vontade de conferir; o perfil mostra, de relance, o nível e XP sem precisar entrar em uma tela separada; e cada tela de destino desses convites — Gamificação, "Meu Grupo" — já está, desde a FASE 3/4 desta auditoria, pronta para parecer exatamente o que o BORAH promete ser: **não uma plataforma, mas alguém do grupo, comemorando com você.**

---

**Aguardando revisão do usuário antes de prosseguir para `RC03_FEATURE_GAP.md` (FASE 5).**
