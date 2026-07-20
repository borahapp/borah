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

## Rodada 2 --- Tier 2 (ainda não iniciada — reordenada, ver §5)

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

# 5. Próximo passo --- Tier 2 reordenado (2026-07-19)

Com base nos achados da Gap Analysis (§3.1), a ordem prevista original
do Tier 2 foi revista: **Detalhe do Restaurante** e **Detalhe da
Avaliação** (Alto Risco, identificados só nesta análise) entram **antes**
de Favoritar, Feed e Editar Perfil (que já eram conhecidos desde a
FASE 6A). Ordem atual do Tier 2:

1.  Detalhe do Restaurante
2.  Detalhe da Avaliação
3.  Favoritar
4.  Feed
5.  Editar Perfil

Aguardando instrução explícita para confirmar escopo e iniciar a
Rodada 2 nessa nova ordem.
