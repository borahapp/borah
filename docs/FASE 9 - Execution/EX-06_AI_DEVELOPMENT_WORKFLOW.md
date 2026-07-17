# EX-06 --- AI Development Workflow

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-06_AI_DEVELOPMENT_WORKFLOW.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir o fluxo operacional que uma IA de desenvolvimento (Claude Code)
deverá seguir para implementar o BORAH de forma incremental, segura,
rastreável e alinhada à documentação oficial.

------------------------------------------------------------------------

# 2. Princípios

-   A documentação é a Single Source of Truth (SSOT).
-   Nenhuma implementação deve ocorrer sem documentação correspondente.
-   Cada tarefa deve produzir código pronto para produção.
-   A IA deve minimizar retrabalho e preservar compatibilidade.

------------------------------------------------------------------------

# 3. Fluxo de Trabalho

Para **cada documento** do projeto:

1.  Ler o documento alvo.
2.  Ler documentos relacionados e dependências.
3.  Identificar impacto técnico.
4.  Elaborar plano de implementação.
5.  Aguardar esclarecimentos caso existam ambiguidades.
6.  Implementar somente o escopo definido.
7.  Executar validações automáticas.
8.  Atualizar documentação.
9.  Sugerir commit.
10. Aguardar aprovação antes da próxima etapa.

------------------------------------------------------------------------

# 4. Entradas Obrigatórias

Antes de iniciar uma implementação, a IA deve conhecer:

-   Roadmap oficial
-   Arquitetura
-   Regras de negócio
-   UX/UI
-   ADRs
-   Definition of Done
-   Operating Manual

------------------------------------------------------------------------

# 5. Saídas Esperadas

Ao concluir cada tarefa, apresentar:

-   Resumo da implementação
-   Arquivos criados
-   Arquivos alterados
-   Testes executados
-   Cobertura obtida (quando disponível)
-   Limitações conhecidas
-   Próximo documento recomendado

------------------------------------------------------------------------

# 6. Processo de Implementação

## Planejar

-   Entender requisitos
-   Validar dependências
-   Identificar riscos

## Construir

-   Implementar código
-   Seguir padrões arquiteturais
-   Escrever testes

## Validar

-   Executar lint
-   Formatter
-   Build
-   Testes

## Finalizar

-   Atualizar documentação
-   Atualizar changelog
-   Preparar commit
-   Solicitar aprovação

------------------------------------------------------------------------

# 7. Tratamento de Bloqueios

Se houver:

-   Requisitos conflitantes
-   Dependências ausentes
-   Dúvidas arquiteturais
-   Erros críticos

A IA deve interromper a implementação e relatar claramente:

-   Problema
-   Impacto
-   Alternativas
-   Recomendação

Nunca assumir requisitos inexistentes.

------------------------------------------------------------------------

# 8. Regras de Evolução

-   Não alterar APIs públicas sem justificativa.
-   Preservar compatibilidade quando possível.
-   Refatorações devem manter comportamento esperado.
-   Toda mudança estrutural relevante deve gerar um ADR.

------------------------------------------------------------------------

# 9. Checklist Operacional

Antes de concluir uma tarefa:

-   [ ] Documentação consultada
-   [ ] Dependências verificadas
-   [ ] Código implementado
-   [ ] Testes executados
-   [ ] Lint aprovado
-   [ ] Build aprovado
-   [ ] Documentação atualizada
-   [ ] Commit sugerido
-   [ ] Pronto para revisão

------------------------------------------------------------------------

# 10. Critérios de Aceite

O workflow é considerado seguido quando:

-   Cada implementação respeita o roadmap.
-   Toda entrega atende à Definition of Done.
-   Não existem alterações fora do escopo.
-   A documentação permanece sincronizada com o código.

------------------------------------------------------------------------

# 11. Próximo Documento

Após aprovação deste workflow, iniciar:

**EX-07 --- Master Prompt**
