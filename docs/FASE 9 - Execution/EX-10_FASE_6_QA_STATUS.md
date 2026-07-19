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

## Rodada 2 --- Tier 2 (não iniciada)

Favoritar, Editar Perfil e Feed — aguardando confirmação explícita de
escopo antes de começar, mesmo ritual de aprovação da Rodada 1.

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

# 5. Próximo passo

Aguardar instrução explícita para: (a) confirmar escopo e iniciar a
Rodada 2 (Tier 2), ou (b) iniciar outro documento QA-\*.
