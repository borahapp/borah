# EX-02 --- Development Roadmap

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-02_DEVELOPMENT_ROADMAP.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a sequência oficial de implementação do projeto BORAH,
garantindo que cada etapa seja construída sobre dependências já
concluídas, reduzindo retrabalho e preservando a integridade da
arquitetura.

------------------------------------------------------------------------

# 2. Princípios

-   A documentação é a **Single Source of Truth**.
-   Nenhum documento pode ser implementado antes de suas dependências.
-   Cada etapa deve ser concluída, testada e aprovada antes da próxima.
-   Não implementar funcionalidades fora do roadmap.

------------------------------------------------------------------------

# 3. Fluxo Geral

``` text
Planejamento
    ↓
Engenharia
    ↓
UX/UI
    ↓
Arquitetura
    ↓
Desenvolvimento
    ↓
QA
    ↓
Publicação
    ↓
Marketing
```

------------------------------------------------------------------------

# 4. Ordem de Implementação

## Fase 0 --- Bootstrap

1.  EX-01 --- Project Bootstrap
2.  EX-02 --- Development Roadmap
3.  EX-03 --- Claude Code Operating Manual
4.  EX-04 --- Definition of Done
5.  EX-05 --- Release Roadmap
6.  EX-06 --- AI Development Workflow
7.  EX-07 --- Master Prompt
8.  EX-08 --- Knowledge Base & ADR

------------------------------------------------------------------------

## Fase 1 --- Planejamento

Implementar todos os documentos ET-\* na ordem numérica.

**Marco de aceite:** requisitos congelados e aprovados.

------------------------------------------------------------------------

## Fase 2 --- Engenharia

Implementar todos os documentos EN-\* (ou equivalente definido no
projeto) na ordem numérica.

**Marco de aceite:** regras de negócio completas e validadas.

------------------------------------------------------------------------

## Fase 3 --- UX/UI

Implementar todos os documentos UX-\*.

**Marco de aceite:** - Design System - Protótipos - Fluxos de
navegação - Componentes aprovados

------------------------------------------------------------------------

## Fase 4 --- Arquitetura

Implementar todos os documentos AR-\*.

**Marco de aceite:** - Estrutura backend - Estrutura Flutter - Banco de
dados - APIs - Infraestrutura

------------------------------------------------------------------------

## Fase 5 --- Desenvolvimento

**Status: Concluída (2026-07-20).** Ver
`EX-09_FASE_5_COMPLETION_REPORT.md` para o relatório de encerramento
(módulos entregues, decisões arquiteturais, lacunas documentais e
dependências adiadas por infraestrutura).

Implementar todos os documentos DV-\* individualmente.

Para cada DV:

1.  Ler documentação relacionada
2.  Implementar
3.  Executar testes
4.  Atualizar documentação
5.  Gerar commit sugerido
6.  Aguardar aprovação

Nunca iniciar DV seguinte sem concluir o atual.

------------------------------------------------------------------------

## Fase 6 --- QA

**Status: Em andamento** (Tier 2 de Widget Tests **concluído** em
2026-07-21 — 5/5 itens: Detalhe do Restaurante, Detalhe da Avaliação,
Favoritar, Feed e Editar Perfil). Auditoria de Encerramento da FASE 6
realizada em 2026-07-21/22 (recomendação: executar rodadas adicionais
antes do encerramento formal — ver `EX-10_FASE_6_QA_STATUS.md` §6).
**QA-03 (Integration Testing) iniciado em 2026-07-22** para eliminar o
maior bloqueador identificado: Rodada 0 concluída — ambiente Supabase
dedicado `borah-qa` provisionado e validado estruturalmente contra o
Development (commit `60f60c8`, merge `45fda6c`). **Rodada A concluída
— infraestrutura local de Integration Tests oficialmente homologada**:
scaffolding do pacote `integration_test` implementado e smoke test
aprovado (1/1) em emulador Android real (`emulator-5554`, Android 16),
com conexão validada ponta a ponta contra o `borah-qa` (commit
`b44fb33`). Suíte de unit/widget tests sem regressão (242/242).
**Rodada B concluída — Autenticação homologada ponta a ponta**: 4/4
cenários (Cadastro, Login, Logout, Persistência) aprovados em
emulador Android real contra o `borah-qa` (commit `4b8ec67` +
estabilização). Durante a rodada, um bug real de condição de corrida
em `AuthController.signUp()` foi encontrado e corrigido (estado
indeterminístico quando "Confirm email" está desabilitado) — corrigido
de forma determinística, sem duplicar regra de negócio, funcionando
para os dois cenários de configuração. Suíte de unit/widget tests sem
regressão (243/243). Rodadas C--E liberadas para implementação;
Rodada F (CI) pendente da configuração manual de 4 GitHub Secrets. Ver
`EX-10_FASE_6_QA_STATUS.md` §7 para o progresso detalhado e
pendências (rotação de `SERVICE_ROLE_KEY`, criação de buckets de
Storage, GitHub Secrets).

**Release Candidate iniciado em 2026-07-25.** **RC-01 (Auditoria
Completa da Aplicação) concluída** — revisão somente-leitura de todos
os fluxos, Design System, Motion Design, Performance, Acessibilidade,
Código/Arquitetura e Testes, sem nenhuma alteração de código; ver
`RC-01_APPLICATION_AUDIT.md` para o levantamento completo e a
priorização de melhorias. **RC-02 (Quick Wins) concluída** —
implementados os 5 itens de alto impacto / baixo-médio esforço / baixo
risco identificados na RC-01: componente `ErrorState` reutilizável com
retry, conexão da sincronização em tempo real de Favoritos
(`FavoritesController.refresh()`/`FavoritesSyncing`, já existentes e
nunca usados), reenvio de e-mail de verificação, fluxo de logout com
confirmação/tratamento de erro/feedback visual (incluindo correção de
um redirect indevido de rotas protegidas durante falha de logout), e
upload de fotos em Reviews sem substituir a tela inteira por um
spinner. Commits `f3789e3` (implementação) e `6790179` (refinamento da
suíte de testes) — **desenvolvidos diretamente em `develop`, sem
feature branch nesta rodada**; retomar o fluxo padrão de feature
branches a partir da próxima rodada. Suíte de unit/widget tests sem
regressão (266/266).

Executar QA-\* em sequência.

Cada documento deve incluir:

-   Testes unitários
-   Integração
-   Performance
-   Segurança
-   Regressão

Corrigir falhas antes do próximo QA.

------------------------------------------------------------------------

## Fase 7 --- Publicação

Executar PB-\*.

Inclui:

-   Android
-   iOS
-   Stores
-   CI/CD
-   Monitoramento

------------------------------------------------------------------------

## Fase 8 --- Marketing

Executar MK-\*.

Entregas:

-   Landing Page
-   Vídeos
-   Social
-   Paid Media
-   Influenciadores
-   PR

------------------------------------------------------------------------

# 5. Regras Operacionais

Antes de cada implementação o Claude Code deve:

1.  Ler toda a documentação relevante.
2.  Identificar dependências.
3.  Criar plano de execução.
4.  Implementar somente o escopo do documento atual.
5.  Executar lint.
6.  Executar testes.
7.  Atualizar README e documentação.
8.  Sugerir mensagem de commit.
9.  Aguardar aprovação.

------------------------------------------------------------------------

# 6. Marcos do Projeto

-   M1 --- Planejamento concluído
-   M2 --- Arquitetura aprovada
-   M3 --- MVP funcional
-   M4 --- Beta fechado
-   M5 --- Beta público
-   M6 --- Publicação nas lojas
-   M7 --- Lançamento oficial

------------------------------------------------------------------------

# 7. Critérios de Aceite

O roadmap é considerado atendido quando:

-   Todas as fases foram concluídas na ordem definida.
-   Não existem dependências pendentes.
-   Todas as aprovações foram registradas.
-   A documentação permanece sincronizada com o código.

------------------------------------------------------------------------

# 8. Próximo Documento

Após aprovação deste roadmap, iniciar:

**EX-03 --- Claude Code Operating Manual**
