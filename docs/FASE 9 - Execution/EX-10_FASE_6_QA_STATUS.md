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

## Rodada 2 --- Tier 2 (em andamento — reordenada, ver §5)

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

**Próximo item (4/5):** Feed --- aguardando aprovação explícita antes
de iniciar.

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
4.  Feed
5.  Editar Perfil

Aguardando instrução explícita para confirmar escopo e iniciar o
item 4 (Feed).
