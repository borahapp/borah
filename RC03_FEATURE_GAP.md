# RC-03 — FASE 5: Feature Gap

**Status:** Draft para aprovação do usuário — análise pura, nenhum código/schema/arquivo de produto foi alterado.
**Data:** 2026-08-04
**Objetivo desta fase:** não é só descobrir funcionalidades faltantes — é responder oficialmente **"o que ainda falta existir para que o BORAH entregue exatamente a experiência definida na RC-03?"**, definindo o escopo final do BORAH 2.0. Nada entra em implementação sem aparecer na lista oficial do §11.
**Baseline (restrições oficiais de projeto, já confirmadas pelo usuário):** [`RC03_PRODUCT_AUDIT.md`](RC03_PRODUCT_AUDIT.md), [`RC03_UX_AUDIT.md`](RC03_UX_AUDIT.md), [`RC03_UI_AUDIT.md`](RC03_UI_AUDIT.md), [`RC03_DESIGN_GAP.md`](RC03_DESIGN_GAP.md). Este documento não redescobre esses achados — referencia-os por ID e foca em transformá-los em escopo de funcionalidade, com um segundo eixo novo: as 18 funcionalidades candidatas que o usuário pediu para analisar em profundidade nesta fase.
**Fontes adicionais desta fase:** `rc03_supabase_inventory.md` (schema live-verified, para responder "o que já existe no banco" com precisão), `rc03_flutter_inventory.md` (controllers/providers/repositories existentes).

---

## 1. Matriz Completa de Funcionalidades

Cobertura: todas as funcionalidades atuais do produto (organizadas pelos 15 módulos do Product Audit) mais as funcionalidades candidatas citadas nesta fase. Cada linha responde Status + Objetivo + Dependências + Impacto + Complexidade + Prioridade. Descrição/Fluxo detalhados só são repetidos em prosa quando o item ainda não foi descrito em nenhum documento anterior (a maioria dos itens "Existe" já tem descrição completa no Product Audit §2, e não é repetida aqui para não inflar o documento).

| ID | Funcionalidade | Status | Objetivo | Dependências | Impacto | Complexidade | Prioridade |
|---|---|---|---|---|---|---|---|
| F01 | Login/Cadastro e-mail+senha | Existe | Entrada básica no app | — | — | — | — |
| F02 | Login social (Google/Apple/Facebook) | **Parcial** | Reduzir fricção de cadastro | Métodos já existem em `AuthController`; falta botão de UI (Google) | Médio | Baixa (é só UI) | Importante |
| F03 | Verificação de e-mail | Existe | Confirmar identidade | — | — | — | — |
| F04 | Exclusão de conta | Existe | Conformidade/controle do usuário | — | — | — | — |
| F06 | Edição de perfil | Existe | Manter dados pessoais atualizados | — | — | — | — |
| F07 | @username único | **Não existe** | Identidade pública estável, menções | Requer coluna nova + constraint UNIQUE em `profiles` | Baixo | Média (unicidade + migração de perfis existentes) | Opcional |
| F08 | Privacidade de perfil (público/privado) | **Não existe** | Controle de exposição social | Requer coluna + reescrever RLS de `profiles`/`reviews`/`event_reviews` | Baixo-médio | Média-alta (toca RLS em múltiplas tabelas) | Futuro |
| F09 | Perfil com atalhos ricos (redesign) | **Parcial** | Tornar o Perfil um hub de valor, não uma lista neutra | Design Gap §1.4; dados de Gamificação/Rankings já existem | Alto | Baixa (visual, dado já existe) | Muito importante |
| F10 | Cadastro manual de restaurante | Existe | Fallback sempre disponível | — | — | — | — |
| F11 | Busca/filtro de restaurante | Existe | Descoberta básica | — | — | — | — |
| F12 | Cadastro inteligente (Google Places + Autocomplete) | **Não existe** | Eliminar digitação manual, dado confiável | API paga externa + billing; ver §5.1 | Alto | Média-alta | Muito importante |
| F13 | Descoberta de restaurantes guiada pelo grupo | **Não existe** | Sugerir com base em favoritos/histórico do grupo | Reusa `favorites`+`group_members`+`events`, sem tabela nova; ver §5.9 | Alto | Baixa-média (é query nova, não infraestrutura nova) | Muito importante |
| F14 | Galeria automática de restaurante | **Não existe** | Mostrar fotos reais agregadas de quem avaliou | Reusa fotos de `reviews`; ver §5.4 (unificar com F39) | Médio | Baixa (agregação de dado existente) | Importante |
| F15 | Avaliação individual de restaurante | Existe | Registrar experiência 1x por usuário/restaurante | — | — | — | — |
| F16 | Avaliação por categorias (estender a `reviews`) | **Não existe** para `reviews` (já existe em `event_reviews`) | Consistência de critério entre os 2 sistemas de avaliação | Ver Oportunidade #6 do UX Audit; requer migração de schema em `reviews` | Médio | Média (schema change + UI) | Importante |
| F17 | Curtidas em avaliação | Existe | Reconhecimento social leve | — | — | — | — |
| F18 | Comentários em avaliação | Existe | Discussão em torno de uma avaliação | — | — | — | — |
| F19 | Favoritar restaurante | Existe | Guardar para depois | — | — | — | — |
| F20 | Ranking geral de restaurantes | Existe | Descoberta por qualidade | — | — | — | — |
| F21 | Desempate de ranking (4 níveis, ET-13) | **Não existe** | Previsibilidade de ordenação em empates | Nenhuma nova — é lógica de ordenação sobre dado já existente | Baixo | Baixa | Opcional |
| F22 | Ranking de usuários (global/amigos) | Existe | Competição individual | — | — | — | — |
| F23 | "Meu Grupo" (unificação Ranking+Estatísticas+Memórias) | **Não existe** (é composição de telas existentes) | Tornar o "momento WOW" visível e proeminente | Design Gap §1.3; nenhum dado novo, só componente de Tabs | Altíssimo | Média | **Core** |
| F24 | Feed (reviews de seguidos) | **Parcial — gap crítico a verificar** | Descoberta social passiva | Rota/controller já existem; suspeita de ausência de ponto de entrada na UI (UX Audit §2.11) | Alto (se confirmado) | Baixa (é 1 botão, se confirmado) | **Core (verificação); Muito importante (correção)** |
| F25 | Feed automático de atividade de grupo | **Não existe** | Ver o que o grupo fez sem precisar entrar em cada rolê | Ver §5.3; requer nova fonte de "eventos de feed" (rolês criados, avaliações coletivas) | Alto | Média-alta | Importante |
| F26 | Seguidores/Seguir | Existe | Grafo social entre usuários | — | — | — | — |
| F27 | Compartilhamento (convite, review) | Existe | Canal de aquisição/divulgação | — | — | — | — |
| F28 | XP/Nível/Badges (Reviews/Comments/Likes) | Existe | Recompensar contribuição individual | — | — | — | — |
| F29 | XP automático para Grupos/Rolês/Avaliação Coletiva | **Não existe** | Conectar gamificação ao núcleo real do produto pós-pivô | `award_gamification_points()` já pronta; só faltam triggers novos em `event_attendances`/`event_reviews` | Altíssimo | Baixa | **Core** |
| F30 | Badges automáticos ligados a atividade de grupo | **Não existe** | Reconhecer engajamento em grupo (ex.: presença consistente) | `award_badge()` já pronta; depende de F29 estar decidido primeiro | Alto | Baixa (mesma infra de F29) | Muito importante |
| F31 | Desafios diário/semanal/sazonal | **Não existe** | Engajamento recorrente estruturado | Requer tabela nova (`challenges`) + lógica de expiração | Médio | Alta | Futuro |
| F32 | Temporadas de grupo | **Não existe** | Ranking com recomeço periódico | Requer tabela nova (`group_seasons`) + decisão de regra de negócio | Médio | Alta | Futuro |
| F33 | CRUD de grupo + papéis | Existe | Núcleo social do produto | — | — | — | — |
| F34 | Convite por código | Existe | Entrada controlada no grupo | — | — | — | — |
| F35 | Deep link de convite de grupo | **Não existe** | Eliminar copiar/colar manual de código | Requer App Links (Android)/Universal Links (iOS) + rota no GoRouter | Alto | Média (infra de plataforma, não é só Flutter) | **Core** |
| F36 | Rodízio/sistema de sorteio de escolha | **Não existe** | Resolver fricção social de "quem sempre escolhe" | Requer decisão de regra de negócio + coluna/lógica nova | Médio | Média | Importante |
| F37 | CRUD de rolê + RSVP | Existe | Organização do encontro | — | — | — | — |
| F38 | Confirmação/recusa de presença | Existe | Sinalização de comparecimento | — | — | — | — |
| F39 | Álbum do rolê (fotos coletivas) | **Não existe** | Memória visual compartilhada do encontro | Ver §5.4 — recomendo unificar com F14, não duplicar | Alto | Média | Importante |
| F40 | Avaliação coletiva de rolê | Existe | Nota única de grupo por experiência | — | — | — | — |
| F41 | Notificação "avaliação liberada" | **Não existe** | Fechar o loop comportamental "aconteceu → avalie agora" | `create_notification()` já pronta; só falta trigger novo | Altíssimo | Baixa | **Core** |
| F42 | Ranking do Grupo | Existe | Competição saudável dentro do grupo | — | — | — | — |
| F43 | Estatísticas do Grupo | Existe | Visão analítica do grupo | — | — | — | — |
| F44 | Memórias (mais visitado/campeão) | **Parcial** | Nostalgia/retrospectiva | Já existe parcialmente; falta expandir métricas | Médio | Baixa | Importante |
| F45 | Memórias expandidas (quem mais participou/escolheu) | **Não existe** | Completar a promessa original de Memórias | Mesma query pattern de F44, só mais métricas | Médio | Baixa | Importante |
| F46 | GroupCard/EventCard (suporte de design) | **Não existe** | Dar identidade visual às listas centrais | Pré-requisito de F23 e das listas de Grupos/Rolês (Design Gap §3) | Alto | Média | **Core** |
| F47 | Notificações in-app | Existe | Central de avisos | — | — | — | — |
| F48 | Preferências de notificação completas (categoria Grupos) | **Parcial** | Controle real sobre o que o usuário recebe | Backend já suporta `category='groups'`; só falta 1 `SwitchListTile` | Médio | Baixa | Muito importante |
| F49 | Push notifications (FCM) | **Não existe** | Alcançar o usuário fora do app | Decisão de escopo já registrada como fora do Beta fechado (`RC02_BETA_READY.md`) | Alto (mas fora do escopo imediato) | Alta | Futuro |
| F50 | Painel administrativo | Existe | Moderação/gestão interna | — | — | — | — |
| — | Check-in físico geolocalizado (ET-06 original) | **Obsoleta/Substituída** | — | Já substituído por confirmação prévia + passagem de tempo (`can_review_event()`), funciona bem | — | — | **Descartar** — não reconstruir |
| — | "Wrapped" (nomenclatura ET-09) | **Substituída** | — | Renomeada para "Memórias" em toda a documentação e produto atuais | — | — | **Descartar** (nomenclatura, não funcionalidade) |
| — | Backend NestJS/Prisma (ET-01/02/03) | **Obsoleta** | — | Supabase é a arquitetura real e congelada | — | — | **Descartar** |
| — | Bottom nav antiga (Home/Pesquisa/Ranking/Perfil sem Grupos) | **Obsoleta/Substituída** | — | Já substituída por Grupos/Restaurantes/Favoritos/Perfil, decisão já tomada | — | — | **Descartar** |

---

## 2. Classificação

| Nível | Itens |
|---|---|
| **Core** (o BORAH 2.0 não está completo sem isso) | F23 (Meu Grupo), F24 (verificar/corrigir entrada do Feed), F29 (XP automático Grupos/Rolês), F35 (Deep link de convite), F41 (Notificação avaliação liberada), F46 (GroupCard/EventCard) |
| **Muito importante** | F02 (login Google UI), F09 (Perfil redesenhado), F12 (Google Places), F13 (Descoberta guiada por grupo), F25 (Feed automático de grupo), F30 (Badges de grupo), F48 (Preferências de notificação completas) |
| **Importante** | F14 (Galeria automática, unificar com F39), F16 (Avaliação por categorias em Reviews), F36 (Rodízio/sorteio), F39 (Álbum do rolê, unificar com F14), F44/F45 (Memórias expandidas) |
| **Opcional** | F07 (@username), F21 (Desempate de ranking) |
| **Futuro** | F08 (Privacidade de perfil), F31 (Desafios), F32 (Temporadas), F49 (Push/FCM) |
| **Descartar** | Check-in físico geolocalizado, nomenclatura "Wrapped", backend NestJS/Prisma, bottom nav antiga |

**Nota sobre por que 6 itens são Core e não "Muito importante"**: os 6 itens Core compartilham uma característica confirmada nas 4 fases anteriores — cada um fecha um loop que hoje está **estruturalmente pronto mas desconectado** (motor de XP, motor de notificação, componentes de card, ponto de entrada de rota) ou resolve o **maior ponto de risco de desistência já identificado** (deep link de convite, UX Audit §3). Não são "features novas" no sentido de construção do zero — são o que falta para o produto que já existe funcionar como uma experiência coerente. Por isso entram como requisito mínimo do BORAH 2.0, não como melhoria opcional.

---

## 3. Diferença entre funcionalidade existente e desejada

Cobre os itens "Parcial" e "Não existe" classificados Core/Muito importante/Importante (os itens Opcional/Futuro estão descritos com menos detalhe no §1, por serem de menor prioridade nesta rodada).

| Funcionalidade | Existente hoje | Desejada (BORAH 2.0) | O que precisa mudar | O que pode ser reaproveitado | O que será removido |
|---|---|---|---|---|---|
| F23 Meu Grupo | 2 telas separadas atrás de menu overflow | 1 tela com abas Ranking/Estatísticas/Memórias, acessível por botão primário | Composição de UI + 1 componente de Tabs novo | `GroupRankingController`, `EventsListController` (memórias), `RankingCard`, `AppCard` — tudo reaproveitado | As 2 rotas separadas (`/groups/:id/ranking`, `/groups/:id/stats`) podem convergir para 1 rota com parâmetro de aba |
| F24 Feed | Rota/controller/página funcionais, sem ponto de entrada confirmado na UI | Acessível a partir de algum lugar real da navegação (a decidir: ícone no Perfil? aba própria voltando? atalho em "Meu Grupo"?) | 1 decisão de produto (onde) + 1 botão/rota de entrada | `FeedController`/`FeedPage` 100% prontos | Nada |
| F29 XP automático Grupos/Rolês | `event_attendances`/`event_reviews` não geram XP | Confirmar presença e avaliar coletivamente geram XP como qualquer outra ação social do app | 2 triggers SQL novos (`handle_gamification_new_attendance`, `handle_gamification_new_event_review`, nomes ilustrativos) | `award_gamification_points()`/`award_badge()` 100% reaproveitados, sem alteração | Nada |
| F35 Deep link de convite | Convite é só um código de 8 caracteres em texto | Link único (`https://borah.app/join/{code}` ou esquema customizado) abre o app direto na confirmação | Infra de App Links/Universal Links + 1 rota no GoRouter | `join_group_by_invite_code()` RPC já pronta; `JoinGroupController` já pronto (só precisa ser alcançável por rota, não só por formulário) | O formulário de "colar código" continua existindo como fallback, não é removido |
| F41 Notificação avaliação liberada | Silêncio total — usuário só descobre voltando por conta própria | Notificação automática assim que `can_review_event()` fica verdadeiro para cada confirmado | 1 trigger SQL novo em `event_attendances`/`events` | `create_notification()` 100% reaproveitada | Nada |
| F46 GroupCard/EventCard | `ListTile` cru em `groups_list_page`/`events_list_page` | Cards com identidade visual (foto/cor, prévia de atividade) | 2 componentes novos de design system | Padrão de `RestaurantCard`/`RankingCard` como referência de como construir | `ListTile` cru é removido dessas 2 telas |
| F02 Login Google | Método pronto, sem botão | Botão visível na tela de Login | 1 botão de UI + fluxo de tratamento de erro específico de OAuth | `AuthController.signInWithGoogle()` 100% pronto | Nada |
| F09 Perfil redesenhado | Atalhos como `ListTile` neutro | Atalhos como cards com prévia de dado (nível/XP no atalho de Gamificação) | Composição de UI | `AppCard`, dados já expostos por `GamificationProfileController`/`RankingUsersController` | `Card`+`ListTile` cru atual |
| F12 Google Places | Formulário 100% manual | Autocomplete preenchendo nome/categoria/endereço/lat-long/foto | Integração de API paga + possível evolução de schema (telefone/horário, se adotado) | `CreateRestaurantPage` continua existindo como fallback manual | Nenhum campo existente é removido — só deixa de ser obrigatório digitar tudo |
| F13 Descoberta guiada por grupo | Busca é neutra, sem contexto de grupo | Sugestões "favoritos do grupo"/"ainda não visitado pelo grupo" ao criar rolê | Nova query cruzando `favorites`+`group_members`+`events`, exibida via `RestaurantCard` já existente | Toda a infraestrutura de dado já existe | Nada |
| F25 Feed automático de grupo | Não existe | Atividade do grupo (rolês criados, avaliações coletivas, novos membros) visível como feed | Requer decisão: uma view agregada em SQL, ou reaproveitar `notifications` como fonte primária (ver §6) | Potencialmente `NotificationsController`/estrutura de lista paginada já existente | Nada — é aditivo |
| F48 Preferências completas | Só toggle "social" na UI | Toggle "social" + "grupos" | 1 `SwitchListTile` adicional | Schema já suporta `category='groups'` desde `20260801130000` | Nada |
| F14+F39 Galeria/Álbum | Não existe nenhuma das duas | 1 galeria unificada de fotos, filtrável por restaurante OU por rolê | Ver §6 — recomendo tratar como 1 funcionalidade, não 2 | Fotos já existem em `reviews`/bucket `review-photos`; se `event_reviews` ganhar suporte a foto (mudança de schema), a mesma galeria cobre os 2 casos | Nada |
| F16 Avaliação por categorias em Reviews | `reviews` tem nota única | `reviews` com os mesmos 5 critérios já usados em `event_reviews` | Migração de schema em `reviews` (novas colunas) + UI | Padrão de UI de `SubmitEventReviewPage` já existe como referência direta | A coluna `rating` única não é removida (mantida para compatibilidade/simplicidade, pode virar média calculada dos 5 critérios) |
| F36 Rodízio/sorteio | Não existe, escolha é sempre manual | Sugestão (nunca obrigação) de quem escolhe o próximo rolê | Requer decisão de regra de negócio + 1 coluna de rastreamento em `groups`/`group_members` | Nenhuma infraestrutura de UI nova além de um badge/texto de sugestão na tela de criar rolê | Nada |
| F44/F45 Memórias expandidas | Só "mais visitado"/"campeão" | + "quem mais participou"/"quem mais escolheu" | Mesma query pattern de `EventsListController`, estendida | Estrutura de card de Memórias já existe | Nada |

---

## 4. Reutilização — minimizando código novo

Para cada item Core/Muito importante/Importante, o que já existe e pode ser diretamente reaproveitado (sem reescrever).

| Funcionalidade | Módulos que já resolvem parte | Widgets reutilizáveis | Controllers existentes | Providers existentes | APIs/RPCs existentes | Triggers existentes | Tabelas existentes | Migrations que já atendem |
|---|---|---|---|---|---|---|---|---|
| F23 Meu Grupo | `group_ranking`, `group_ranking` (stats) | `RankingCard`, `AppCard`, `SectionHeader` | `GroupRankingController`, `EventsListController` | `groupRankingControllerProvider`, `eventsListControllerProvider` | — | `recalculate_member_events_count`, `recalculate_member_review_stats` | `group_members` (colunas desnormalizadas), `events` | `20260801110000_add_group_ranking_columns.sql`, `20260801120000_add_member_declined_count.sql` |
| F24 Feed (correção) | `social` | `AppTopBar`, `EmptyState`, `AppStaggeredListItem`, `ReviewSummaryTile` | `FeedController` | `feedControllerProvider` | — | — | `reviews`, `followers` | Nenhuma nova |
| F29 XP automático | `gamification`, `events`, `event_reviews` | — (backend) | — | — | `award_gamification_points()`, `award_badge()` | Padrão de `handle_gamification_new_review/comment/like` como modelo | `event_attendances`, `event_reviews`, `user_progress`, `user_badges` | Nenhuma tabela nova — só 1-2 migrations de trigger |
| F30 Badges de grupo | `gamification` | `AppBadge` | — | — | `award_badge()` | Depende de F29 | `badges`, `user_badges` | Possível seed de novos badges (`badges` já tem `code`/`name`/`description`) |
| F35 Deep link | `groups` | `JoinGroupPage` (form já existe como fallback) | `JoinGroupController` | `joinGroupControllerProvider` | `join_group_by_invite_code()` | — | `groups` (`invite_code`) | Nenhuma — é infraestrutura de plataforma (App Links/Universal Links), não schema |
| F41 Notificação avaliação liberada | `notifications`, `event_reviews`, `events` | — (backend) | — | — | `create_notification()`, `can_review_event()` | Padrão de `notify_event_attendance_response`/`notify_new_event` como modelo | `notifications`, `event_attendances`, `events` | 1 migration de trigger novo |
| F46 GroupCard/EventCard | `restaurants` (`RestaurantCard` como referência de padrão) | `RestaurantCard` (padrão de composição a seguir) | — | — | — | — | — | — (é componente Flutter, não schema) |
| F02 Login Google | `authentication` | `AppPrimaryButton`/`AppOutlinedButton` (para o botão) | `AuthController` | `authControllerProvider` | `signInWithGoogle()` | — | — | — |
| F09 Perfil redesenhado | `gamification`, `rankings` | `AppCard` | `GamificationProfileController` (dado de nível/XP) | `gamificationProfileControllerProvider` | — | — | — | — |
| F13 Descoberta guiada | `favorites`, `events`, `groups` | `RestaurantCard` | `FavoritesController` (padrão de query) | — | — | — | `favorites`, `group_members`, `events` | Nenhuma nova — é query nova sobre dado existente |
| F48 Preferências completas | `notifications` | `SwitchListTile` (padrão já usado 1x) | `NotificationPreferencesController` | `notificationPreferencesControllerProvider` | `NotificationPreferenceRepository` | — | `notification_preferences` (`category='groups'` já suportada) | Já atendida por `20260801130000_add_group_event_notifications.sql` |
| F14+F39 Galeria/Álbum | `reviews` (fotos já existem) | Estrutura de tira de fotos de `review_detail_page.dart` como referência | `ReviewDetailController` (`addPhoto`, `maxReviewPhotos`) | — | Bucket `review-photos` já existe | — | `reviews` (photos), possível extensão de `event_reviews` | Depende de decisão em §6 |
| F16 Avaliação por categorias | `event_reviews` (já implementado, usar como modelo) | `SubmitEventReviewPage` como referência direta de UI | `SubmitEventReviewController` como referência de padrão | — | — | `recalculate_event_rating` como modelo de agregação | `reviews` (precisaria de novas colunas) | Nenhuma — precisaria de migration nova, mas o **padrão** já está validado em produção via `event_reviews` |
| F36 Rodízio/sorteio | `groups`, `events` | — | `GroupDetailController`/`CreateEventController` como pontos de integração | — | — | — | `groups`, `group_members` (precisaria de coluna de rastreamento) | Nenhuma — precisa de 1 migration pequena |
| F44/F45 Memórias expandidas | `events` | Cards de Memórias já existentes em `events_list_page.dart` | `EventsListController` (estender a query) | — | — | — | `events`, `event_attendances`, `event_reviews` | Nenhuma nova — é query nova sobre dado existente |

**Leitura desta tabela**: dos 15 itens cobertos, **9 não exigem nenhuma tabela nova e a maioria não exige nenhuma migration nova** — o trabalho é majoritariamente trigger novo (reaproveitando função já pronta) ou composição de UI (reaproveitando componente/controller já pronto). Isso confirma, em escala, o achado já antecipado no UX Audit §10 (Matriz de Reutilização): o BORAH tem uma base de "motores genéricos" e componentes prontos maior do que o produto atualmente usa.

---

## 5. Análise profunda das funcionalidades candidatas

As 18 funcionalidades pedidas nesta fase, analisadas uma a uma. Vários pares se consolidam em uma única iniciativa (ver justificativa de cada uma) — isso já antecipa a resposta da §6 (não aceitar duplicação).

### 5.1 Cadastro inteligente de restaurantes / Google Places / Autocomplete
Tratadas como **uma única funcionalidade** (F12) — os 3 nomes descrevem a mesma iniciativa em granularidades diferentes ("cadastro inteligente" é o resultado, "Google Places" é a fonte de dado, "Autocomplete" é o mecanismo de UI). Objetivo: eliminar o gargalo de digitação manual confirmado como o maior do produto (UX Audit §2.4). Fluxo: usuário digita 3+ caracteres → autocomplete sugere lugares reais → seleção preenche nome/categoria/endereço/lat-long/foto automaticamente → usuário confirma. Dependência real: conta Google Cloud + billing configurado (não é decisão de código, é decisão operacional/financeira do usuário) — **recomendação estratégica em §12**: começar restrito a cadastro de restaurante novo, não retroalimentar os restaurantes já cadastrados manualmente na primeira etapa (reduz escopo e risco).

### 5.2 Feed automático
Distinto do Feed atual (F24, que mostra reviews de quem o usuário segue). "Feed automático" (F25) é um conceito novo: atividade do **grupo** — rolês criados, avaliações coletivas enviadas, novos membros — aparecendo como um fluxo cronológico, sem que ninguém precise "postar" nada manualmente (é automático porque nasce de ações que já acontecem, não de um "criar publicação"). Isso é coerente com a intenção original do produto (`ET-09_FEED_AND_SHARING.md`, mesmo que pré-pivô) adaptada ao modelo de Grupos. Fonte de dado recomendada: a própria tabela `notifications` já registra exatamente esses eventos por usuário — uma variante de feed poderia ser "as notificações do grupo, em formato de linha do tempo compartilhada", evitando construir uma segunda fonte de verdade paralela (ver §6).

### 5.3 Galeria automática (de restaurante)
(F14) Fotos que os usuários já anexam em `reviews` (até 5 por avaliação, já implementado) agregadas visualmente na tela de detalhe do restaurante — hoje essas fotos só existem "presas" dentro de cada review individual, nunca vistas em conjunto. Não requer nenhuma tabela nova — é uma query de agregação (`select photo urls from reviews where restaurant_id = X`) mais um grid de exibição.

### 5.4 Álbum do rolê
(F39) Conceito irmão do anterior, mas escopado ao encontro (rolê), não ao restaurante — fotos coletivas de quem participou. **Recomendação estratégica (§12, aprofundada aqui)**: `event_reviews` hoje **não tem suporte a foto** (confirmado, schema não tem coluna equivalente a `photos_count`/bucket dedicado para avaliação coletiva). Construir um "álbum do rolê" do zero, separado da galeria de restaurante, duplicaria a mesma infraestrutura (upload, bucket, grid de exibição) que F14 já usa. **Recomendo tratar F14+F39 como uma única funcionalidade de Galeria**, parametrizada por escopo (restaurante ou rolê), com a extensão de schema necessária (permitir foto em `event_reviews`, reaproveitando o mesmo padrão de bucket/coluna já usado em `reviews`) feita uma vez só.

### 5.5 Avaliação por categorias
(F16) Já existe e funciona bem para `event_reviews` (5 critérios: comida/atendimento/ambiente/custo-benefício/geral) — a pergunta real é se `reviews` (avaliação individual de restaurante, hoje nota única) deveria adotar o mesmo modelo, unificando a experiência de "avaliar" em todo o app (ligação direta com a Oportunidade Estratégica #6 do UX Audit — unificar recompensa/experiência entre os 2 sistemas de avaliação). Recomendo tratar como uma extensão de schema em `reviews`, usando `SubmitEventReviewPage` como referência de UI já validada em produção, não uma funcionalidade construída do zero.

### 5.6 Novo Perfil
(F09) Já coberto em detalhe no Design Gap §1.4 — não é reconstrução da tela, é enriquecimento dos atalhos existentes com prévia de dado (nível/XP visível no atalho de Gamificação, por exemplo). Baixa complexidade, dado já existe.

### 5.7 Novo Ranking / Ranking Global / Ranking Grupo
Estes 3 nomes, analisados com cuidado, **não representam uma funcionalidade ausente** — Ranking Global (F22, ranking de usuários) e Ranking do Grupo (F42) já existem e funcionam. **Achado desta análise, relevante para §6**: o "Novo Ranking" que o usuário provavelmente tem em mente já é integralmente coberto pela unificação "Meu Grupo" (F23, já classificada Core) — construir qualquer coisa adicional chamada "Novo Ranking" seria duplicar uma solução que já está no escopo. **Recomendo não criar nenhuma funcionalidade nova aqui além de F23.**

### 5.8 Sistema de sorteio
(F36) Mapeia diretamente ao "rodízio automático de escolha" já identificado no UX Audit (Oportunidade #10) e no Product Audit (§2.9, ET-05 nunca implementado). Nome "sorteio" sugere um mecanismo de aleatoriedade — importante decidir, como parte do escopo, se é (a) sugestão baseada em rodízio justo (quem não escolhe há mais tempo) ou (b) aleatório de verdade entre os membros elegíveis. **Recomendação estratégica em §12**: qualquer que seja a regra, deve permanecer uma **sugestão, nunca uma trava** (consistente com o princípio "nunca obrigatoriedade" já estabelecido na Matriz de Engajamento do UX Audit §11) — o grupo sempre pode escolher manualmente por cima da sugestão.

### 5.9 Memórias automáticas
(F44/F45) "Automáticas" já é como as Memórias funcionam hoje (trigger recalcula a cada mudança, sem intervenção manual) — o gap real não é automação, é **cobertura de métrica**: hoje só 2 de N métricas prometidas existem. Expandir é estender a mesma query, sem mudança de mecanismo.

### 5.10 XP automático
(F29) O item de maior impacto confirmado em todas as 4 fases anteriores. Já detalhado extensivamente no §1/§3/§4 — é a conexão de `award_gamification_points()` a `event_attendances`/`event_reviews` via 2 triggers novos, reaproveitando 100% da função central já existente e testada em produção.

### 5.11 Badges automáticos
(F30) Extensão direta de F29 — uma vez que XP passe a ser concedido por atividade de grupo, `award_badge()` (já genérica) pode checar novos critérios (ex.: "presença perfeita" usando o dado já existente em `group_members.declined_count`). Não é uma funcionalidade separada de infraestrutura, é um conjunto de novos badges definidos sobre a mesma mecânica.

### 5.12 Comentários
(F18) Já existe, funciona, tem moderação (denúncia) — nenhuma lacuna encontrada nesta análise além do que já foi coberto no UI Audit (tooltip do menu de ações).

### 5.13 Compartilhamento
(F27) Já existe (convite de grupo via `share_plus`, botão de compartilhar review) — a única lacuna relacionada é indireta: o compartilhamento de convite hoje gera **texto**, não um link clicável (é exatamente o que F35, Deep Link, resolve). Não é uma funcionalidade nova separada, é uma melhoria de F35.

### 5.14 Descoberta de restaurantes
(F13) Distinta de F12 (Google Places, que melhora a qualidade do dado) — esta é sobre **usar dado que já existe** (favoritos do grupo, restaurantes ainda não visitados) para sugerir, principalmente no fluxo de Criar Rolê. Zero infraestrutura nova de dado, só uma query cruzando tabelas já existentes.

---

## 6. Não aceitar duplicação — onde integrar em vez de construir

Respondendo diretamente à pergunta do usuário: **sim, várias das funcionalidades "novas" nascem só de conectar peças que já existem.**

1. **F14 (Galeria) + F39 (Álbum do rolê) → 1 funcionalidade só.** Ambas são "grade de fotos agregadas", diferindo só no escopo (restaurante vs. rolê). Construir 2 sistemas separados duplicaria upload/bucket/grid. Ver §5.4.
2. **F22/F42 (Rankings existentes) + "Novo Ranking"/"Ranking Global"/"Ranking Grupo" → nenhuma funcionalidade nova além de F23 (Meu Grupo).** Os rankings já existem; o que faltava era visibilidade, não uma nova funcionalidade. Ver §5.7.
3. **F25 (Feed automático de grupo) deveria nascer de `notifications`, não de uma segunda fonte de eventos paralela.** A tabela `notifications` já registra, por usuário, exatamente os eventos que um "feed de grupo" mostraria (novo rolê, resposta de presença, novo membro) — em vez de criar uma tabela de "eventos de feed" nova, uma visão que agrupa `notifications` por grupo (não por usuário destinatário) evita duplicar a fonte de verdade.
4. **F30 (Badges automáticos) não precisa de nenhuma tabela nova** — nasce inteiramente de conectar F29 (que já cria o gatilho de XP) a `award_badge()` (já genérica). Tratar como funcionalidade separada de infraestrutura seria duplicar trabalho.
5. **F16 (Avaliação por categorias em Reviews) deveria reusar a UI de `SubmitEventReviewPage` como padrão**, não desenhar um formulário de 5 campos do zero — o padrão já existe, validado em produção.
6. **F13 (Descoberta guiada) e F35 (Deep link) não geram nenhuma tela nova** — a primeira é uma seção a mais dentro de `create_event_page.dart`/`restaurants_search_page.dart` (usando `RestaurantCard`, já existente); a segunda reaproveita `JoinGroupPage`/`join_group_by_invite_code()` já prontos, só muda a porta de entrada.
7. **F02 (Login Google) é 100% front-end** — o backend (`signInWithGoogle()`) já existe e nunca precisou de nenhum trabalho de integração nova.

**Princípio consolidado para a FASE 6/Implementação**: antes de qualquer funcionalidade nova ser desenhada como "do zero", checar primeiro se um controller/RPC/trigger/tabela já resolve 80% do problema — o padrão repetido nesta fase (e nas 4 anteriores) é que o BORAH tem mais infraestrutura pronta do que interface conectada a ela.

---

## 7-8-9. Impacto no Banco, no Flutter e no Produto — tabela consolidada

Cobre os itens Core/Muito importante/Importante (os itens Opcional/Futuro/Descartar não precisam desta análise nesta rodada, por não estarem no escopo imediato do BORAH 2.0).

| Funcionalidade | Migration? | Trigger? | RLS? | Edge Function? | Storage? | Telas que mudam | Telas novas | Telas que desaparecem | Componentes novos | Valor entregue / dimensão de produto que aumenta |
|---|---|---|---|---|---|---|---|---|---|---|
| F23 Meu Grupo | Não | Não | Não | Não | Não | `group_ranking_page`, `group_stats_page` (fundidas) | 1 (a nova "Meu Grupo", substitui as 2) | 2 (as antigas, absorvidas) | Componente de Tabs | Retenção, competição saudável percebida |
| F24 Feed (correção) | Não | Não | Não | Não | Não | 1 tela (onde o botão de entrada for adicionado — a decidir) | Não (já existe) | Não | Não | Descoberta social, tempo de uso |
| F29 XP automático | Sim (trigger) | **Sim, 2 novos** | Não (usa RLS já existente) | Não | Não | `gamification_profile_page` (passa a mostrar mais XP) | Não | Não | Não | Engajamento, retenção, avaliações, criação de rolês |
| F30 Badges de grupo | Sim (seed de novos badges) | Não (reusa F29) | Não | Não | Não | `gamification_profile_page` | Não | Não | Não | Engajamento |
| F35 Deep link | Não (schema) | Não | Não | Não | Não | `join_group_page` (alcançável por rota nova) | Não | Não | Não | Criação/entrada em grupos (canal de aquisição) |
| F41 Notificação avaliação liberada | Sim (trigger) | **Sim, 1 novo** | Não | Não | Não | Nenhuma tela muda visualmente — só passa a existir uma notificação nova | Não | Não | Não | Avaliações, retenção |
| F46 GroupCard/EventCard | Não | Não | Não | Não | Não | `groups_list_page`, `events_list_page` | Não | Não | Sim, 2 (`GroupCard`, `EventCard`) | Pertencimento, tempo de uso, descoberta |
| F02 Login Google | Não | Não | Não | Não | Não | `login_page` | Não | Não | Não (reuso de botão existente) | Redução de fricção de cadastro |
| F09 Perfil redesenhado | Não | Não | Não | Não | Não | `profile_page` | Não | Não | Não (reuso de `AppCard`) | Engajamento com Gamificação |
| F12 Google Places | Talvez (se novos campos como telefone/horário forem adotados) | Não | Não | **Possível** (proxy de chamada à API, para não expor a chave no cliente) | Não | `create_restaurant_page` | Não | Não | Componente de autocomplete | Qualidade de dado, descoberta, criação de rolês (menos fricção) |
| F13 Descoberta guiada | Não | Não | Não | Não | Não | `create_event_page`, `restaurants_search_page` | Não | Não | Não (reuso de `RestaurantCard`) | Descoberta de restaurantes, criação de rolês |
| F25 Feed automático de grupo | Talvez (view agregada) | Não | Sim (nova policy de leitura por grupo) | Não | Não | Nova seção dentro de `events_list_page` ou tela própria (a decidir) | Possivelmente 1 | Não | Não | Pertencimento, tempo de uso |
| F48 Preferências completas | Não | Não | Não | Não | Não | `notification_preferences_page` | Não | Não | Não | Retenção (menos opt-out por ruído) |
| F14+F39 Galeria unificada | Sim (permitir foto em `event_reviews`) | Não | Sim (policy de storage para o novo escopo) | Não | Sim (extensão de bucket/policy) | `restaurant_detail_page`, `event_detail_page` | Possivelmente 1 (galeria em tela cheia) | Não | Grid de galeria (novo) | Memória, descoberta, avaliações (incentivo a fotografar) |
| F16 Avaliação por categorias | Sim (novas colunas em `reviews`) | Sim (ajustar `recalculate_restaurant_rating`) | Não | Não | Não | `create_review_page`, `edit_review_page`, `review_detail_page` | Não | Não | Não (reuso do padrão de `SubmitEventReviewPage`) | Avaliações, qualidade de dado de ranking |
| F36 Rodízio/sorteio | Sim (coluna de rastreamento) | Talvez (ou lógica em `create_event()`) | Não | Não | Não | `create_event_page` (seção de sugestão) | Não | Não | Não | Criação de rolês, pertencimento |
| F44/F45 Memórias expandidas | Não | Não | Não | Não | Não | `events_list_page` (mais cards) | Não | Não | Não | Memória, retenção |

---

## 10. Matriz de Priorização

| Funcionalidade | Valor | Esforço | Risco | Dependências | Complexidade | ROI | Prioridade |
|---|---|---|---|---|---|---|---|
| F29 XP automático | Altíssimo | Baixo | Baixo | Nenhuma | Baixa | **Altíssimo** | **P0** |
| F41 Notificação avaliação liberada | Altíssimo | Baixo | Baixo | Nenhuma | Baixa | **Altíssimo** | **P0** |
| F23 Meu Grupo | Altíssimo | Médio | Médio (mexe em rotas existentes) | Componente de Tabs | Média | Alto | **P0** |
| F46 GroupCard/EventCard | Alto | Médio | Baixo-médio | Nenhuma | Média | Alto | **P0** |
| F35 Deep link de convite | Alto | Médio | Baixo (aditivo, fallback continua) | App Links/Universal Links (infra de plataforma) | Média | Alto | **P0** |
| F24 Feed (verificar/corrigir) | Alto (se confirmado) | Muito baixo | Muito baixo | Nenhuma | Baixa | **Altíssimo** (se confirmado) | **P0 (verificação); P1 (correção)** |
| F02 Login Google | Médio | Muito baixo | Muito baixo | Nenhuma | Baixa | Alto | P1 |
| F09 Perfil redesenhado | Alto | Baixo | Baixo | Nenhuma | Baixa | Alto | P1 |
| F48 Preferências completas | Médio | Muito baixo | Muito baixo | Nenhuma | Baixa | Alto | P1 |
| F30 Badges de grupo | Alto | Baixo | Baixo | F29 | Baixa | Alto | P1 |
| F13 Descoberta guiada | Alto | Médio | Baixo | Nenhuma | Baixa-média | Alto | P1 |
| F12 Google Places | Alto | Alto | Médio (dependência externa paga) | Conta Google Cloud + billing | Média-alta | Médio-alto | P1 |
| F14+F39 Galeria unificada | Médio-alto | Médio | Baixo-médio | Extensão de schema em `event_reviews` | Média | Médio-alto | P2 |
| F16 Avaliação por categorias | Médio | Médio | Médio (migração de dado existente) | Nenhuma | Média | Médio | P2 |
| F25 Feed automático de grupo | Médio-alto | Médio-alto | Médio | Decisão de fonte de dado (§6) | Média-alta | Médio | P2 |
| F44/F45 Memórias expandidas | Médio | Baixo | Baixo | Nenhuma | Baixa | Médio-alto | P2 |
| F36 Rodízio/sorteio | Médio | Médio | Baixo | Decisão de regra de negócio | Média | Médio | P2 |
| F07 @username | Baixo | Médio | Baixo | Nenhuma | Média | Baixo | P3 |
| F21 Desempate de ranking | Baixo | Baixo | Baixo | Nenhuma | Baixa | Baixo | P3 |
| F08 Privacidade de perfil | Baixo (hoje) | Médio-alto | Médio (RLS em múltiplas tabelas) | Nenhuma | Média-alta | Baixo | Futuro |
| F31 Desafios | Médio | Alto | Médio | Nenhuma | Alta | Baixo-médio | Futuro |
| F32 Temporadas | Médio | Alto | Médio | Nenhuma | Alta | Baixo-médio | Futuro |
| F49 Push (FCM) | Alto (a longo prazo) | Alto | Médio | Decisão de escopo já adiada | Alta | Médio | Futuro |

---

## 11. FUNCIONALIDADES OFICIAIS DO BORAH 2.0

**Esta é a definição oficial do escopo do produto. Nada entrará na implementação sem aparecer nesta lista.**

### Core (obrigatório para o BORAH 2.0 ser considerado completo)
1. **F29 — XP automático para Grupos/Rolês/Avaliação Coletiva**
2. **F41 — Notificação de avaliação liberada**
3. **F23 — "Meu Grupo" (Ranking + Estatísticas + Memórias unificados)**
4. **F46 — Componentes `GroupCard`/`EventCard`**
5. **F35 — Deep link de convite de grupo**
6. **F24 — Verificação e correção do ponto de entrada do Feed**

### Muito importante (compõe a experiência BORAH 2.0 completa, entra na mesma leva de planejamento que o Core)
7. **F02 — Botão de Login com Google**
8. **F09 — Perfil redesenhado (atalhos com prévia de dado)**
9. **F48 — Preferências de notificação completas (categoria Grupos)**
10. **F30 — Badges automáticos de atividade de grupo**
11. **F13 — Descoberta de restaurantes guiada pelo grupo**
12. **F12 — Cadastro inteligente de restaurantes via Google Places**

### Importante (planejado para o BORAH 2.0, mas pode ceder espaço em caso de restrição de tempo)
13. **F14+F39 — Galeria de fotos unificada (restaurante + rolê)**
14. **F16 — Avaliação por categorias em `reviews`**
15. **F25 — Feed automático de atividade de grupo**
16. **F36 — Sistema de rodízio/sorteio de escolha**
17. **F44+F45 — Memórias expandidas**

### Opcional (fica de fora do escopo formal do BORAH 2.0, mas não é descartado — pode entrar se houver capacidade)
18. F07 — @username único
19. F21 — Desempate de ranking (4 níveis)

### Futuro (explicitamente fora do BORAH 2.0, decisão a revisitar em uma próxima rodada de produto)
20. F08 — Privacidade de perfil
21. F31 — Desafios diário/semanal/sazonal
22. F32 — Temporadas de grupo
23. F49 — Push notifications (FCM)

### Descartar (não implementar, decisão já justificada nas fases anteriores)
- Check-in físico geolocalizado (substituído, funciona bem como está)
- Nomenclatura "Wrapped" (já renomeada para "Memórias")
- Backend NestJS/Prisma (arquitetura obsoleta, Supabase é definitivo)
- Bottom nav antiga sem aba Grupos (já substituída)

---

## 12. Recomendações Estratégicas

Oportunidades identificadas nesta fase que são **melhores ou mais eficientes** do que a lista original de 18 itens sugeria, documentadas para decisão do usuário — nada foi implementado.

1. **Consolidar F29+F30+F41 em uma única entrega técnica** ("Fechamento do motor social do cluster Grupos/Rolês"), não 3 iniciativas separadas. As 3 tocam as mesmas tabelas (`event_attendances`, `event_reviews`) e a mesma dupla de funções centrais (`award_gamification_points()`/`create_notification()`) — planejá-las juntas reduz o risco de entregar "XP sem notificação" ou vice-versa, um estado intermediário incoerente.
2. **F14+F39 devem nascer como uma única funcionalidade de Galeria**, não duas — ver §5.4/§6. Construir separadamente duplicaria upload/bucket/grid.
3. **"Novo Ranking"/"Ranking Global"/"Ranking Grupo" não devem virar nenhuma funcionalidade nova além de F23** — os rankings já existem, o gap era só visibilidade (ver §5.7). Recomendo que a FASE 6/Implementação trate esses 3 nomes como já resolvidos por F23, evitando um retrabalho que pareceria "novo" mas seria puramente redundante.
4. **F12 (Google Places) deveria ser faseado**: primeira etapa restrita a cadastro de restaurante novo (menor escopo, menor risco); retroalimentar os restaurantes já cadastrados manualmente com dado do Places deveria ser uma decisão separada e posterior, não parte do mesmo pacote de trabalho — misturar os dois aumenta a superfície de risco sem aumentar o valor da primeira entrega.
5. **F36 (Rodízio/sorteio) deve ser desenhado como sugestão, nunca como trava** — o nome "sorteio" carrega risco de ser interpretado como um mecanismo obrigatório/automático que decide por cima da vontade do grupo; isso contradiz o princípio "nunca obrigatoriedade" já estabelecido no UX Audit §11 (Matriz de Engajamento) e deveria ser um guardrail explícito de qualquer especificação futura desta funcionalidade.
6. **F25 (Feed automático de grupo) deveria ser construído sobre `notifications`, não sobre uma fonte de eventos paralela nova** — ver §6, item 3. Isso é uma recomendação de arquitetura de dado que reduz complexidade e risco de divergência entre "o que o feed mostra" e "o que as notificações já sabem".
7. **F24 (verificação da entrada do Feed) deveria ser a primeiríssima ação da FASE de implementação**, antes até de qualquer outro item Core — é a verificação mais barata de toda esta lista (uma busca de código) e, se confirmada, destrava uma funcionalidade inteira que já está pronta e paga, sem nenhum custo de desenvolvimento novo.

---

**Aguardando revisão do usuário antes de prosseguir para `RC03_IMPLEMENTATION_PLAN.md`.**
