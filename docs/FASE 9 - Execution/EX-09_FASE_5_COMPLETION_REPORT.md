# EX-09 --- Relatório de Encerramento da FASE 5 (Desenvolvimento)

**Versão:** 1.0\
**Status:** Concluído\
**Documento:** `EX-09_FASE_5_COMPLETION_REPORT.md`\
**Data de encerramento:** 2026-07-20

------------------------------------------------------------------------

# 1. Objetivo

Registrar o encerramento formal da FASE 5 (Desenvolvimento) do EX-02 ---
Development Roadmap, consolidando os módulos entregues, as decisões
arquiteturais relevantes, as lacunas documentais identificadas e as
dependências adiadas por ausência de infraestrutura.

------------------------------------------------------------------------

# 2. Módulos implementados (DV-01 a DV-10)

| Módulo | Escopo | Commit (branch) |
|---|---|---|
| DV-01 | Authentication - Supabase Auth, sessão, proteção de rotas | `a305827` (`feature/dv-01-authentication-module`) |
| DV-02 | Users - perfil, avatar (bucket privado) | `9e8c2ac` (`feature/dv-02-users-module`) |
| DV-03 | Restaurants - cadastro colaborativo, busca, capa (bucket público) | `bff092c` (`feature/dv-03-restaurants-module`) |
| DV-04 | Reviews - avaliação por restaurante, curtidas, fotos | `bf70a1c` (`feature/dv-04-reviews-module`) |
| DV-05 | Rankings - sem tabela própria, projeção sobre `restaurants` | `a177c9a` (`feature/dv-05-rankings-module`) |
| DV-06 | Favorites - favoritar/desfavoritar com atualização otimista | `a8c64a3` (`feature/dv-06-favorites-module`) |
| DV-07 | Social - seguidores, comentários, denúncias, feed, compartilhamento | `5143a4d` (`feature/dv-07-social-module`) |
| DV-08 | Administration - RBAC, moderação, auditoria (exceção documentada ao AR-13) | `72074a2` (`feature/dv-08-administration-module`) |
| DV-09 | Notifications - central in-app gerada via trigger, sem Push | `b6cf40c` (`feature/dv-09-notifications-module`) |
| DV-10 | Gamification - XP, níveis, badges, ranking de usuários | `96908fd` (`feature/dv-10-gamification-module`) |

Todos os 10 módulos seguiram o mesmo processo: leitura da documentação →
identificação de dependências → identificação de infraestrutura
reutilizável → apresentação do plano → aprovação → implementação →
autorrevisão → Code Review Final → aprovação → merge para `develop`.

------------------------------------------------------------------------

# 3. Decisões arquiteturais relevantes

- **ADR-0001** (Supabase como backend oficial) permanece a decisão
  fundacional de todo o desenvolvimento.
- **Sem camada de use case** - fluxo direto `Repository → Controller` em
  todos os módulos (decisão do DV-01, mantida até o DV-10).
- **Sealed classes com prefixo por módulo** para estados de tela,
  evitando colisão entre módulos (`AuthStatus`, `RestaurantsStatus`,
  `ReviewDetailStatus` etc.) e com o próprio SDK/Flutter (`AppNotification`
  em vez de `Notification`; `GamificationBadge` em vez de `Badge`).
- **Exclusão lógica (`deleted_at`)** como padrão para conteúdo com valor
  (`reviews`, `comments`); **`ON DELETE CASCADE`** para relações
  descartáveis sem valor próprio (`review_likes`, `favorites`, `followers`).
- **Extensão controlada de repositórios já mesclados** em vez de
  duplicar consultas, sempre que a nova necessidade é literalmente a
  mesma entidade com outro filtro (`RestaurantRepository.listRanked`
  no DV-05, `ReviewRepository.listByUser` no DV-07,
  `RestaurantRepository.listAllForAdmin`/`updateAsAdmin` e
  `ReviewRepository.hideAsAdmin` no DV-08).
- **Automação via trigger Postgres em vez de Edge Functions**, de forma
  consistente do DV-04 ao DV-10 (`recalculate_restaurant_rating`,
  `create_notification`, `award_gamification_points` etc.) - decisão
  repetida porque a infraestrutura de Edge Functions nunca chegou a
  existir no projeto (AR-09 permanece fechado sem código).
- **Exceção documentada ao AR-13** (DV-08): operações administrativas
  sobre dados de aplicação autorizadas via RLS baseada em papel
  (`is_admin`/`has_admin_role`/`can_moderate`), não via Edge Function -
  não se estende a operações sobre o Supabase Auth.
- **Decisão consciente de duplicação** quando extrair uma dependência
  cruzaria a fronteira de um módulo sem benefício líquido
  (`FavoriteRepositoryImpl._mapRestaurantRow` duplica
  `RestaurantRepositoryImpl._mapRow`; `FeedRepositoryImpl`/
  `FollowerRepositoryImpl` idem) - preferido a acoplar Favorites/Social
  aos repositórios de Restaurants/Reviews.
- **Extração de padrões apenas na 3ª ocorrência real**, nunca antes:
  `ReviewSummaryTile` (DV-07) foi extraído nesse critério; o padrão
  "buscar ids → buscar relacionados → preservar ordem" permanece como
  observação registrada (2ª ocorrência no DV-10), não extraído.

------------------------------------------------------------------------

# 4. Lacunas documentais registradas (não resolvidas, apenas registradas)

| Divergência | Documentos | Resolução adotada |
|---|---|---|
| Modelo de avaliação por evento vs. por restaurante | ET-08 vs. DV-04 | DV-04 prevalece (mais específico e aprovado) |
| Modelo de comentários por post/evento vs. por avaliação | ET-09 vs. DV-07 | DV-07 prevalece |
| Quantidade de papéis administrativos (2 vs. 4) | ET-12 vs. DV-08 | DV-08 prevalece |
| Conceito de "Temporada/Season" (3 modelos físicos, 2 donos) | ET-02, ET-05, ET-08, ET-13 | Nenhum DV v1.0 depende disso; reconciliar só quando houver consumidor real (Grupos ou Gamificação v2.0) |
| Quantidade de ambientes (3, 5 e agora 4 variações) | AR-06/12 (3), AR-17 (5), DV-11 §11 (4) | Não reconciliado; aguardando ambientes reais |
| Fotos de avaliação sem tabela própria | DV-04 §9 | Resolvido via listagem do bucket, sem tabela nova |
| "Curtidas sociais" sem tabela própria | DV-07 §2 vs. §9 | Satisfeito pelo `review_likes` já existente (DV-04) |
| "Missões"/"Desafios"/"Recompensas" sem modelo, e fora do próprio v2.0 | DV-10 §2/§5/§6/§17/§18 vs. §9/§19 | Não implementado, não é v2.0 - lacuna documental genuína |
| "Aprovar cadastro" de restaurante vs. criação direta como `active` | DV-08 §6 vs. DV-03 | DV-03 prevalece; "aprovar cadastro" fora de escopo |

------------------------------------------------------------------------

# 5. Dependências adiadas por ausência de infraestrutura (nenhuma implementada especulativamente)

- **Projeto Supabase real** (AR-06) - bloqueia testes de integração, E2E,
  segurança de RLS/RBAC contra instância real, e qualquer validação
  além da revisão estática das migrações.
- **Edge Functions** (AR-09) - bloqueia bloqueio de usuário (Supabase
  Auth Admin API/Service Role Key), envio real de Push (DV-09),
  exportação assíncrona (DV-08), e qualquer operação que exigisse
  privilégio além de RLS.
- **Push Provider (Firebase)** - bloqueia a metade "Push" do DV-09;
  apenas In-App foi implementado.
- **MFA para administradores** (DV-08 §12) - sem infraestrutura de MFA
  configurada.
- **Ambientes QA/Staging/Production** - existe apenas desenvolvimento
  local; bloqueia testes de performance e os ambientes citados no DV-11.
- **DV-12 (Release & Publishing) inteiro** - contas nas lojas,
  certificados/keystores, Crashlytics/Sentry, pipeline de publicação -
  nenhum artefato de código, fechado com o mesmo critério do AR-16.
- **Categorias/gerenciamento de categorias de restaurante** (DV-08) -
  sem tabela de categorias, `category` permanece texto livre.
- **Moderação de fotos** (DV-08) - sem fila de denúncia para fotos.
- **Ranking Mensal e "Missões/Desafios/Recompensas"** (DV-10) - sem
  histórico temporal nem modelo de dados, respectivamente.

------------------------------------------------------------------------

# 6. Métricas finais

- **Módulos de funcionalidade entregues:** 10 (DV-01 a DV-10)
- **Migrações SQL criadas:** 21
- **Testes unitários:** 117, todos passando (`flutter test`: `117/117`)
- **Cobertura:** habilitada no CI (`flutter test --coverage` +
  `coverage/lcov.info` publicado via `actions/upload-artifact@v4`) -
  sem percentual-alvo medido nesta fase, sem serviço externo de
  cobertura (Codecov/SonarCloud) integrado
- **`flutter analyze`:** sem problemas em toda a FASE 5
- **Feature branches criadas até o fim da FASE 5:** 13 (`feature/ar-06-...`,
  `feature/ar-12-...`, `feature/dv-01-...` a `feature/dv-11-dv-12-closure`) -
  todas mantidas vivas, nenhuma excluída. (Uma 14ª,
  `feature/fase-5-completion-report`, foi criada depois, só para este
  próprio relatório - não contabilizada acima porque não existia
  enquanto `develop` estava em `af4a805`.)
- **`develop`:** avançou de `6702de0` (último commit da FASE 4,
  `feature/ar-12-secrets-management`) até `af4a805` (fim da FASE 5) via
  **11 merges fast-forward** - um por módulo (DV-01 a DV-10) mais o
  fechamento do DV-11/DV-12. Os merges de `ar-06`/`ar-12` (`fdf9bbb`,
  `6702de0`) antecedem esse intervalo: são FASE 4, não FASE 5, mesmo
  tendo ocorrido cronologicamente depois de `3a37f0f`.
- **`main`:** intocada em `3a37f0f` desde o fim da FASE 4 - nenhuma
  promoção para produção ocorreu durante toda a FASE 5 (decisão
  consistente: `main` só recebe merge mediante aprovação explícita
  separada, ainda não solicitada)

------------------------------------------------------------------------

# 7. Estado para Retomada

- **Branch principal de desenvolvimento:** `develop`
- **Último commit estável:** conteúdo consolidado no commit `57def28`
  (`docs(ex-09): fix merge count and add Estado para Retomada section`);
  um commit adicional apenas ajusta esta própria referência de hash
  (sem mudança de conteúdo) antes do merge por fast-forward para
  `develop` - o HEAD de `develop` após a aprovação deste relatório é o
  commit estável de referência.
- **Fase concluída:** FASE 5 --- Desenvolvimento
- **Próxima fase do roadmap:** FASE 6 --- QA (EX-02 §4)
- **Data da última atualização da SSOT:** 2026-07-20

------------------------------------------------------------------------

# 8. Encerramento

Com a aprovação deste relatório, a **FASE 5 --- Desenvolvimento** é
considerada oficialmente encerrada, com uma arquitetura consistente,
baixo acoplamento entre módulos, documentação de decisões preservada na
memória do projeto e no histórico de commits, e sem dívidas técnicas
introduzidas por implementação especulativa de funcionalidades sem
consumidor ou infraestrutura reais.

A próxima etapa, conforme o EX-02 --- Development Roadmap, é a
**FASE 6 --- QA**, a ser iniciada mediante instrução explícita.
