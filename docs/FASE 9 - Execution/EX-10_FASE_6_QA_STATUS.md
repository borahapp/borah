# EX-10 --- FASE 6 (QA) --- Status de Execução

**Versão:** 1.0\
**Status:** Em andamento\
**Documento:** `EX-10_FASE_6_QA_STATUS.md`

------------------------------------------------------------------------

# 1. Objetivo

Registrar o progresso incremental da FASE 6 (Qualidade). Diferente da
FASE 5 (encerrada de uma vez via
`EX-09_FASE_5_COMPLETION_REPORT.md`), a FASE 6 está sendo executada em
rodadas menores, cada uma aprovada individualmente antes da próxima —
este documento é atualizado a cada rodada concluída, não apenas no
encerramento da fase.

------------------------------------------------------------------------

# 2. FASE 6A --- Diagnóstico (concluído, 2026-07-19/20)

Análise realizada sem gerar artefatos versionados (levantamento, não
implementação). Resultados:

-   **Cobertura real por camada:** Domain 60,9%, Application 71,5%,
    Data 1,6%. A baixa cobertura de `data/` é **estrutural, não uma
    lacuna** — `data/` nunca é testado diretamente por decisão
    arquitetural em vigor desde o DV-01 (a camada é validada
    indiretamente pelos testes de `application/`, que mockam o
    repositório).
-   **Auditoria de segredos:** sem achados.
-   **Fluxos críticos priorizados para Widget Tests:**
    -   Tier 1: Login, Signup, Buscar Restaurantes, Criar Avaliação.
    -   Tier 2 (ainda não iniciado): Favoritar, Editar Perfil, Feed.

------------------------------------------------------------------------

# 3. FASE 6B --- Implementação

## Rodada 1 --- Widget Tests do Tier 1 (concluída, 2026-07-19)

Commit `40201c6` (branch `feature/qa-06-widget-tests-tier1`, mesclada
em `develop` por fast-forward).

-   4 telas cobertas: `LoginPage`, `SignupPage`,
    `RestaurantsSearchPage`, `CreateReviewPage`.
-   Por tela: renderização inicial, validação de formulário, estado de
    carregamento, estado de erro (snackbar), navegação principal,
    responsividade básica (3 tamanhos de viewport) e acessibilidade
    básica (matchers nativos do `flutter_test`:
    `textContrastGuideline`, `labeledTapTargetGuideline`,
    `androidTapTargetGuideline`).
-   **Achado real corrigido durante a rodada:** o `IconButton` de
    adicionar restaurante (`RestaurantsSearchPage`) não tinha rótulo
    semântico — adicionado `tooltip: 'Adicionar restaurante'`.
-   **Explicitamente fora de escopo desta rodada** (decisão do
    usuário, 2026-07-19): `golden_toolkit`, `integration_test`,
    testes de performance/segurança, QA-03/05/07/08. Nenhuma
    dependência nova foi adicionada ao `pubspec.yaml`.
-   **Evolução da suíte de testes:** 117 → **155** testes
    (`flutter test --coverage`, 155/155 aprovados; `flutter analyze` e
    `dart format --set-exit-if-changed .` limpos).

## Rodada 2 --- Tier 2 (concluída — reordenada, ver §5, 2026-07-21)

### Item 1 --- Detalhe do Restaurante (concluído, 2026-07-21)

Commit `377ebc9` (branch `feature/qa-08-widget-tests-restaurant-detail`,
mesclada em `develop` por merge commit `f603240`).

-   11 cenários cobertos em `RestaurantDetailPage`: renderização
    inicial, estado de carregamento, estado de erro, ícone de favorito
    (favoritado e não favoritado), toggle de favorito, navegação para
    "Ver avaliações", responsividade (3 tamanhos) e acessibilidade
    básica. Mesma estratégia do Tier 1 (`ProviderScope` +
    `MaterialApp.router` + mocktail + rotas placeholder), sem
    `golden_toolkit`/`integration_test`.
-   **Achado real corrigido durante a rodada:** o `IconButton` de
    favoritar não tinha rótulo semântico — adicionado
    `tooltip: 'Favoritar restaurante'` (mesma classe de achado já
    corrigida no Tier 1 para o botão "+" de `RestaurantsSearchPage`).
-   **Evolução da suíte:** 169 → **180** testes (`flutter test`,
    180/180 aprovados; `flutter analyze` e
    `dart format --set-exit-if-changed .` limpos).
-   **Cobertura da camada Presentation:** 21,7% → **25,9%**
    (353/1629 → 422/1629 linhas). Application permanece em 75,4%
    (nenhum código de aplicação foi alterado nesta rodada).

### Item 2 --- Detalhe da Avaliação (concluído, 2026-07-21)

Commit `1f6367f` (branch `feature/qa-09-widget-tests-review-detail`,
mesclada em `develop` por merge commit `20f6f1f`).

-   16 cenários cobertos em `ReviewDetailPage`: renderização inicial
    (nota/comentário/curtidas), conteúdo sem comentário, estado de
    carregamento, estado de erro (exibido tanto no corpo quanto via
    snackbar --- divergência intencional em relação a
    `CreateReviewPage`, que usa apenas snackbar), ações do autor
    (Editar/Excluir exibidas apenas quando `review.userId ==
    currentUserId`, ambos os casos), imagens (com fotos + botão
    "Adicionar foto", sem fotos, limite de 5 escondendo o botão),
    toggle de curtida, navegação ("Ver comentários" e "Editar"),
    responsividade (3 tamanhos) e acessibilidade básica. Mesma
    estratégia dos rounds anteriores (`ProviderScope` +
    `MaterialApp.router` + mocktail + rotas placeholder), sem
    `golden_toolkit`/`integration_test`.
-   **Achados reais corrigidos durante a rodada:** os `IconButton`s de
    curtir e de compartilhar não tinham rótulo semântico --- mesma
    classe de achado já corrigida no Tier 1 e no Item 1 deste Tier.
    Adicionado `tooltip` dinâmico ao botão de curtir
    (`'Remover curtida'` / `'Curtir avaliação'`, conforme
    `likedByCurrentUser`) e `tooltip: 'Compartilhar avaliação'` ao
    botão de compartilhar.
-   **Divergência documentada (não corrigida nesta rodada):** DV-04 §5
    lista Data e Autor entre as informações exibidas na avaliação;
    a implementação atual de `ReviewDetailPage` não exibe nenhum dos
    dois campos. Registrado como divergência entre documentação e
    implementação, sem alteração de escopo nesta rodada.
-   **Evolução da suíte:** 180 → **196** testes (`flutter test`,
    196/196 aprovados; `flutter analyze` e
    `dart format --set-exit-if-changed .` limpos).
-   **Cobertura da camada Presentation:** 25,9% → **31,2%**.
    Application permanece em 75,4% (nenhum código de aplicação foi
    alterado nesta rodada).

### Item 3 --- Favoritar (concluído, 2026-07-21)

Commit `dfbae4c` (branch `feature/qa-10-widget-tests-favorites`,
mesclada em `develop` por merge commit `f5f0b4e`).

-   13 cenários cobertos em `FavoritesPage`: renderização inicial,
    estado de carregamento, estado vazio, estado com favoritos, estado
    de erro, busca por nome, filtro por cidade, ordenação (nome),
    navegação para o detalhe do restaurante, estado "syncing"
    (mantendo a lista anterior visível durante uma atualização em
    segundo plano, incluindo o caso de um favorito ser removido na
    sincronização seguinte), responsividade (3 tamanhos) e
    acessibilidade básica. Mesma estratégia dos rounds anteriores
    (`ProviderScope` + `MaterialApp.router` + mocktail + rotas
    placeholder), sem `golden_toolkit`/`integration_test`.
-   **Nenhuma alteração de código de produção foi necessária nesta
    rodada:** a suíte de acessibilidade foi aprovada sem exigir
    ajustes em `FavoritesPage` (diferente do Tier 1 e dos Itens 1 e 2
    deste Tier, que exigiram correções de `tooltip`).
-   **Divergências documentadas (não corrigidas nesta rodada):**
    -   DV-06 §5 lista filtro por "cidade e categoria", mas
        `FavoritesPage` só expõe campo de busca por cidade na UI; o
        parâmetro `category` existe em `FavoritesController` e
        `FavoriteRepository`, mas não tem controle de UI associado.
    -   DV-06 §5 descreve "Remover" (desfavoritar) como ação da lista
        de favoritos, mas a única forma de remover um favorito na
        implementação atual é navegando até `RestaurantDetailPage` e
        usando o ícone de favorito de lá (já coberto pelos testes do
        Item 1 deste Tier); `FavoritesPage` não possui ação de
        remoção direta na própria lista.
    -   `FavoritesController` expõe `refresh()` e `loadNextPage()`
        (estados Syncing/paginação, DV-06 §10/§11), mas `FavoritesPage`
        não tem nenhum gesto de UI (puxar para atualizar, scroll
        infinito) ligado a eles; o cenário "syncing" foi validado
        disparando `refresh()` diretamente via `ProviderContainer`.
-   **Evolução da suíte:** 196 → **209** testes (`flutter test`,
    209/209 aprovados; `flutter analyze` e
    `dart format --set-exit-if-changed .` limpos).
-   **Cobertura da camada Presentation:** 31,2% → **34,9%**
    (569/1631 linhas). Application permanece em 75,4% (nenhum código
    de aplicação foi alterado nesta rodada).

### Item 4 --- Feed (concluído, 2026-07-21)

Commit `fb96bc0` (branch `feature/qa-11-widget-tests-feed`, mesclada
em `develop` por merge commit `7dad437`).

-   10 cenários cobertos em `FeedPage`: renderização inicial/estado de
    carregamento, listagem do feed, estado vazio, estado de erro,
    navegação para o detalhe da avaliação, "puxar para atualizar"
    (`RefreshIndicator` mantendo a lista anterior visível durante a
    atualização em segundo plano, incluindo o caso do feed ficar vazio
    ao concluir), responsividade (3 tamanhos) e acessibilidade básica.
    Mesma estratégia dos rounds anteriores (`ProviderScope` +
    `MaterialApp.router` + mocktail + rotas placeholder), sem
    `golden_toolkit`/`integration_test`. `FeedPage` não possui filtros
    nem ações inline (curtir/comentar/compartilhar ficam em
    `ReviewDetailPage`, já cobertas no Item 2 deste Tier); nenhum
    achado de acessibilidade nesta rodada.
-   **Bug real de produção encontrado e corrigido (autorizado antes da
    implementação):** `FeedController.loadNextPage()` substituía a
    lista inteira pelos itens da página buscada em vez de concatená-
    los aos já carregados, quebrando o "Infinite Scroll" exigido por
    DV-07 §11 --- hoje dormente, pois `FeedPage` não possui nenhum
    gatilho de UI (scroll) que acione `loadNextPage()`. Correção
    mínima: `_run()` passou a aceitar `previousItems` (vazio por
    padrão para `loadForUser`/`refresh`, que continuam substituindo a
    lista inteira; preenchido apenas por `loadNextPage()`, que
    concatena os itens da nova página aos já carregados). Teste de
    regressão adicionado em `feed_controller_test.dart`, confirmado
    falhando antes da correção e aprovado depois.
-   **Divergências documentadas (não corrigidas nesta rodada):**
    -   DV-07 §5 lista "Conquistas da gamificação" como conteúdo do
        Feed sem marcá-la como "(futuro)" (só "Novos favoritos
        públicos" tem essa marca); a implementação exclui gamificação
        e favoritos do Feed por decisão já registrada em comentário no
        código, mas o texto do DV-07 nunca foi atualizado para
        refletir isso.
    -   DV-07 §11 exige "Paginação"/"Infinite Scroll"; `loadNextPage()`
        existe no controller, mas `FeedPage` não tem nenhum gatilho de
        UI (scroll) que o acione.
    -   ET-09 (FASE 2, Draft) descreve um modelo de Feed baseado em
        posts/eventos/grupos/Wrapped já superado pelo DV-07 (FASE 5,
        Approved) --- mesmo padrão de supersessão já visto em rodadas
        anteriores.
-   **Evolução da suíte:** 209 → **220** testes (10 novos Widget Tests
    + 1 novo teste unitário de regressão; `flutter test`, 220/220
    aprovados; `flutter analyze` e `dart format --set-exit-if-changed .`
    limpos).
-   **Cobertura da camada Presentation:** 34,9% → **37,1%**
    (605/1631 linhas). **Cobertura da camada Application:** 75,4% →
    **76,5%** (579/757 linhas --- aumento pela nova ramificação de
    `_run()` coberta pelo teste de regressão).

### Item 5 --- Editar Perfil (concluído, 2026-07-21)

Commit `809206a` (branch `feature/qa-12-widget-tests-profile`,
mesclada em `develop` por merge commit `4aabfab`).

-   12 cenários cobertos em `EditProfilePage`: renderização inicial
    mesmo sem perfil carregado, formulário preenchido a partir do
    perfil, validação de nome obrigatório, salvar com sucesso
    (navegando de volta), estado de salvamento (indicador no botão),
    erro via snackbar, cancelamento (botão voltar sem enviar
    alterações), navegação para a troca de avatar, responsividade e
    acessibilidade básica.
-   10 cenários cobertos em `ChangeAvatarPage`: renderização inicial
    com ícone padrão, resolução da URL assinada para avatar existente,
    botão "Salvar foto" desabilitado até uma imagem ser selecionada,
    estado de envio com indicador e navegação de volta ao concluir,
    erro via snackbar, voltar sem selecionar foto, responsividade e
    acessibilidade básica. A seleção real de imagem (`ImagePicker`,
    sem canal de plataforma mockado) e o disparo de `updateAvatar()`
    via toque em "Salvar foto" não são testáveis por interação de UI
    --- mesma limitação já estabelecida para os demais fluxos baseados
    em `ImagePickerService`; os estados de carregamento/sucesso/erro
    de `updateAvatar()` foram validados invocando o controller
    diretamente via `ProviderContainer` (mesma técnica usada nos
    rounds de Favoritos/Feed para estados sem gatilho de UI
    equivalente). Ambas as páginas usam uma seed de
    `UserProfileStatus` inicial, já que nenhuma delas dispara
    carregamento próprio (assumem que o perfil já foi carregado por
    `ProfilePage` antes da navegação, DV-02 §4). Mesma estratégia dos
    rounds anteriores (`ProviderScope` + `MaterialApp.router` +
    mocktail + rotas placeholder), sem
    `golden_toolkit`/`integration_test`.
-   **Nenhuma alteração de código de produção foi necessária nesta
    rodada:** nenhum bug de acessibilidade foi encontrado em
    `EditProfilePage` ou `ChangeAvatarPage`.
-   **Achado de acessibilidade fora do escopo (documentado, não
    corrigido nem testado):** `ProfilePage` (tela de visualização,
    diferente de "Editar Perfil") tem um `IconButton` de configurações
    (`Icons.settings`, navega para `/settings`) sem `tooltip` --- mesma
    classe de bug já corrigida em rodadas anteriores (Tier 1, Itens 1
    e 2 deste Tier), mas em uma tela fora do escopo desta entrega.
-   **Divergências documentadas (não corrigidas nesta rodada):**
    -   DV-02 §10 modela estados genéricos (Initial/Loading/Loaded/
        Updating/Success/Error) para o módulo inteiro, mas
        `EditProfilePage` não renderiza estados distintos de corpo
        para Initial/Loading/Error --- o formulário é sempre exibido;
        erro via snackbar e sucesso via pop (mesmo padrão já visto em
        `CreateReviewPage`).
    -   DV-02 §14 "Integração > Storage" lista "Remoção da foto
        anterior (quando aplicável)"; `updateAvatar()` não remove o
        arquivo de avatar anterior do Storage ao fazer upload do novo
        (achado na camada de dados, fora do escopo de Widget Tests).
-   **Evolução da suíte:** 220 → **242** testes (12 novos em
    `EditProfilePage` + 10 novos em `ChangeAvatarPage`; `flutter test`,
    242/242 aprovados; `flutter analyze` e
    `dart format --set-exit-if-changed .` limpos).
-   **Cobertura da camada Presentation:** 37,1% → **42,7%**
    (697/1631 linhas). **Cobertura da camada Application:** 76,5% →
    **77,0%** (583/757 linhas).

**Tier 2 --- encerrado (5/5 itens concluídos, 2026-07-21).**

------------------------------------------------------------------------

# 3.1 FASE 6C --- Gap Analysis (concluída, sem código, 2026-07-19)

Etapa intermediária, puramente analítica (nenhum arquivo de código
alterado) para decidir com evidência onde investir antes de continuar
o Tier 2. Cobertura real medida por arquivo (não mais estimativas):
Domain 45,7%, Application 71,6% — a maior parte do "gap" em Domain é
um artefato do instrumentador de cobertura (construtores `const` de
exceção nunca registram *hit*), não uma lacuna real.

**Achados que mudaram a ordem prevista da FASE 6:**

-   Três arquivos de Application com **0% de cobertura**:
    `current_user_role_provider.dart` (controla acesso ao painel
    admin), `public_profile_provider.dart` e
    `user_reviews_controller.dart`.
-   Ações inteiras nunca exercitadas por nenhum teste unitário:
    `follow_controller.dart` (erro de `load()`/`toggle()`),
    `comments_controller.dart` (`delete()`),
    `review_detail_controller.dart` (`update()`, sucesso de
    `addPhoto()`, ramo "descurtir" de `toggleLike()`, erro de
    `delete()`) — este último era o controller mais frágil da
    auditoria (57,6%).
-   **Duas telas de Alto Risco sem nenhum Widget Test e fora de
    qualquer Tier até então**: Detalhe do Restaurante e Detalhe da
    Avaliação — ambas ponte obrigatória entre buscar/criar avaliação
    (Tier 1, já cobertos) e o resto do app.
-   **Recomendação resultante:** reforçar Testes Unitários antes de
    continuar o Tier 2 de Widget Tests — risco confirmado (não
    hipotético) e mais barato de corrigir do que abrir novas telas.

------------------------------------------------------------------------

# 3.2 FASE 6D --- Unit Test Reinforcement (concluída, 2026-07-19)

Commit `539cacd` (branch `feature/qa-07-unit-test-reinforcement`).
Cobriu exclusivamente os 4 itens de prioridade máxima da Gap Analysis
— nenhuma cobertura artificial (sem testes de construtores `const`,
exceções, guard clauses triviais ou ramos `catch (_)` genéricos):

-   `current_user_role_provider.dart`: 0% → **100%**.
-   `review_detail_controller.dart`: 57,6% → **89,8%**.
-   `follow_controller.dart`: 71,4% → **90,5%**.
-   `comments_controller.dart`: 86,0% → **90,7%**.

**Cobertura da camada Application: 71,6% → 75,4%** (538/751 → 566/751
linhas). `public_profile_provider.dart` e `user_reviews_controller.dart`
permanecem em 0% — não estavam na lista de prioridade máxima desta
rodada, ficam registrados para uma rodada futura. Validado com
`flutter analyze` (limpo), `dart format --set-exit-if-changed .`
(limpo) e `flutter test --coverage` (169/169 aprovados, suíte
155 → **169** testes).

------------------------------------------------------------------------

# 4. Itens do QA-04 permanentemente fora do escopo atual

Registrado explicitamente para não ser reintroduzido sem decisão nova:

-   **Golden Tests** e **Testes Exploratórios** (QA-04 §4).
-   **`integration_test`/Patrol** (QA-04 §9) — sem projeto Supabase
    real para validar contra, mesmo bloqueio já registrado em DV-11.
-   Testes de performance (QA-05), segurança/RLS/RBAC contra Postgres
    real (QA-06), gestão formal de bugs (QA-07) e critérios de
    aceite/go-live (QA-08) — nenhum iniciado ainda.

------------------------------------------------------------------------

# 5. Próximo passo --- Tier 2 reordenado (2026-07-19, atualizado 2026-07-21)

Com base nos achados da Gap Analysis (§3.1), a ordem prevista original
do Tier 2 foi revista: **Detalhe do Restaurante** e **Detalhe da
Avaliação** (Alto Risco, identificados só nesta análise) entram **antes**
de Favoritar, Feed e Editar Perfil (que já eram conhecidos desde a
FASE 6A). Ordem atual do Tier 2:

1.  ~~Detalhe do Restaurante~~ --- **concluído** (§3, commit `377ebc9`)
2.  ~~Detalhe da Avaliação~~ --- **concluído** (§3, commit `1f6367f`)
3.  ~~Favoritar~~ --- **concluído** (§3, commit `dfbae4c`)
4.  ~~Feed~~ --- **concluído** (§3, commit `fb96bc0`)
5.  ~~Editar Perfil~~ --- **concluído** (§3, commit `809206a`)

**Tier 2 encerrado (5/5 itens concluídos, 2026-07-21).**

------------------------------------------------------------------------

# 6. Auditoria de Encerramento da FASE 6 (concluída, 2026-07-22)

Revisão cruzada de QA-01 a QA-08 contra este documento, o EX-02, o
código-fonte, `coverage/lcov.info`, o CI e a infraestrutura Supabase.
Recomendação: **(B) executar rodadas adicionais** antes do
encerramento formal da FASE 6 — o Widget Testing (Tier 1 + Tier 2)
está genuinamente concluído, mas a FASE 6 como um todo (QA-01 a
QA-08) tem 3 bloqueadores estruturais: ausência de ambiente
Staging/Produção, zero testes de Integração/Performance, e zero
UAT/plano de rollback. Metas de cobertura do QA-02 (Domain 90%/
Application 85%/Data 80%) não atingidas (atual: 63,0%/77,0%/1,6%) —
registrado como dívida técnica conhecida, não bloqueante.

**Decisão tomada:** iniciar o QA-03 (Integration Testing) para
eliminar o maior bloqueador identificado (ausência de ambiente
isolado), antes de decidir sobre o encerramento formal da FASE 6.

------------------------------------------------------------------------

# 7. QA-03 --- Integration Testing (em andamento)

## Rodada 0 --- Provisionamento do ambiente QA/Test (concluída, 2026-07-22)

Commit `60f60c8` (branch `feature/qa-13-provision-qa-environment`,
mesclada em `develop` por merge commit `45fda6c`).

-   **Ambiente `borah-qa` provisionado**: projeto Supabase dedicado
    (ref `fgzokfkvccgkclkmfqui`, região `sa-east-1`, mesma organização
    do Development), criado e vinculado via Supabase CLI.
-   **24/24 migrations aplicadas** (`supabase db push`), idênticas em
    nome e ordem às do Development.
-   **Validação estrutural cruzada** (sem Docker --- `db diff`/
    `db dump` dependem de Docker, indisponível nesta máquina; validado
    por métodos alternativos via `supabase inspect db` e
    `supabase db query --linked`): 15/15 tabelas, 41/41 policies RLS e
    17/17 funções idênticas entre Development e QA; RLS habilitado nas
    15 tabelas de `public` no projeto QA. Nenhuma divergência
    estrutural encontrada.
-   **Bootstrap validado**: usuário de teste criado via Admin API (o
    endpoint público de signup rejeita domínios `.test`/`example.com`
    por validação de e-mail do GoTrue --- achado registrado, não
    corrigido, é comportamento do provedor); trigger
    `handle_new_user()` confirmado populando `profiles`; funções RBAC
    (`is_admin`, `has_admin_role`, `can_moderate`) confirmadas
    `SECURITY DEFINER` e funcionando sem recursão (mesma correção do
    Development, migration `20260720130030`). Usuário de teste
    removido ao final, cascata de `profiles` confirmada.
-   **`.env.qa` criado** (não versionado) com `SUPABASE_URL`/
    `SUPABASE_ANON_KEY` do projeto QA; `.gitignore` atualizado.
-   **QA-03 §6 "Base de dados exclusiva para testes": bloqueador
    estrutural eliminado.** Rodadas A--E do plano de Integration
    Testing (Autenticação, Restaurantes+Avaliações, Favoritos+Feed,
    Perfil, e o próprio scaffolding) estão **liberadas** para início.
    **Rodada F (CI)** permanece pendente apenas da configuração manual
    dos 4 GitHub Secrets (ver pendências abaixo).

### Achados e pendências registradas nesta rodada

-   **Achado pré-existente (não introduzido agora):** nem Development
    nem QA têm nenhum bucket de Storage criado --- os fluxos de upload
    de foto (avatar, capa de restaurante, fotos de avaliação) nunca
    foram validados contra Storage real em nenhum ambiente. Pendência
    registrada para quando a Rodada E (Perfil/avatar) for
    implementada; **criação dos buckets de Storage** também fica como
    pendência de infraestrutura, fora do escopo desta rodada.
-   **Achado de segurança:** ao consultar `supabase projects
    api-keys` sem `--reveal`, a CLI expôs por completo a
    `service_role key` no formato legacy (JWT) do projeto `borah-qa`.
    A chave foi usada e descartada nesta sessão, não persistida em
    nenhum arquivo do repositório. **Pendência: rotacionar a
    SERVICE_ROLE_KEY** do projeto `borah-qa` (Dashboard → Project
    Settings → API → Reset service_role key) antes de qualquer uso em
    produção/CI, preferindo o formato novo (`sb_secret_...`).
-   **Pendência: configuração dos 4 GitHub Secrets** (`SUPABASE_QA_URL`,
    `SUPABASE_QA_ANON_KEY`, `SUPABASE_QA_PROJECT_REF`,
    `SUPABASE_QA_SERVICE_ROLE_KEY`) --- sem acesso à ferramenta `gh`
    nesta sessão; checklist manual entregue no relatório da Rodada 0,
    aguardando execução por quem tem acesso administrativo ao
    repositório GitHub.
-   Nenhum código Flutter, `pubspec.yaml` ou CI foi alterado nesta
    rodada.

## Rodada A --- Scaffolding e homologação da infraestrutura local (concluída, 2026-07-22)

Commit `b44fb33` (branch `feature/qa-14-integration-scaffolding`).

-   **Estrutura criada**: pacote oficial `integration_test` (SDK do
    Flutter) adicionado ao `pubspec.yaml`; diretório padrão
    `integration_test/` criado na raiz do `app/` (substituindo o
    placeholder vazio de `test/integration/`); helpers organizados em
    `integration_test/helpers/`:
    -   `qa_environment.dart` --- guard-rail que aborta a suíte se
        `SUPABASE_URL` não apontar para o `borah-qa` (ref
        `fgzokfkvccgkclkmfqui`), evitando rodar contra
        Development/Production por engano.
    -   `test_user_helper.dart` --- scaffolding (ainda não exercido)
        para criar/remover usuários de teste via Admin API do
        Supabase, pronto para a Rodada B. `SERVICE_ROLE_KEY` nunca
        hardcoded --- sempre lida via `--dart-define` em tempo de
        execução.
-   **Smoke test implementado** (`app_smoke_test.dart`): inicializa a
    aplicação real (`main.dart`/`app.dart`) contra o ambiente QA,
    aguarda a Splash restaurar sessão (sem sessão salva) e confirma a
    navegação até o Login. Nenhum cadastro, login ou dado persistido.
-   **Bloqueador de execução encontrado e resolvido nesta rodada**:
    a primeira tentativa de rodar o smoke test falhou por ausência de
    dispositivo capaz de executar `integration_test` nesta máquina
    (Windows desktop não configurado --- mobile-only por decisão do
    EX-01; Web sem suporte a `integration_test`; nenhum emulador
    Android disponível). Preparação de infraestrutura local realizada
    em rodada específica (fora do repositório): instalação da system
    image `system-images;android-36;google_apis;x86_64`, criação do
    AVD `borah_qa_test` (perfil Pixel 6), e habilitação do Windows
    Hypervisor Platform (WHPX) --- esta última exigiu ação
    administrativa e reinicialização da máquina, executada por você.
-   **Integração ponta a ponta validada com sucesso**: smoke test
    executado no emulador Android **`emulator-5554`** (sdk gphone64
    x86_64, Android 16 / API 36), com o comando
    `flutter test integration_test/app_smoke_test.dart
    --dart-define-from-file=.env.qa -d emulator-5554`.
    -   **Resultado: 1/1 aprovado ("All tests passed!").**
    -   **Tempo de execução:** ~147s no total (130,3s de build Gradle
        `assembleDebug` --- build inicial, sem cache --- + instalação
        do APK + ~2s de execução real do teste).
    -   Confirmado: inicialização real do app (build/instalação/
        execução no emulador), conexão real com o `borah-qa` (log
        `Supabase init completed`, sem exceção de URL/chave inválida),
        e navegação real da Splash até o Login (campos `E-mail`/
        `Senha` e botão `Entrar` confirmados).
-   **Nenhuma regressão**: suíte de unit/widget tests inalterada,
    **242/242 aprovados**, `flutter analyze` e
    `dart format --set-exit-if-changed .` limpos.
-   **Observação registrada (não é pendência)**: o build do Gradle
    emitiu um aviso de que o plugin `share_plus` aplica o Kotlin
    Gradle Plugin (KGP) de uma forma que versões futuras do Flutter
    deixarão de suportar. Não afetou o resultado desta rodada; é uma
    observação de manutenção futura do plugin, sem ação necessária
    agora.

**Infraestrutura local de Integration Tests oficialmente homologada.**
Rodadas B--E (Autenticação, Restaurantes+Avaliações, Favoritos+Feed,
Perfil) liberadas para implementação. Rodada F (CI) permanece
pendente apenas da configuração manual dos 4 GitHub Secrets (ver
Rodada 0 acima).

## Rodada B --- Autenticação (concluída, 2026-07-22)

Commits `4b8ec67` (branch `feature/qa-15-authentication-integration`,
implementação inicial dos 4 cenários) e um segundo commit de
estabilização/correção nesta mesma branch (ver hash ao final desta
seção).

-   **4 cenários implementados**, um arquivo por cenário
    (`integration_test/authentication/{signup,login,logout,
    persistence}_test.dart`), cada um com seu próprio
    `Supabase.initialize()` (evita reinicialização dupla no mesmo
    processo) --- independentes entre si, sem depender de ordem de
    execução:
    -   **Cadastro**: dirige o formulário real de `SignupPage` (único
        cenário que não usa `QaTestUserHelper` para criar o usuário,
        já que o próprio fluxo de cadastro é o que está sendo
        validado). Usa domínio `mailinator.com` (domínios reservados
        de teste são rejeitados pela validação de e-mail do GoTrue,
        achado da Rodada 0).
    -   **Login/Logout/Persistência**: usuário pré-criado via
        `QaTestUserHelper` (Admin API, já confirmado).
-   **Helpers adicionados**: `helpers/pump_helpers.dart` (`pumpUntil`
    compartilhado), `helpers/qa_test_config.dart` (constrói
    `QaTestUserHelper` lendo `SUPABASE_QA_SERVICE_ROLE_KEY` via
    `--dart-define`, nunca hardcoded/gravada em `.env.qa`),
    `helpers/test_user_helper.dart` estendido com `findUserByEmail()`
    e `fetchProfile()`.

### Achado 1 --- Rate limit de e-mail (infraestrutura, resolvido)

Na primeira execução, o cenário de Cadastro foi bloqueado por
`over_email_send_rate_limit` (HTTP 429) --- o Supabase usa um SMTP
compartilhado com limite baixo por padrão para projetos novos, e duas
tentativas de cadastro em poucos minutos já esgotaram a cota. **Não
era um bug de código.** Resolvido por você desabilitando "Confirm
email" para o projeto `borah-qa` (Dashboard --- Authentication ---
Sign In / Providers --- Email).

### Achado 2 --- Condição de corrida no cadastro (bug real de produção, corrigido)

Ao desabilitar "Confirm email", o cenário de Cadastro passou a falhar
de forma diferente: a navegação esperada para `/email-verification`
nunca acontecia. Investigação confirmou uma condição de corrida real
em `AuthController.signUp()`
(`app/lib/features/authentication/application/auth_controller.dart`):
o método definia `EmailVerificationPending` **incondicionalmente**
após `signUp()`, sem checar se uma sessão já havia sido criada. Com
"Confirm email" desabilitado, `signUp()` já retorna com sessão ativa
--- e o listener assíncrono de `onAuthStateChange` (que define
`Authenticated` ao detectar a sessão) competia com essa atribuição
incondicional, sem ordem garantida entre os dois caminhos assíncronos.

**Comportamento antes da correção:** resultado indeterminístico
--- dependendo de qual dos dois caminhos assíncronos executasse por
último, o app podia ficar preso num estado inconsistente (a
navegação para `/email-verification` nunca se consolidava).

**Correção aplicada** (menor alteração possível, sem duplicar regra
de negócio nem criar estado novo): `signUp()` passou a consultar
`_repository.currentUser` logo após o `await` --- a mesma técnica já
usada em `signIn()`/`restoreSession()` no mesmo arquivo --- e decide
o estado final de forma determinística:

```dart
final current = _repository.currentUser;
state = current == null
    ? EmailVerificationPending(email)
    : Authenticated(userId: current.userId, email: current.email);
```

**Comportamento depois da correção**, funcionando corretamente para
os dois cenários de configuração:
-   **Confirm email = ON**: `currentUser` é `null` logo após
    `signUp()` --- `EmailVerificationPending`, navega para
    `/email-verification` (comportamento original, preservado).
-   **Confirm email = OFF** (cenário atual do `borah-qa`):
    `currentUser` já reflete a sessão criada --- `Authenticated`
    diretamente, navega para `/home`.

Teste unitário adicionado em `auth_controller_test.dart` cobrindo o
cenário "confirm email OFF -> Authenticated". O teste de integração
`signup_test.dart` foi atualizado para aguardar e validar
corretamente **qualquer um dos dois desfechos válidos**, falhando
explicitamente (sem mascarar erros) caso nenhum dos dois --- ou um
terceiro estado inesperado --- ocorra.

### Resultado final da Rodada B

-   **4/4 cenários de Integration Test aprovados** em emulador
    Android real (`emulator-5554`), executados individualmente contra
    o `borah-qa`: Cadastro, Login, Logout, Persistência.
-   **Nenhum usuário órfão**: confirmado via `select count(*) from
    auth.users` no `borah-qa` = 0 após todas as execuções.
-   **Nenhuma regressão**: suíte de unit/widget tests
    **243/243 aprovados** (242 + 1 novo teste unitário do
    `AuthController`), `flutter analyze` e
    `dart format --set-exit-if-changed .` limpos.

**Autenticação ponta a ponta homologada no ambiente `borah-qa`.**
Rodadas C--E (Restaurantes+Avaliações, Favoritos+Feed, Perfil)
liberadas para implementação, reaproveitando a mesma arquitetura
(arquivos separados por cenário, `QaTestUserHelper`, `pumpUntil`).

**Próximo passo:** aguardando autorização explícita para iniciar a
Rodada C do QA-03.
