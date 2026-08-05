# RC-03 — FASE 1: Product Audit

**Status:** Draft para aprovação do usuário — análise pura, nenhum código/schema/arquivo de produto foi alterado.
**Data:** 2026-08-04
**Fontes utilizadas (ordem de prioridade, conforme instruído):** Código Flutter (`app/lib/`) → Banco Supabase (`supabase/migrations/` + queries live contra `borah-qa`) → APIs/RPCs → Assets → Documentação (`docs/FASE 2`, `docs/FASE 3`, `docs/FASE 5`, `docs/store/`) → Relatórios RC (raiz do repo) → Identidade Visual (`identidade visual-borah/`).
**Regra seguida:** nenhuma afirmação abaixo vem de memória ou suposição — toda linha cita arquivo/classe/método/linha, ou uma query live contra o banco, ou uma citação textual de documento. Os quatro inventários brutos que sustentam este documento estão em:
- `rc03_flutter_inventory.md` (código — 13 módulos, ~90 classes, 34 controllers, 44 páginas, 46 rotas)
- `rc03_supabase_inventory.md` (schema live-verified — 24 tabelas, RLS, 33 triggers, 35 funções, 3 buckets)
- `rc03_design_inventory.md` (design system + identidade visual + docs UI/UX)
- `rc03_docs_inventory.md` (34 documentos de produto lidos — ET-01/13, UX-01/02, DV-01/12 títulos, 5 relatórios RC, 2 fichas de loja)

---

## 1. Sumário Executivo — o pivô de produto é real e está confirmado por 3 fontes independentes

O achado mais importante desta fase, já sinalizado no inventário de documentação e agora **confirmado pelo código e pelo banco de dados**, é que o BORAH passou por um pivô de produto que a documentação formal (Fase 2 — Especificação Técnica, Fase 3 — UX/UI) nunca foi atualizada para refletir:

| | Visão original (ET-01/13, UX-01/02 — "Draft", pré-pivô) | Produto real hoje (código + banco + loja atual — pós-pivô) |
|---|---|---|
| Núcleo do produto | Feed social individual: seguir usuários, curtir, comentar, avaliar restaurantes sozinho (`ET-09_FEED_AND_SHARING.md`, `DV-07_Social_Module`) | Grupos fechados por convite → Rolês (eventos) → Avaliação Coletiva → Ranking do Grupo (`app/lib/features/{groups,events,event_reviews,group_ranking}/`, schema `groups/group_members/events/event_attendances/event_reviews`) |
| Home / navegação principal | `Home/Pesquisa/Ranking/Perfil`, sem aba "Grupos" (`UX-02_WIREFRAMES.md`) | Aba 0 = **Grupos** (`home_shell_page.dart:41-43`); Feed removido da bottom nav, só acessível via perfil público (`home_shell_page.dart:14-21`) |
| Backend | NestJS + Prisma + Firebase Auth (`ET-01`, `ET-03`) | Supabase (Postgres + RLS + Auth), confirmado live nas 24 tabelas e 35 funções do inventário Supabase; `DV-01_Authentication_Module` já documenta Supabase, então o pivô de stack aconteceu entre a Fase 2 e a Fase 5 |
| Retrospectiva anual | "Wrapped" (`ET-09`) | "Memórias" (loja atual, `EventsListPage` — cards de "mais visitado"/"campeão", `events_list_page.dart`) — mesmo conceito, nome trocado |

**Conclusão da FASE 1:** o app que existe hoje **não é** o app descrito em ET-01–13/UX-01/02/DV-01–12. É um produto diferente, mais restrito e mais social-em-grupo, que a cópia de loja atual (`docs/store/app_store_listing.md`, `google_play_listing.md`) já descreve corretamente, mas que a documentação técnica formal nunca foi atualizada para acompanhar. Isso não é um bug de execução — é uma dívida de documentação. Ela importa para RC-03 porque **qualquer decisão de "isso já existe, não precisa reimplementar" precisa vir do código/banco (o que este documento faz), nunca do ET/UX/DV**, que descrevem um produto anterior.

---

## 2. Auditoria por área de produto

Cada área usa o mesmo formato: **Intenção documentada** (com citação) → **Implementação real** (arquivo:linha) → **Veredito** (Match / Pivô / Gap / Parcial).

### 2.1 Autenticação

- **Documentado:** `ET-03_AUTHENTICATION.md` — NestJS+JWT+BCrypt+Firebase Auth, RBAC Usuário/Administrador. `DV-01_Authentication_Module` — já contradiz ET-03, aponta Supabase Auth.
- **Implementado:** `AuthRepository`/`AuthController` (`app/lib/features/authentication/`) sobre Supabase Auth (`auth_repository_impl.dart:10`). Métodos: signUp/signIn/signOut/requestPasswordReset/updatePassword/resendVerificationEmail + `signInWithGoogle/Apple/Facebook/Anonymously` (`auth_repository.dart:27-60`). RBAC via tabela `user_roles` (`super_admin/admin/moderator/support`, `20260719160000_create_user_roles.sql:18-25`) e função `is_admin()`/`has_admin_role()`/`can_moderate()` (SECURITY DEFINER, `supabase inventory §4`).
- **Veredito: Pivô de stack (ET→DV), implementação atual completa.** Gap de UI confirmado no `BORAH_RELEASE_CANDIDATE_REPORT.md`: **login Google sem botão visível na UI**, embora o método `signInWithGoogle()` exista no repository/controller (`auth_controller.dart:216-226`) — é um método órfão de interface, não uma lacuna de backend.

### 2.2 Perfil de usuário

- **Documentado:** `ET-04_USERS.md` — @username único, estatísticas (restaurantes visitados, eventos, XP, nível, badges), privacidade perfil público/privado.
- **Implementado:** `UserProfile {id, fullName?, bio?, avatarUrl?, city?, state?}` (`user_profile.dart:3`) — **sem campo `username`** (só `fullName`, que não é único, confirmado ausência de constraint UNIQUE em `profiles` no inventário Supabase §1). `ProfilePage` mostra atalhos para Gamificação/Rankings/Notificações (`profile_page.dart:146-156`), não estatísticas agregadas de restaurantes/eventos diretamente na tela de perfil.
- **Veredito: Parcial/Gap.** Não existe `@username` público único em lugar nenhum do schema nem do código — é um campo especificado (RN-002 do ET-04: "username único") que nunca foi implementado. Não existe controle de privacidade "perfil público/privado" — toda `profiles_select_authenticated` é `true` para qualquer autenticado (RLS, inventário Supabase §2), ou seja, **todo perfil é público para qualquer usuário logado**, sem opção de restringir.

### 2.3 Restaurantes (cadastro/busca/detalhe)

- **Documentado:** `ET-07_RESTAURANTS.md` — fonte primária **Google Places API** (place_id, fotos, horário, telefone, website, cache local).
- **Implementado:** `Restaurant` é uma entidade 100% manual/CRUD interno — campos `name, category, description, address, city, state, latitude, longitude` preenchidos por formulário de texto livre (`create_restaurant_page.dart:122-154`), **sem nenhuma integração com Google Places** em nenhum lugar do código (confirmado — `google_sign_in` é a única dependência "Google" em `pubspec.yaml:30-83`, não há `google_places`/`geocoding` nem chave de API Places em nenhum `.env`). Sem `phone`/`website`/`opening_hours` no schema (`restaurants` table, inventário Supabase §1).
- **Veredito: Gap grande, e é exatamente um dos 10 "candidatos" que o próprio usuário já listou para FASE 5/6 (cadastro inteligente via Google Places)** — confirma que essa não é uma lacuna nova, é a mesma identificada pelo usuário ao abrir a RC-03.

### 2.4 Avaliações de restaurante (Reviews)

- **Documentado:** `ET-08` — critérios múltiplos (comida, bebidas, atendimento, ambiente, música, tempo de espera, custo-benefício, limpeza, "voltaria?"), escala sugerida de estrelas.
- **Implementado:** `Review {rating (1-5, single score), comment?, likesCount, photosCount}` (`review.dart:3`) — **uma única nota geral**, não os 9 critérios do ET-08. `CreateReviewPage` usa campo de nota + comentário (`create_review_page.dart:38`). Suporte a até 5 fotos por review (`maxReviewPhotos=5`, `review_detail_controller.dart:13`). Curtidas via `review_likes` (RLS `review_likes_insert_own`, inventário Supabase §2).
- **Veredito: Pivô/simplificação deliberada.** O modelo de "critérios múltiplos" do ET-08 foi implementado só para `event_reviews` (avaliação coletiva de rolê — 5 critérios: comida/atendimento/ambiente/custo-benefício/geral, `event_review.dart:6`), não para `reviews` (avaliação individual de restaurante, que ficou com nota única). Isso é coerente com o pivô geral: o modelo rico de avaliação foi para o fluxo de Grupo/Rolê, o modelo simples ficou para avaliação solo de restaurante. **Confirma também o achado do Beta Playbook §4**: `SubmitEventReviewPage` usa 5 campos numéricos de texto livre, não seletor de estrelas — divergência de UI (não de dado) frente ao "escala sugerida de estrelas" do ET-08.

### 2.5 Favoritos

- **Documentado:** `ET-07` — favoritos individuais por usuário.
- **Implementado:** `FavoriteRepository`/`FavoritesController` completo (`favorites_controller.dart:13`), com busca/filtro por cidade/ordenação (nome/nota/data) (`favorites_page.dart:25`), toggle otimista com rollback (`favorite_toggle_controller.dart:32`).
- **Veredito: Match.** Único módulo simples onde a especificação original bate 1:1 com o implementado.

### 2.6 Rankings (geral de restaurantes)

- **Documentado:** `ET-08` — rankings por grupo/temporada: melhor escolha, maior XP, mais eventos organizados, melhor avaliador, com regras de desempate em 4 níveis (`ET-13`).
- **Implementado:** `RankingsPage`/`RankingsController` — ranking geral de restaurantes por nota, com filtro cidade/categoria (`rankings_page.dart:21`), delega a `RestaurantRepository.listRanked()` (`ranking_repository_impl.dart:14`). **Não há nenhuma lógica de desempate de 4 níveis** implementada em código nem em SQL (nenhuma função do inventário Supabase §4 menciona desempate) — o ranking é, presumivelmente, ordenação simples por `average_rating`.
- **Veredito: Parcial.** A funcionalidade existe mas as regras de negócio detalhadas do ET-13 (desempate) nunca foram codificadas — não é possível confirmar se isso é intencional (simplificação de escopo) ou esquecimento, porque nenhum documento pós-pivô (RC reports) menciona essa decisão explicitamente. **Recomendo tratar como decisão de escopo a esclarecer com o usuário na FASE 5 (Feature Gap), não assumir.**

### 2.7 Social (Feed, Comentários, Seguidores)

- **Documentado:** `ET-09_FEED_AND_SHARING.md`, `DV-07_Social_Module` — núcleo do produto na visão original (feed, posts, álbuns por evento, curtidas, comentários, Wrapped).
- **Implementado:** módulo `social` existe completo — `FeedController`/`FeedPage` (`feed_controller.dart:11`), `CommentsController` com denúncia/moderação (`comments_controller.dart:12`), `FollowController`/`FollowListController` (`follow_controller.dart:10`). **Mas foi rebaixado de Home/aba principal para "camada secundária"** — confirmado pelo próprio código: `home_shell_page.dart:14-21` documenta explicitamente em comentário a decisão de remover Feed da bottom nav em favor de Grupos; `FeedPage` só é alcançável hoje via `PublicProfilePage` (perfis de outros usuários, `public_profile_page.dart:26`), rota `/feed` não está em nenhum item de navegação principal (confirmado: `/feed` não aparece na tabela dos 4 itens do bottom nav, inventário Flutter §15).
- **Veredito: Pivô confirmado, não removido — rebaixado.** O módulo Social inteiro (Feed/Comentários/Seguidores) continua 100% funcional no código, só não é mais a porta de entrada do app. Isso é coerente com a decisão de produto já tomada pelo usuário ("Grupos é a Home, confirmado" — `BORAH_RELEASE_CANDIDATE_REPORT.md` item 6 dos gaps de escopo).

### 2.8 Gamificação (XP/Badges/Ranking de usuários)

- **Documentado:** `ET-13_GAMIFICATION_ENGINE.md` — tabela de XP explícita: Participar de evento=50, Criar evento=100, Check-in=25, Avaliar restaurante=40, Convidar membro=75; níveis 200/500/900 XP; desafios diário/semanal/mensal/temporadas por grupo.
- **Implementado:** `award_gamification_points()`/`award_badge()` (SECURITY DEFINER, `20260720120100_create_gamification_functions_and_triggers.sql:58-111`). Valores reais: **avaliação de restaurante = 40XP/40pts** (bate com ET-13), **comentário = 10XP/10pts** (não especificado no ET-13), **curtida recebida = 5XP/5pts** (não especificado no ET-13). Níveis: 200/500/900 XP — **bate exatamente** com ET-13. Badges: 5 fixos (`first_review, explorador, gourmet, influenciador, critico`, `badges` seed, inventário Supabase §1) — **não corresponde** à lista de badges "com raridade" e "desafios" do ET-13, que não existem em nenhuma tabela do schema (não há `challenges`/`seasons`/`group_seasons` em nenhuma das 24 tabelas).
- **Achado crítico confirmado, agora duplamente verificado (código E schema live):** **Grupos/Rolês/Avaliação Coletiva concedem ZERO XP.** Nenhum trigger em `groups`, `group_members`, `events`, `event_attendances`, `event_reviews` chama `award_gamification_points()`/`award_badge()` — confirmado tanto por leitura de todas as migrations quanto por query live em `information_schema.triggers` (inventário Supabase §3a). Isso significa que a tabela de XP do ET-13 ("Participar de evento=50, Criar evento=100, Check-in=25") **nunca foi implementada para o produto pós-pivô** — só sobrevive para o modelo antigo de avaliação individual de restaurante.
- **Veredito: Gap grande e concreto.** O sistema de gamificação está estruturalmente pronto (função central `award_gamification_points()` é genérica, aceita qualquer XP/pontos) mas **desconectado** do núcleo atual do produto (Grupos/Rolês). Conectar essas duas peças é provavelmente o item de maior impacto/menor esforço de todo o roadmap de FASE 6/7 — a infraestrutura já existe, falta só o trigger.

### 2.9 Grupos

- **Documentado:** `ET-05_GROUPS.md` — "núcleo da experiência social do BORAH". Papéis Owner/Admin/Membro. **Rodízio de escolha** (RN-001–004: sistema sugere automaticamente quem escolhe o próximo restaurante, com histórico). **Temporadas** (`group_seasons`, ranking por período, campeão).
- **Implementado:** `GroupRepository`/`GroupDetailController` completos (`group_repository.dart:17`), papéis via `group_members.role CHECK ('owner','admin','member')` (inventário Supabase §1), RLS reforça hierarquia (`is_group_owner`/`is_group_admin`/`is_group_member`, SECURITY DEFINER). **Rodízio de escolha: não existe.** Nenhuma coluna/tabela rastreia "quem escolheu por último" nem sugere o próximo automaticamente — `create_event()` só exige que o usuário escolha manualmente o restaurante (`create_event.sql:159-199`), sem qualquer lógica de sugestão. **Temporadas: não existem.** Não há tabela `group_seasons` nem qualquer coluna de período/temporada em `groups` (confirmado, schema tem só `last_activity_at`, sem manutenção por trigger — "débito técnico documentado" no próprio comentário da migration, inventário Supabase §1).
- **Veredito: Parcial — núcleo forte, 2 regras de negócio específicas do ET-05 nunca implementadas.** Rodízio de escolha e Temporadas são funcionalidades nomeadas explicitamente na spec original como parte do "núcleo" e simplesmente não existem hoje. Não há nenhuma menção a elas em nenhum relatório RC como "decisão de escopo" — parecem ter sido silenciosamente descartadas, não decididas conscientemente. **Merece decisão explícita do usuário na FASE 5.**

### 2.10 Rolês (Events)

- **Documentado:** `ET-06_EVENTS.md` — criação, RSVP (Confirmado/Talvez/Recusado/Sem resposta), **Check-in** (janela do evento, libera avaliação), Encerramento. **Regra: "apenas um evento ativo por grupo (MVP)"**.
- **Implementado:** `Event`/`EventAttendance` (`event.dart:5`, `event_attendance.dart:5`) — status de attendance é só `pending/confirmed/declined` (CHECK constraint, inventário Supabase §1) — **sem opção "Talvez"** do ET-06. **Não existe Check-in.** Nenhuma tabela/coluna de check-in existe no schema; `can_review_event()` libera a avaliação coletiva quando `attendance='confirmed' AND event.status='scheduled' AND scheduled_at <= now()` (`supabase inventory §4`) — ou seja, o "gatilho" de liberação de avaliação é **tempo passado + confirmação prévia**, não um check-in ativo do usuário no local. A regra "um evento ativo por grupo" **não é reforçada em lugar nenhum** — não há UNIQUE/CHECK que impeça múltiplos eventos `scheduled` simultâneos no mesmo grupo (confirmado ausência de tal constraint no inventário Supabase §1/§6).
- **Veredito: Pivô de mecanismo — check-in físico foi substituído por confirmação prévia + passagem de tempo.** Isso é uma simplificação sensata (não depende de geolocalização/proximidade), mas é uma mudança de mecanismo não documentada em nenhum lugar — vale confirmar como decisão consciente. A ausência de "um evento ativo por grupo" parece ser uma decisão correta de relaxamento de escopo (grupos maiores plausivelmente querem múltiplos rolês em paralelo), mas também nunca foi documentada como tal.

### 2.11 Avaliação Coletiva de Rolê (EventReviews)

- **Documentado:** não existe como conceito na Fase 2 original — é inteiramente um produto do pivô (ET-08 fala de avaliação por evento, mas individual, não "coletiva" no sentido de nota única do grupo).
- **Implementado:** `EventReview` com 5 notas (`foodScore, serviceScore, ambienceScore, costBenefitScore, overallScore`) + comentário, uma por usuário por evento (`event_reviews_unique(event_id, user_id)`, inventário Supabase §1), agregadas em `events.average_rating` via `recalculate_event_rating()`.
- **Veredito: Feature nova pós-pivô, bem implementada, sem lacuna estrutural encontrada** além do já citado (zero XP, ver §2.8) e da UI de texto-livre-numérico em vez de estrelas (Beta Playbook §4).

### 2.12 Ranking de Grupo / Memórias (GroupRanking)

- **Documentado:** não existe na Fase 2/3 original (é pós-pivô).
- **Implementado:** `GroupRankingPage` (ranking de membros por rolês participados) + `GroupStatsPage` (estatísticas: total de rolês, restaurantes diferentes, dia/horário mais comum, faltas, avaliações) — dados vêm 100% de colunas desnormalizadas em `group_members` (`events_count, reviews_count, average_score, declined_count`), recalculadas por trigger a cada mudança (inventário Supabase §6). "Memórias" = cards de "mais visitado"/"campeão" no topo de `EventsListPage` (`events_list_page.dart`).
- **Gap confirmado independentemente por 2 fontes:** o `BORAH_RELEASE_CANDIDATE_REPORT.md` (gap de escopo #5) já registra que **"Quem mais participou"/"Quem mais escolheu" em Memórias nunca foram implementados**, só "Mais visitado"/"Campeão" — e o inventário de código confirma que não há nenhum controller/query que produza essas duas métricas adicionais.
- **Veredito: Match parcial com o que a própria engenharia já documentou como gap conhecido — não é um achado novo, é uma confirmação.**

### 2.13 Notificações

- **Documentado:** `ET-10_NOTIFICATIONS.md` — FCM, 4 categorias, **notificação "avaliação pendente/liberada"**, RN-002: "notificações críticas não podem ser desativadas".
- **Implementado:** notificações in-app puras via tabela `notifications` + `create_notification()` (SECURITY DEFINER) — **sem FCM/push real**, confirmado como decisão de escopo explícita ("Push Notifications fora do Beta fechado", `RC02_BETA_READY.md`). 8 tipos de notificação no CHECK constraint final (`notifications_type_check`, inventário Supabase §1), cobrindo followers/comments/likes/gamificação/grupos/eventos/attendance. **Notificação "avaliação liberada" (event_reviews) confirmada ausente** — nenhum trigger em `event_reviews` chama `create_notification()` (inventário Supabase §3b) — o que é o mesmo gap já apontado por 3 fontes independentes (`ET-10`, `BORAH_RELEASE_CANDIDATE_REPORT.md` débito #11, `BORAH_BETA_PLAYBOOK.md` §2.4), agora confirmado como fato estrutural do banco, não hipótese. Preferências de notificação (`notification_preferences`) só têm categoria "social" exposta na UI (`NotificationPreferencesPage` é um único `SwitchListTile`, `notification_preferences_page.dart:14`), embora o schema já suporte categoria `'groups'` desde `20260801130000` — gap de UI, não de banco (mesmo padrão do gap #2 do RC Report).
- **Veredito: Gap confirmado e triplamente verificado — notificação de avaliação liberada é a lacuna de produto mais bem documentada de todo o audit.**

### 2.14 Administração/Moderação

- **Documentado:** `ET-12_SECURITY.md`, `DV-08_Administration_Module` — RBAC, moderação de conteúdo.
- **Implementado:** módulo `administration` completo (Dashboard/Usuários/Restaurantes/Moderação/Papéis/Audit Log), 6 páginas, protegido por `AdminGuard` (`admin_guard.dart:11`) + RLS baseada em `user_roles`/`is_admin()`/`can_moderate()`.
- **Veredito: Match.** Único módulo "de retaguarda" onde a spec original e a implementação convergem quase totalmente.

### 2.15 Navegação principal

- **Documentado:** `UX-02_WIREFRAMES.md` — `Home/Pesquisa/Ranking/Perfil`.
- **Implementado:** `Grupos/Restaurantes/Favoritos/Perfil` (`home_shell_page.dart:41-58`) — **nenhum dos 4 itens da spec original sobrevive sem mudança**: "Home" virou "Grupos", "Pesquisa" virou "Restaurantes" (mesma função, nome diferente), "Ranking" saiu da bottom nav (acessível só via Perfil→atalho), "Favoritos" entrou (não estava na spec original).
- **Veredito: Pivô total, já confirmado/decidido pelo usuário** (gap de escopo #6 do RC Report: "Grupos como Home confirmado como decisão tomada").

---

## 3. Tabela consolidada — Match / Pivô / Gap por área

| Área | Veredito | Confirmado por quantas fontes independentes |
|---|---|---|
| Autenticação | Pivô de stack (ET→DV), 1 gap de UI (botão Google) | 2 (ET vs DV; RC Report) |
| Perfil de usuário | Gap (sem username único, sem privacidade de perfil) | 1 (achado novo desta auditoria) |
| Restaurantes | Gap grande (sem Google Places) | 2 (ET-07; já era candidato #1 do usuário) |
| Avaliações de restaurante | Pivô/simplificação (nota única vs. critérios) | 2 (ET-08; Beta Playbook §4) |
| Favoritos | Match | 1 |
| Rankings | Parcial (sem desempate de 4 níveis) | 1 (achado novo) |
| Social/Feed | Pivô (rebaixado, não removido) | 3 (Beta Playbook; RC Report; código) |
| Gamificação | Gap grande (zero XP em Grupos/Rolês) | 2 (memória de sessão anterior; agora live-confirmed) |
| Grupos | Parcial (sem rodízio, sem temporadas) | 1 (achado novo) |
| Rolês/Events | Pivô de mecanismo (check-in→confirmação+tempo) | 1 (achado novo) |
| Avaliação Coletiva | Feature nova, sem lacuna estrutural extra | — |
| Ranking de Grupo/Memórias | Gap confirmado (métricas "quem mais...") | 2 (RC Report gap #5; código) |
| Notificações | Gap confirmado (avaliação liberada) | 3 (ET-10; RC Report débito #11; Beta Playbook §2.4) |
| Administração | Match | 1 |
| Navegação principal | Pivô total, já decidido | 2 (UX-02 vs. código; RC Report gap #6) |

---

## 4. O que isso significa para as próximas fases

- **FASE 2 (UX Audit)** deve tratar UX-01/UX-02 como referência histórica, não como baseline — os fluxos reais (Grupo→Rolê→Confirmar→Avaliar) precisam ser mapeados do zero a partir do código, não comparados linha a linha com os wireframes de 2026-07.
- **FASE 5 (Feature Gap)** tem agora uma lista concreta de decisões pendentes do usuário, não apenas bugs: rodízio de escolha em Grupos, Temporadas, desempate de ranking, métricas adicionais de Memórias — nenhuma delas está formalmente descartada, só ausente.
- **FASE 6 (10 funcionalidades candidatas)** já tem 2 confirmações diretas nesta auditoria: Google Places (restaurantes) e gamificação expandida (conectar Grupos/Rolês ao motor de XP já existente) são exatamente os itens #1 e #10 da lista do usuário, e este documento mostra que a infraestrutura para o segundo já existe — só falta o trigger.
- **FASE 7 (Reutilização)** deve destacar `award_gamification_points()` como o melhor exemplo de "motor pronto, subutilizado" de todo o app — genérico, testado em produção (reviews/comments/likes já o usam), e uma única chamada de trigger o conectaria a Grupos/Rolês.

---

**Próximo entregável:** `RC03_UX_AUDIT.md` (FASE 2), a partir dos fluxos reais do código (não da spec original) cruzados com os achados de UX já documentados no Beta Playbook.
