# RC-03 — Plano de Implementação do BORAH 2.0

**Status:** Draft para aprovação do usuário — plano operacional, nenhum código/schema/arquivo de produto foi alterado.
**Data:** 2026-08-04
**Natureza deste documento:** é a ponte entre o [`RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md`](RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md) (o que construir) e o código (como construir) — deriva exclusivamente do PRD e das 5 auditorias já aprovadas ([`RC03_PRODUCT_AUDIT.md`](RC03_PRODUCT_AUDIT.md), [`RC03_UX_AUDIT.md`](RC03_UX_AUDIT.md), [`RC03_UI_AUDIT.md`](RC03_UI_AUDIT.md), [`RC03_DESIGN_GAP.md`](RC03_DESIGN_GAP.md), [`RC03_FEATURE_GAP.md`](RC03_FEATURE_GAP.md)). Nenhuma funcionalidade neste plano existe fora da lista oficial do PRD §4.
**Nota sobre nomenclatura de sprint**: o exemplo do usuário sugeriu rótulos `UI-01`...`UI-09`. Esses rótulos já são usados pela documentação existente (`docs/FASE 3 - UX_UI/UI-01` a `UI-08`, rodadas de design system já executadas e mescladas em `develop`). Reutilizá-los aqui criaria ambiguidade real entre "rodada de design já concluída" e "sprint futuro deste plano". Este documento usa **Sprint 0 a Sprint 9**, preservando o agrupamento de conteúdo sugerido pelo usuário, com uma trilha adicional (Sprint 0) justificada no §2.

---

## 1. Princípios da Implementação

Não são aspiracionais — são restrições já confirmadas e vigentes no projeto (memória do projeto + PRD §9), repetidas aqui porque nenhuma sprint deste plano pode violá-las:

- **Arquitetura congelada**: Feature-First + Clean Architecture (domain/data/application/presentation por módulo), decisão do usuário desde a aprovação da RC-02D. Nenhuma sprint deste plano cria uma nova camada ou reorganiza módulos existentes.
- **Não criar novas camadas sem justificativa**: toda funcionalidade nova (PRD §4) deve caber nas camadas já existentes de um módulo já existente, ou de um módulo novo que siga exatamente o mesmo padrão dos 13 já auditados (`rc03_flutter_inventory.md`).
- **Reutilização máxima**: antes de qualquer controller/provider/repository novo, checar `RC03_FEATURE_GAP.md §4` (Reutilização) — 9 das 15 funcionalidades Core/Muito importantes/Importantes já analisadas não exigem nenhuma tabela nova.
- **Componentes globais**: `GroupCard`/`EventCard`/Tabs (os únicos 3 componentes novos aprovados, `RC03_DESIGN_GAP.md §3`) devem nascer em `design_system/components/`, nunca como widget local de uma tela.
- **Design System único**: nenhuma sprint deste plano introduz uma segunda fonte de tokens de cor/espaçamento/tipografia — a fundação já existe e está correta (`RC03_UI_AUDIT.md §2`).
- **Zero duplicação**: aplicar diretamente as decisões já tomadas em `RC03_FEATURE_GAP.md §6` (Galeria+Álbum unificados, "Meu Grupo" cobre todos os pedidos de "novo ranking", Feed automático construído sobre `notifications`).
- **Feature-First**: cada funcionalidade nova entra dentro do módulo de feature correspondente (`groups`, `events`, `gamification`, etc.), nunca em um módulo transversal novo.
- **Riverpod**: todo estado novo segue o padrão `Notifier`/`NotifierProvider` já usado nos 34 controllers existentes — nenhuma sprint introduz um padrão de gerenciamento de estado alternativo.
- **Supabase**: toda automação de servidor (triggers, RPCs) segue o padrão já estabelecido de 35 funções `SECURITY DEFINER` — nenhuma sprint introduz uma segunda tecnologia de backend.
- **Clean Architecture**: toda funcionalidade nova respeita a direção de dependência já estabelecida (domain não depende de data/presentation; controllers dependem de repositories via interface).
- **SOLID**: aplicado como já é hoje — por exemplo, `RankingRepository` delega inteiramente a `RestaurantRepository.listRanked()` em vez de duplicar a query (`RC03_UX_AUDIT.md §10`) é o padrão de referência de Single Responsibility + reuso a seguir.

---

## 2. Dependências entre Sprints

```
Sprint 0 (Backend paralelo)                Sprint 1 (Design System)         Sprint 2 (Auth)
 XP automático (F29)                        GroupCard, EventCard,            Splash/Login/Cadastro
 Notificação avaliação liberada (F41)       Tabs, tokens de ícone/imagem,     (Login Google)
 Badges de grupo (F30)                      unificação de avatar,
 Preferências completas (F48)               fix de review_summary_tile
 Verificação do Feed (F24)                  (ScoreBubble)
      │                                            │                                │
      │ sem bloqueio — roda em paralelo            │                                │
      │ a qualquer sprint                          ├───────────┬───────────┬────────┴─────────┐
      │                                            ▼           ▼           ▼                  ▼
      │                                       Sprint 3     Sprint 4     Sprint 5          (S2 não
      │                                       Home/Feed/   Restaurantes/ Grupos/Rolês/     depende
      │                                       BottomNav    Places/Cards  GroupCard/        de S1)
      │                                       (usa           (RestaurantCard EventCard
      │                                       GroupCard)     já existe;    (usa EventCard;
      │                                                      tokens novos) Deep Link F35;
      │                                                                    Rodízio F36)
      │                                                          │              │
      │                                                          │              │
      │                    Sprint 7 (Avaliações/Categorias/Feed  │              │
      │                    Automático) — paralelo a S3-S6,       │              │
      │                    não depende de GroupCard/EventCard    │              │
      │                                                          │              │
      └──────────────────────────────────────┐                  │              │
                                               ▼                  ▼              ▼
                                          Sprint 8 (Ranking/Gamificação/Memórias)
                                          — precisa de Tabs (S1), do dado real de
                                          XP (S0) e do modelo de dado de Rolês
                                          estável (S5) — "Meu Grupo"
                                                          │
                    Sprint 6 (Perfil/Favoritos/Fotos) ────┤ (precisa da unificação
                    — precisa da unificação de avatar     │  de avatar de S1)
                    de S1                                 │
                                                          ▼
                                          Sprint 9 (Polimento/Animações/Performance)
                                          — deve vir por último: toca os mesmos
                                          arquivos de S3/S6/S8 (Administração,
                                          Configurações, Perfil Público) e depende
                                          de todas as áreas estarem funcionalmente
                                          estáveis antes de refinar
```

**O que obrigatoriamente precisa vir antes:**
- Sprint 1 precisa terminar antes de Sprint 3 (`GroupCard`), Sprint 5 (`EventCard`), Sprint 6 (unificação de avatar) e Sprint 8 (Tabs).
- Sprint 5 precisa estar substancialmente pronto antes de Sprint 8 (o "Meu Grupo" consome o mesmo modelo de dado de Rolês que Sprint 5 organiza visualmente).
- Sprint 0 precisa entregar F29 (XP automático) antes da parte de Sprint 8 que adiciona a seção "XP ganho em rolês" em `gamification_profile_page.dart` (`RC03_DESIGN_GAP.md §1.3`) — sem esse dado, a seção não tem o que mostrar.
- Sprint 9 precisa vir por último — qualquer polimento aplicado antes de S3-S8 estarem estáveis corre o risco de ser refeito.

**O que pode ser executado em paralelo:**
- Sprint 0, Sprint 1 e Sprint 2 podem começar simultaneamente no dia 1 — nenhum depende dos outros dois.
- Depois de Sprint 1 concluído, Sprint 3, Sprint 4, Sprint 5 e Sprint 6 podem rodar em paralelo entre si (tocam módulos de feature diferentes, sem arquivo compartilhado).
- Sprint 7 pode rodar em paralelo a Sprint 3-6 — não depende de `GroupCard`/`EventCard`/Tabs.
- Sprint 0 continua rodando em paralelo a tudo até entregar F29, que é o único ponto de sincronização real com Sprint 8.

---

## 3. Sprints

| Sprint | Nome | Conteúdo (agrupamento sugerido pelo usuário) |
|---|---|---|
| Sprint 0 | Trilha Backend Paralela | XP automático, notificação de avaliação liberada, badges de grupo, preferências completas, verificação **e correção** do Feed (responsabilidade exclusiva desta sprint) |
| Sprint 1 | Design System | `GroupCard`, `EventCard`, Tabs, tokens novos, unificação de avatar, fix de `review_summary_tile` |
| Sprint 2 | Splash, Login, Cadastro | Login com Google, refinamentos de tokens |
| Sprint 3 | Home, Feed, Bottom Navigation | `groups_list_page` com `GroupCard` (Feed já resolvido integralmente na Sprint 0) |
| Sprint 4 | Restaurantes, Google Places, Cards | Google Places, descoberta guiada por grupo, adoção de `RestaurantCard` |
| Sprint 5 | Grupos, Rolês, `GroupCard`, `EventCard` | `events_list_page` com `EventCard`, deep link de convite, rodízio/sorteio |
| Sprint 6 | Perfil, Favoritos, Fotos | Perfil redesenhado, fusão de troca de avatar, galeria unificada |
| Sprint 7 | Avaliações, Categorias, Feed Automático | Avaliação por categorias em `reviews`, feed automático de grupo |
| Sprint 8 | Ranking, Gamificação, Memórias | "Meu Grupo" unificado, memórias expandidas, seção de XP de rolês |
| Sprint 9 | Polimento, Animações, Performance | Cluster Administração, `settings_page`, `public_profile_page`, cobertura de `AppAnimatedSwitcher` |

---

## 4. Detalhamento por Sprint

### Sprint 0 — Trilha Backend Paralela

- **Objetivo**: fechar o motor social do cluster Grupos/Rolês (recomendação estratégica #1 do `RC03_FEATURE_GAP.md §12` — tratar F29+F30+F41 como uma única entrega coerente) e verificar/corrigir a suspeita de maior risco/menor custo de todo o plano (F24).
- **Funcionalidades**: F29 (XP automático), F41 (Notificação avaliação liberada), F30 (Badges de grupo), F48 (Preferências completas), F24 (Feed — **responsabilidade exclusiva desta sprint**: verificar a existência do ponto de entrada, corrigir se confirmado ausente, e validar o funcionamento; nenhuma outra sprint compartilha esta funcionalidade).
- **Arquivos impactados**: novas migrations em `supabase/migrations/`; `notification_preferences_page.dart` (1 `SwitchListTile` novo); e, se a verificação confirmar a ausência do ponto de entrada do Feed, o arquivo de tela onde esse ponto de entrada for adicionado (local a decidir nesta própria sprint, ex.: `profile_page.dart`) — nenhum outro arquivo Flutter novo além desses.
- **Widgets reutilizados**: nenhum novo necessário — `gamification_profile_page.dart` e `notifications_page.dart` já existem e já sabem exibir XP/badges/notificações, só passam a ter mais dado real para mostrar.
- **Novos widgets**: nenhum.
- **Controllers**: nenhum novo — `GamificationProfileController`/`NotificationsController`/`NotificationPreferencesController` já cobrem o consumo do novo dado.
- **Providers**: nenhum novo.
- **Banco/Storage/Supabase**: 2-3 migrations novas (trigger de XP em `event_attendances`/`event_reviews`, seguindo o padrão de `handle_gamification_new_review/comment/like`; trigger de notificação em `event_attendances`/`events`, seguindo o padrão de `notify_event_attendance_response`/`notify_new_event`; seed de novos badges em `badges` se F30 incluir badges inéditos). RLS: nenhuma nova (reusa policies já existentes de `event_attendances`/`event_reviews`/`notifications`).
- **APIs/RPCs**: nenhuma nova — reaproveita `award_gamification_points()`, `award_badge()`, `create_notification()` sem alteração de assinatura.
- **Testes**: testes de trigger via SQL direto (inserir uma confirmação de presença/avaliação coletiva e verificar `user_progress`/`notifications` atualizados); teste de navegação confirmando que o ponto de entrada do Feed leva à rota `/feed` corretamente; nenhum outro teste Flutter novo necessário além de confirmar que as telas existentes renderizam o novo dado sem quebrar (`flutter test` completo, sem alteração esperada nos testes já existentes).
- **Critérios de aceite**: confirmar presença em rolê gera XP visível em `gamification_profile_page`; avaliar coletivamente gera XP e notificação; preferência de notificação de Grupos aparece e funciona na UI; `/feed` tem (ou passou a ter, corrigido dentro desta mesma sprint) um ponto de entrada real, confirmado por teste de navegação — nenhuma outra sprint deste plano possui critério de aceite relacionado ao Feed.
- **Riscos**: técnico — duplicação acidental de XP se o mesmo usuário também avaliar o restaurante individualmente pelo mesmo rolê (mitigação: escopo do trigger é só `event_reviews`, não reaproveita a lógica de `reviews`, os 2 sistemas continuam contando XP independentemente, por design). Funcional — nenhum. Visual — nenhum (sem mudança de tela). Regressão — baixo, é aditivo.
- **Tempo estimado**: curto (dias, não semanas) — é o sprint de menor esforço e maior retorno de todo o plano.

### Sprint 1 — Design System

- **Objetivo**: construir os 3 componentes novos aprovados e fechar as 2 unificações identificadas no Design Gap, destravando todas as sprints de tela subsequentes.
- **Funcionalidades**: suporte a F46 (`GroupCard`, `EventCard`), suporte a F23 (componente de Tabs), unificação de avatar (`RC03_DESIGN_GAP.md §1.4`), fix de `review_summary_tile.dart` (adoção de `ScoreBubble`, `RC03_UI_AUDIT.md §6`), tokens de tamanho de ícone/imagem (`RC03_UI_AUDIT.md §3`).
- **Arquivos impactados**: `design_system/components/cards/group_card.dart` (novo), `design_system/components/cards/event_card.dart` (novo), `design_system/components/navigation/app_tabs.dart` (novo, wrapper fino sobre `TabBar`/`TabBarView`), `design_system/tokens/app_icon_size.dart` (novo), `design_system/tokens/app_image_size.dart` (novo), `design_system/components/avatars/user_avatar.dart` (estender para aceitar `MemoryImage`), `features/reviews/presentation/widgets/review_summary_tile.dart` (reescrever para importar design system).
- **Widgets reutilizados**: `AppCard`/`RankingCard`/`RestaurantCard` como referência de padrão de composição para `GroupCard`/`EventCard`.
- **Novos widgets**: `GroupCard`, `EventCard`, componente de Tabs.
- **Controllers/Providers/Banco/Storage/Supabase/APIs**: nenhum — este sprint é 100% Flutter/design system, sem alteração de backend.
- **Testes**: testes de widget novos para `GroupCard`/`EventCard`/Tabs (golden test ou widget test verificando renderização com dados de exemplo); atualizar os testes existentes que dependem de `review_summary_tile.dart` (feed/reviews/perfil público têm suítes que verificam texto de nota — coordenar com a mesma disciplina já usada nas rodadas UI-03/UI-03B, que preservou finders de teste ao trocar `Text` por `ScoreBubble` em outros pontos).
- **Critérios de aceite**: `GroupCard`/`EventCard`/Tabs existem, documentados, com pelo menos 1 uso de exemplo cada; `flutter analyze` limpo; `flutter test` sem regressão.
- **Riscos**: técnico — baixo (componentes novos e isolados). Funcional — nenhum (nada consome ainda). Visual — nenhum (sem tela alterada neste sprint). Regressão — **médio no fix de `review_summary_tile.dart`**, porque esse widget já é consumido por 3 telas em produção (Feed, Reviews, Perfil Público) — mitigação: seguir a mesma disciplina já documentada em `UI-07_APPLY_DESIGN_SYSTEM.md §5.1` (checar finders de teste antes de trocar o texto por `ScoreBubble`, ajustando os testes se necessário, nunca escondendo a regressão).
- **Tempo estimado**: médio (é a sprint de maior superfície de construção nova, mesmo sendo só design system).

### Sprint 2 — Splash, Login, Cadastro

- **Objetivo**: fechar o único item Muito importante que depende só da tela de autenticação (F02) e os refinamentos triviais já mapeados no Design Gap.
- **Funcionalidades**: F02 (Login com Google).
- **Arquivos impactados**: `features/authentication/presentation/pages/login_page.dart` (botão novo + tratamento de erro OAuth), `email_verification_page.dart` (adicionar `AppTopBar`, `RC03_DESIGN_GAP.md §1.2`).
- **Widgets reutilizados**: `AppPrimaryButton`/`AppOutlinedButton` (para o botão Google), `AppTopBar` (para `email_verification_page.dart`), `AuthController.signInWithGoogle()` (já existe, sem alteração).
- **Novos widgets**: nenhum.
- **Controllers/Providers**: nenhum novo — `AuthController` já expõe o método.
- **Banco/Storage/Supabase/APIs**: nenhum — o backend de login social já está pronto (`RC03_PRODUCT_AUDIT.md §2.1`).
- **Testes**: teste de widget para o novo botão (renderização + chamada do método correto ao tocar); atualizar teste de `email_verification_page.dart` se algum finder dependia da ausência de AppBar.
- **Critérios de aceite**: botão de Login com Google visível e funcional; `email_verification_page.dart` tem `AppTopBar` com voltar.
- **Riscos**: técnico — baixo. Funcional — médio (fluxo OAuth tem mais pontos de falha externos — conta cancelada, popup bloqueado — exige tratamento de erro cuidadoso). Visual — baixo. Regressão — baixo.
- **Tempo estimado**: curto.

### Sprint 3 — Home, Feed, Bottom Navigation

- **Objetivo**: dar identidade visual à Home. (A correção do ponto de entrada do Feed é responsabilidade exclusiva da Sprint 0, já resolvida antes desta sprint começar — ver §4, Sprint 0.)
- **Funcionalidades**: aplicação de `GroupCard` em `groups_list_page.dart` (parte de F46).
- **Arquivos impactados**: `features/groups/presentation/pages/groups_list_page.dart`.
- **Widgets reutilizados**: `AppAnimatedSwitcher`, `AppStaggeredListItem`, `EmptyState`/`ErrorState` (já corretos em `groups_list_page.dart`, só a troca do `ListTile` por `GroupCard`).
- **Novos widgets**: nenhum (consome `GroupCard` de Sprint 1).
- **Controllers/Providers**: nenhum novo — `GroupsListController` já expõe o dado necessário.
- **Banco/Storage/Supabase**: nenhum.
- **Testes**: atualizar testes de widget de `groups_list_page.dart` que dependiam de `ListTile` (finders).
- **Critérios de aceite**: Home mostra grupos como `GroupCard` (o critério de aceite relativo ao Feed pertence exclusivamente à Sprint 0, já cumprido antes desta sprint começar).
- **Riscos**: técnico — baixo. Funcional — baixo. Visual — médio (é a Home, mudança visível a cada abertura do app — validar em dispositivo real antes de finalizar). Regressão — médio (testes de `groups_list_page.dart` precisam ser atualizados, não só a tela).
- **Tempo estimado**: médio.

### Sprint 4 — Restaurantes, Google Places, Cards

- **Objetivo**: reduzir o maior gargalo de digitação do produto e destravar a descoberta guiada por grupo.
- **Funcionalidades**: F12 (Google Places), F13 (Descoberta guiada), adoção de `RestaurantCard` em `restaurants_search_page.dart`/`favorites_page.dart` (refinamento já mapeado no Design Gap §1.2).
- **Arquivos impactados**: `features/restaurants/presentation/pages/create_restaurant_page.dart` (autocomplete), `restaurants_search_page.dart`, `favorites_page.dart` (troca de `ListTile` por `RestaurantCard`), `create_event_page.dart` (seção de sugestão de restaurante).
- **Widgets reutilizados**: `RestaurantCard` (já existe, só passa a ser efetivamente usada).
- **Novos widgets**: componente de autocomplete (novo, especificamente para a integração Places — não estava na lista de componentes de design system do §3 do Design Gap porque depende de uma decisão técnica externa, tratado aqui como parte da funcionalidade F12, não como componente de design system genérico).
- **Controllers**: `RestaurantDetailController`/`RestaurantsController` estendidos para consumir o resultado do autocomplete; novo controller/serviço para a chamada à API do Places (padrão a decidir na implementação, mas deve seguir a mesma estrutura de repository já usada, ex.: `PlacesRepository` na camada `data/`).
- **Banco**: possível migration se novos campos (telefone/horário) forem adotados — decisão a confirmar antes de iniciar (`RC03_FEATURE_GAP.md §5.1`).
- **Storage/Supabase**: possível Edge Function como proxy da chamada ao Google Places, para não expor a chave de API no cliente (`RC03_FEATURE_GAP.md §7-8-9`).
- **APIs**: integração nova com Google Places API (dependência externa, requer conta Google Cloud + billing configurados pelo usuário antes do início deste sprint — não é uma tarefa de código, é um pré-requisito operacional).
- **Testes**: mock da API do Places para testes de widget/integração (nunca chamar a API real em teste automatizado); teste de fallback (cadastro manual continua funcionando se a API falhar ou não retornar resultado).
- **Critérios de aceite**: autocomplete funcional no cadastro de restaurante; fallback manual preservado; sugestão de restaurante visível ao criar rolê.
- **Riscos**: técnico — médio-alto (dependência externa paga, rate limit, chave de API). Funcional — médio (o que fazer se a API não retornar resultado precisa de UX definida, não só tratamento de erro genérico). Visual — baixo. Regressão — baixo (é aditivo, cadastro manual não é removido). **Mitigação principal**: seguir a recomendação estratégica do `RC03_FEATURE_GAP.md §12` item 4 — restringir a primeira entrega a cadastro de restaurante novo, não retroalimentar restaurantes já cadastrados manualmente.
- **Tempo estimado**: longo (é o sprint com a única dependência externa paga de todo o plano).

### Sprint 5 — Grupos, Rolês, `GroupCard`, `EventCard`

- **Objetivo**: dar identidade visual aos Rolês, eliminar a fricção de convite manual, e endereçar a fricção social de "quem sempre escolhe".
- **Funcionalidades**: aplicação de `EventCard` em `events_list_page.dart` (parte de F46), F35 (Deep link de convite), F36 (Rodízio/sorteio).
- **Arquivos impactados**: `features/events/presentation/pages/events_list_page.dart`, `features/groups/presentation/pages/join_group_page.dart` (nova rota de entrada via deep link), `core/router/app_router.dart` (nova rota/handler de deep link), configuração nativa Android (`AndroidManifest.xml`, `assetlinks.json`)/iOS (`Info.plist`, associated domains) para App Links/Universal Links, `create_event_page.dart` (seção de sugestão de rodízio).
- **Widgets reutilizados**: `EventCard` (de Sprint 1), `JoinGroupPage`/`join_group_by_invite_code()` (já prontos, só ganham uma segunda porta de entrada).
- **Novos widgets**: nenhum além do `EventCard` já construído em Sprint 1.
- **Controllers**: `GroupDetailController`/`CreateEventController` estendidos para expor sugestão de rodízio.
- **Banco**: 1 migration pequena para F36 (coluna de rastreamento de "última escolha" em `groups`/`group_members`, decisão de regra de negócio a confirmar antes de iniciar, `RC03_FEATURE_GAP.md §5.8`); nenhuma para F35 (deep link é infraestrutura de plataforma, não schema).
- **RLS**: nenhuma nova.
- **Testes**: teste de deep link (abrir o app via link simulado e verificar navegação correta até a tela de confirmação de entrada); teste de widget para `EventCard`; teste de sugestão de rodízio (dado simulado de grupo, verificar sugestão correta).
- **Critérios de aceite**: rolês exibidos como `EventCard`; link de convite abre o app direto na tela de confirmação; sugestão de rodízio aparece como sugestão, nunca bloqueia a criação manual.
- **Riscos**: técnico — médio (configuração de App Links/Universal Links é sensível a erro de configuração de domínio, historicamente uma das partes mais frágeis de integrar em apps Flutter). Funcional — baixo. Visual — baixo. Regressão — baixo. **Mitigação**: testar o deep link em build de release (não só debug) antes de considerar o sprint concluído — comportamento de App Links/Universal Links pode diferir entre os dois.
- **Tempo estimado**: médio-longo (a parte de deep link tem complexidade de configuração de plataforma, não só de código Dart).

### Sprint 6 — Perfil, Favoritos, Fotos

- **Objetivo**: elevar o Perfil a um hub de valor e eliminar uma tela inteira do app.
- **Funcionalidades**: F09 (Perfil redesenhado), fusão de `change_avatar_page.dart` em `edit_profile_page.dart`, F14+F39 (Galeria unificada).
- **Arquivos impactados**: `features/users/presentation/pages/profile_page.dart` (atalhos com prévia), `edit_profile_page.dart` (avatar tocável), `change_avatar_page.dart` (**removido**), `core/router/app_router.dart` (remover a rota `/profile/avatar`), `restaurant_detail_page.dart`/`event_detail_page.dart` (grid de galeria), `event_reviews` (extensão de schema para suportar foto).
- **Widgets reutilizados**: `AppCard` (atalhos com prévia), `ProfileAvatar`/`UserAvatar` unificado (de Sprint 1).
- **Novos widgets**: componente de grid de galeria (novo, mas de baixo custo — reaproveita o padrão de tira de fotos já usado em `review_detail_page.dart`).
- **Controllers**: `UserProfileController` (sem alteração de contrato, só de UI consumidora); novo método em `EventReviewRepository`/`SubmitEventReviewController` para upload de foto (seguindo exatamente o padrão de `ReviewDetailController.addPhoto()`).
- **Banco**: migration para adicionar suporte a foto em `event_reviews` (nova tabela de fotos ou coluna, decisão de schema a confirmar — recomendo seguir o mesmo padrão relacional já usado para fotos de `reviews`, não inventar um modelo novo).
- **Storage**: extensão de bucket/policy — reaproveitar o bucket `review-photos` já existente com um novo prefixo de path, ou criar um bucket dedicado (`event-review-photos`) seguindo exatamente o padrão de RLS já usado nos 3 buckets existentes (`RC03_FEATURE_GAP.md §7-8-9`).
- **RLS**: nova policy de storage para o escopo de avaliação coletiva, no mesmo padrão das 11 policies já existentes de `storage.objects`.
- **Testes**: atualizar testes de rota (remoção de `/profile/avatar`); teste de upload de foto em avaliação coletiva; teste de galeria (grid renderiza fotos de origem restaurante + rolê corretamente).
- **Critérios de aceite**: `change_avatar_page.dart` não existe mais como tela separada; avatar é editável dentro de `edit_profile_page.dart`; galeria mostra fotos agregadas tanto de avaliações individuais quanto coletivas.
- **Riscos**: técnico — médio (extensão de schema em `event_reviews` é a única mudança estrutural de banco fora de Sprint 0). Funcional — baixo. Visual — baixo. Regressão — médio (remover uma rota exige checar todos os pontos que navegavam para `/profile/avatar` e redirecioná-los).
- **Tempo estimado**: médio.

### Sprint 7 — Avaliações, Categorias, Feed Automático

- **Objetivo**: unificar a experiência de avaliação em todo o app e dar visibilidade automática à atividade do grupo.
- **Funcionalidades**: F16 (Avaliação por categorias em `reviews`), F25 (Feed automático de grupo).
- **Arquivos impactados**: `features/reviews/domain/review.dart` (novos campos), `create_review_page.dart`/`edit_review_page.dart`/`review_detail_page.dart` (UI de 5 critérios, referência direta em `submit_event_review_page.dart`), nova tela ou seção para o Feed automático de grupo (local a decidir — candidato natural: dentro de `events_list_page.dart` ou uma aba em "Meu Grupo", coordenar com Sprint 8).
- **Widgets reutilizados**: padrão de UI de `SubmitEventReviewPage` (referência direta para o formulário de 5 critérios em `reviews`); `NotificationsController`/estrutura de lista paginada como base para o Feed automático (`RC03_FEATURE_GAP.md §6`, item 3).
- **Novos widgets**: nenhum, se o Feed automático reaproveitar o padrão de lista já existente.
- **Controllers**: `ReviewDetailController` estendido para os 5 critérios; novo controller para o Feed automático de grupo (`GroupActivityFeedController`, nome ilustrativo, seguindo o mesmo padrão dos 34 controllers já existentes).
- **Banco**: migration para adicionar as 4 colunas de critério em `reviews` (mantendo `rating` como compatibilidade, recalculada como média — decisão já registrada no `RC03_FEATURE_GAP.md §3`, item da diferença existente/desejada); trigger ajustado em `recalculate_restaurant_rating()` para considerar a nova estrutura; view ou query agregada para o Feed automático de grupo (sem tabela nova, reaproveitando `notifications`, per recomendação §6).
- **RLS**: nova policy de leitura do Feed automático, escopada por grupo (`is_group_member()`, já existente, reaproveitada).
- **Testes**: migração de dado (avaliações já existentes com `rating` único precisam continuar válidas — teste de compatibilidade retroativa); teste de widget do novo formulário de 5 critérios; teste do Feed automático de grupo (dado simulado, verificar que só membros do grupo veem a atividade).
- **Critérios de aceite**: avaliação de restaurante usa os mesmos 5 critérios da avaliação coletiva; grupo tem uma visão de atividade recente sem que ninguém precise "postar" manualmente.
- **Riscos**: técnico — médio (migração de `reviews` existentes é a única mudança de schema que toca dado de produção já existente em volume, diferente das outras sprints que só adicionam capacidade nova). Funcional — baixo. Visual — baixo. Regressão — **alto na migração de `reviews`** — mitigação: manter `rating` como coluna calculada/compatível, nunca removê-la, seguindo a mesma disciplina já usada no projeto de nunca editar uma migration já mesclada, sempre adicionar uma nova.
- **Tempo estimado**: médio-longo.

### Sprint 8 — Ranking, Gamificação, Memórias

- **Objetivo**: entregar o "momento WOW" do produto de forma visível e proeminente, e fechar a conexão visual entre gamificação e atividade de grupo.
- **Funcionalidades**: F23 ("Meu Grupo", o item de maior impacto de todo o plano fora de Sprint 0), F44/F45 (Memórias expandidas), seção "XP ganho em rolês" em `gamification_profile_page.dart` (depende de Sprint 0).
- **Arquivos impactados**: nova tela `features/group_ranking/presentation/pages/group_hub_page.dart` (nome ilustrativo, substitui `group_ranking_page.dart`+`group_stats_page.dart`), `core/router/app_router.dart` (consolidar as 2 rotas antigas em 1 nova com parâmetro de aba), `group_detail_page.dart` (botão primário visível para "Meu Grupo", substituindo o menu overflow), `events_list_page.dart` (extensão da query de Memórias), `gamification_profile_page.dart` (nova seção).
- **Widgets reutilizados**: `RankingCard`, `AppCard`, `AppGradients` (aplicado pela primeira vez fora de Login/Gamificação, conforme `RC03_DESIGN_GAP.md §1.3`), Tabs (de Sprint 1).
- **Novos widgets**: nenhum além do componente de Tabs já construído em Sprint 1.
- **Controllers**: `GroupRankingController`/`EventsListController` consolidados sob a nova tela (sem reescrever a lógica interna, só a composição de UI); `EventsListController` estendido para as 2 métricas novas de Memórias.
- **Providers**: nenhum novo — reaproveita os providers já existentes dos 2 controllers.
- **Banco**: nenhuma migration nova para F23/F44/F45 (toda a agregação já existe via triggers de `RC03_UX_AUDIT.md §10`/`rc03_supabase_inventory.md §6`) — dependente apenas de Sprint 0 já ter entregue F29 para a seção de XP de rolês ter dado real.
- **Testes**: teste de navegação (as 2 rotas antigas redirecionam corretamente para a nova, ou são removidas com atualização de todos os pontos de navegação que apontavam para elas); teste de widget da nova tela com as 3 abas; teste de regressão nas Memórias expandidas.
- **Critérios de aceite**: "Meu Grupo" acessível por botão primário visível (não menu); as 3 informações (Ranking/Estatísticas/Memórias) estão na mesma tela, com tratamento visual celebratório; `gamification_profile_page.dart` mostra XP de origem de rolê quando existir.
- **Riscos**: técnico — médio (consolidar 2 rotas em 1 exige atualizar todos os pontos de navegação existentes, incluindo testes de integração que hoje navegam para as rotas antigas). Funcional — baixo. Visual — médio (é o redesenho de maior ambição visual do plano — validar em dispositivo real, não só golden test). Regressão — médio.
- **Tempo estimado**: médio-longo.

### Sprint 9 — Polimento, Animações, Performance

- **Objetivo**: fechar a dívida visual já mapeada e conscientemente adiada (cluster Administração), corrigir os padrões de estado quebrados identificados, e estender a cobertura de motion aos pontos remanescentes.
- **Funcionalidades**: nenhuma da lista oficial do PRD §4 — este sprint executa integralmente o §1.4/§1.2 do `RC03_DESIGN_GAP.md` (redesign de `settings_page.dart`, cluster Administração completo, correção de `public_profile_page.dart`, extensão de `AppAnimatedSwitcher` a `ranking_users_page.dart`, tooltips em `PopupMenuButton`). **Nota de atualização**: a cobertura de `AppAnimatedSwitcher` para a área de estatísticas de grupo, originalmente mapeada em `group_stats_page.dart` pelo `RC03_DESIGN_GAP.md`, passa a ser responsabilidade da Sprint 8 — esse arquivo é absorvido por `group_hub_page.dart` (F23, "Meu Grupo") antes desta sprint começar, e a nova tela já deve nascer com a cobertura de estado correta como parte do próprio trabalho de construção da Sprint 8, não como um item pendente para esta sprint.
- **Arquivos impactados**: `settings_page.dart`, `admin_dashboard_page.dart`, `admin_users_page.dart`, `admin_restaurants_page.dart`, `admin_roles_page.dart`, `moderation_page.dart`, `audit_log_page.dart`, `admin_guard.dart`, `public_profile_page.dart`, `comments_page.dart`, `group_detail_page.dart` (tooltips).
- **Widgets reutilizados**: `AppCard`/`SectionHeader` (agrupamento em `settings_page.dart`), `AppSpacing` (em todo o cluster Administração), `AppAnimatedSwitcher`, `ErrorState`/`EmptyState` (correção de `public_profile_page.dart`).
- **Novos widgets**: nenhum — este sprint é 100% aplicação do que já existe.
- **Controllers/Providers/Banco/Storage/Supabase**: nenhum — é polimento puro de UI sobre dado/estado já corretos.
- **Testes**: `flutter test` completo, sem expectativa de novos testes além de ajustes de finder onde `ListTile` for substituído.
- **Critérios de aceite**: cluster Administração usa `AppSpacing` em 100% dos arquivos; todas as telas com estados Loading/Error/Empty/Loaded usam `AppAnimatedSwitcher`; `public_profile_page.dart` usa `ErrorState`/`EmptyState` em vez de `Text` cru; nenhum `PopupMenuButton` sem tooltip.
- **Riscos**: técnico — baixo. Funcional — nenhum (não muda comportamento). Visual — baixo (é a definição de "polimento"). Regressão — baixo, mas espalhado por 10 arquivos — mitigação: 1 PR por tela, não um PR único gigante, para isolar qualquer regressão.
- **Tempo estimado**: médio (mecânico, mas 10 arquivos).

---

## 5. Ordem das Alterações — resumo por Sprint

| Sprint | O que deve ser implementado primeiro | O que depende disso | O que pode esperar |
|---|---|---|---|
| 0 | Trigger de XP (F29) e verificação + correção do Feed (F24, responsabilidade exclusiva desta sprint) | Trigger de notificação (F41) pode ser feito em paralelo; badges (F30) depende só de F29 | Preferências completas (F48) — trivial, pode ser o último item do sprint |
| 1 | `GroupCard`/`EventCard` (bloqueiam S3/S5) | Tabs (bloqueia S8) e unificação de avatar (bloqueia S6) podem vir depois | Tokens de ícone/imagem — refinamento, não bloqueia nada |
| 2 | Botão de Login Google | Nada depende disso | Fix de AppBar em `email_verification_page.dart` — pode esperar |
| 3 | Aplicar `GroupCard` na Home | — (Feed não é mais parte do escopo desta sprint, ver Sprint 0) | Nada crítico |
| 4 | Confirmar pré-requisito operacional (conta Google Cloud + billing) antes de qualquer código | Autocomplete depende disso | Descoberta guiada por grupo (F13) não depende do Places — pode começar antes, em paralelo |
| 5 | Configuração de plataforma para deep link (App Links/Universal Links) | Tela de confirmação de entrada depende da configuração estar pronta | Rodízio/sorteio (F36) é independente, pode esperar |
| 6 | Unificação de avatar (de S1) precisa estar pronta | Fusão de `change_avatar_page` depende disso | Galeria unificada (F14+F39) pode vir depois, é independente |
| 7 | Decisão de schema para as 4 colunas novas de `reviews` | UI do formulário depende do schema decidido | Feed automático de grupo é independente, pode ser feito em paralelo |
| 8 | Consolidação de rota (2→1) | Composição visual da nova tela depende da rota existir | Seção de XP de rolês espera Sprint 0 entregar F29 |
| 9 | Nenhuma ordem interna crítica — 10 arquivos independentes entre si | — | Pode ser paralelizado internamente entre múltiplos desenvolvedores sem risco de conflito |

---

## 6. Riscos — consolidado

| Sprint | Risco técnico | Risco funcional | Risco visual | Risco de regressão | Mitigação principal |
|---|---|---|---|---|---|
| 0 | Baixo | Baixo (duplicação de XP entre os 2 sistemas de avaliação) | Nenhum | Baixo | Escopo do trigger estritamente isolado por tabela |
| 1 | Baixo | Nenhum | Nenhum | **Médio** (fix de `review_summary_tile.dart` toca 3 telas em produção) | Checar finders de teste antes de trocar `Text` por `ScoreBubble`, seguindo a disciplina já documentada em `UI-07 §5.1` |
| 2 | Baixo | Médio (pontos de falha externos do OAuth) | Baixo | Baixo | Tratamento de erro específico para cancelamento/popup bloqueado |
| 3 | Baixo | Baixo | Médio (é a Home) | Médio | Validar em dispositivo real antes de finalizar |
| 4 | **Médio-alto** (dependência externa paga) | Médio (comportamento sem resultado da API) | Baixo | Baixo | Fallback manual sempre preservado; escopo restrito a restaurante novo primeiro |
| 5 | Médio (configuração de plataforma) | Baixo | Baixo | Baixo | Testar deep link em build de release, não só debug |
| 6 | Médio (extensão de schema em `event_reviews`) | Baixo | Baixo | Médio (remoção de rota) | Checar todos os pontos de navegação para `/profile/avatar` antes de remover |
| 7 | Médio | Baixo | Baixo | **Alto** (migração de `reviews` existentes) | Nunca remover `rating`, só adicionar colunas novas, seguindo a disciplina de nunca editar migration já mesclada |
| 8 | Médio (consolidação de rotas) | Baixo | Médio (maior ambição visual do plano) | Médio | Validar em dispositivo real, não só golden test |
| 9 | Baixo | Nenhum | Baixo | Baixo | 1 PR por tela, não um PR único |

---

## 7. Testes

**Tipos de teste aplicáveis a este plano**, seguindo a convenção já estabelecida no projeto (`RC02_RELEASE_CANDIDATE_REPORT.md`: `flutter analyze` 0 issues, `flutter test` 579/579 antes deste plano começar):

- **Testes unitários**: para toda nova lógica de controller/repository (ex.: cálculo de sugestão de rodízio, agregação de Memórias expandidas).
- **Testes de widget**: para todo componente novo (`GroupCard`, `EventCard`, Tabs) e para toda tela que trocar `ListTile`/`Text` cru por um componente de design system (finders precisam ser atualizados, não só a UI).
- **Testes de integração**: para os 2 fluxos com maior superfície de risco — deep link de convite (Sprint 5) e autocomplete de restaurante com fallback (Sprint 4).
- **Smoke Tests**: repetir a mesma metodologia já usada nas rodadas RC-02C/RC-02D (dispositivo Android real, conta QA permanente, roteiro de fluxo completo) ao final de cada sprint que altera comportamento visível ao usuário (Sprints 0, 3, 4, 5, 6, 7, 8 — não necessariamente Sprint 1, que é só construção de componente sem tela consumidora ainda, nem Sprint 9, que é polimento de baixo risco).
- **Validação manual**: obrigatória para todo item classificado risco visual "Médio" ou "Alto" na tabela do §6 (Sprints 3, 8) — não basta passar em teste automatizado.
- **`flutter analyze`**: 0 issues, obrigatório ao final de cada sprint, sem exceção.
- **`flutter test`**: 100% dos testes passando (a base atual mais os novos), obrigatório ao final de cada sprint, sem exceção.

---

## 8. Checkpoints

Ao final de **cada** sprint, sem exceção, antes de avançar para a próxima:

- ✓ `flutter analyze` limpo (0 issues)
- ✓ `flutter test` 100% passando (nenhuma regressão na suíte existente + testes novos do sprint passando)
- ✓ UX validada — o fluxo entregue bate com o que está descrito em `RC03_UX_AUDIT.md`/`RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md §3` (Jornada Completa do Usuário) para a etapa correspondente
- ✓ UI validada — a tela entregue bate com a classificação-alvo definida em `RC03_DESIGN_GAP.md §1`/§4` (nenhuma tela deveria regredir de nível — ex.: uma tela que era ✓ não pode virar △ como efeito colateral de outra mudança)
- ✓ Documentação atualizada — este plano (`RC03_IMPLEMENTATION_PLAN.md`) deve ser atualizado com o status real do sprint (não é um documento estático, é um plano de execução vivo)

Nenhuma sprint avança sem os 5 itens confirmados. Um sprint que falhar em qualquer um desses critérios permanece em execução, não é declarado concluído por prazo.

---

## 9. Critérios de Conclusão

A RC-03 poderá ser considerada encerrada quando, objetivamente:

1. Todos os 6 itens **Core** do PRD (`RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md §4`) estiverem implementados, testados e validados em dispositivo real.
2. Todos os 6 itens **Muito importantes** estiverem implementados, testados e validados (ou explicitamente adiados por decisão consciente do usuário, documentada, não por omissão silenciosa).
3. `flutter analyze` retornar 0 issues e `flutter test` retornar 100% de sucesso na suíte completa (existente + nova).
4. Um Smoke Test completo (mesma metodologia de RC-02C/RC-02D, dispositivo Android real, conta QA permanente) tiver sido executado cobrindo **todos** os fluxos da Jornada Completa do Usuário (`RC03_PRODUCT_REQUIREMENTS_DOCUMENT.md §3`, as 12 etapas), sem bug crítico ou alto em aberto.
5. Nenhuma tela regredir de classificação frente ao `RC03_UI_AUDIT.md §4` (a classificação ✓/△/✗ original) — o objetivo mínimo é que toda tela termine igual ou melhor do que começou.
6. Os itens **Importantes** (13-17 do PRD) estiverem implementados, ou formalmente movidos para uma próxima rodada com decisão explícita do usuário — não é aceitável que fiquem "esquecidos" sem essa decisão.
7. Este plano (`RC03_IMPLEMENTATION_PLAN.md`) refletir, em sua tabela de status, todos os sprints como concluídos ou explicitamente adiados com justificativa.

Os itens **Opcionais** (18-19) e **Futuro** (20-23) não são critério de conclusão da RC-03 — por definição do próprio PRD, estão fora do escopo formal desta rodada.

---

## 10. Roteiro Executivo

| Sprint | Objetivo | Valor entregue | Tempo | Complexidade | Dependências | Status inicial |
|---|---|---|---|---|---|---|
| Sprint 0 | Fechar o motor social de Grupos/Rolês + verificar e corrigir o Feed | Altíssimo — maior ROI de todo o plano, zero dependência | Curto | Baixa | Nenhuma | Não iniciado |
| Sprint 1 | Construir os 3 componentes novos + 2 unificações | Alto (habilitador de S3/S5/S6/S8) | Médio | Média | Nenhuma | Não iniciado |
| Sprint 2 | Login com Google + refinamentos de auth | Médio | Curto | Baixa | Nenhuma | Não iniciado |
| Sprint 3 | Home com identidade visual | Alto | Médio | Média | Sprint 1 | Não iniciado |
| Sprint 4 | Google Places + descoberta guiada | Alto | Longo | Média-alta | Sprint 1 (parcial); conta Google Cloud (operacional) | Não iniciado |
| Sprint 5 | Identidade de Rolês + deep link + rodízio | Alto | Médio-longo | Média | Sprint 1 | Não iniciado |
| Sprint 6 | Perfil como hub + eliminação de tela + galeria | Alto | Médio | Média | Sprint 1 | Não iniciado |
| Sprint 7 | Avaliação unificada + Feed automático de grupo | Médio-alto | Médio-longo | Média-alta | Nenhuma bloqueante | Não iniciado |
| Sprint 8 | "Meu Grupo" — momento WOW visível | Altíssimo | Médio-longo | Média | Sprint 1, Sprint 0 (XP), Sprint 5 | Não iniciado |
| Sprint 9 | Fechar dívida visual conhecida (Administração, Settings, Perfil Público) | Médio | Médio | Baixa | Sprints 3-8 substancialmente prontos | Não iniciado |

---

**Aguardando revisão do usuário.** Conforme instruído, este documento permanece em modo exclusivamente analítico — nenhuma sprint foi iniciada, nenhum código, migration ou commit foi criado. A implementação real de qualquer sprint requer autorização explícita e específica, sprint a sprint, mesmo após a aprovação deste plano como documento.
