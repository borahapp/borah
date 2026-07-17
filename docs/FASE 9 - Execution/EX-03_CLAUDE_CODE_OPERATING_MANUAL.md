# EX-03 --- Claude Code Operating Manual

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-03_CLAUDE_CODE_OPERATING_MANUAL.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir o padrão operacional que o Claude Code deve seguir durante todo
o desenvolvimento do BORAH, garantindo consistência, rastreabilidade,
qualidade e aderência à documentação.

------------------------------------------------------------------------

# 2. Princípios Fundamentais

-   A documentação é a **Single Source of Truth (SSOT)**.
-   Nunca inventar requisitos.
-   Nunca implementar funcionalidades não documentadas.
-   Sempre preservar a arquitetura aprovada.
-   Priorizar código legível, testável e de fácil manutenção.

------------------------------------------------------------------------

# 3. Fluxo Obrigatório de Trabalho

Para cada documento (ET, EN, UX, AR, DV, QA, PB e MK):

1.  Ler o documento atual.
2.  Identificar dependências.
3.  Validar impactos em módulos existentes.
4.  Elaborar um plano resumido de implementação.
5.  Implementar apenas o escopo previsto.
6.  Executar lint, testes e validações.
7.  Atualizar documentação relacionada.
8.  Sugerir mensagem de commit.
9.  Aguardar aprovação antes de seguir.

------------------------------------------------------------------------

# 4. Regras de Implementação

## É obrigatório

-   Seguir Clean Architecture.
-   Aplicar princípios SOLID.
-   Evitar duplicação de código (DRY).
-   Preferir composição à herança.
-   Escrever código autoexplicativo.
-   Criar testes para novas funcionalidades.
-   Registrar decisões arquiteturais relevantes.

## É proibido

-   Alterar funcionalidades aprovadas sem necessidade.
-   Remover código sem justificar.
-   Ignorar falhas de testes.
-   Inserir credenciais no código.
-   Deixar TODOs sem contexto ou responsável.

------------------------------------------------------------------------

# 5. Qualidade de Código

Antes de considerar uma tarefa concluída:

-   Lint sem erros.
-   Formatter executado.
-   Build bem-sucedido.
-   Testes unitários aprovados.
-   Testes de integração quando aplicáveis.
-   Cobertura conforme meta do projeto.
-   Revisão de segurança básica.

------------------------------------------------------------------------

# 6. Gestão de Documentação

Sempre que houver mudança relevante:

-   Atualizar README.
-   Atualizar documentação técnica.
-   Atualizar changelog.
-   Atualizar ADRs quando houver decisão arquitetural.

------------------------------------------------------------------------

# 7. Convenções de Commit

Utilizar Conventional Commits:

-   feat:
-   fix:
-   refactor:
-   docs:
-   test:
-   chore:
-   ci:

Exemplo:

``` text
feat(auth): implementar login com OAuth
```

------------------------------------------------------------------------

# 8. Comunicação

Ao concluir uma tarefa, apresentar:

-   Resumo da implementação.
-   Arquivos criados.
-   Arquivos alterados.
-   Testes executados.
-   Limitações conhecidas.
-   Próximo passo recomendado.

------------------------------------------------------------------------

# 9. Critérios para Avançar

O próximo documento só poderá ser iniciado quando:

-   Implementação aprovada.
-   Testes aprovados.
-   Documentação sincronizada.
-   Sem bloqueios críticos conhecidos.

------------------------------------------------------------------------

# 10. Critérios de Aceite

Este manual é considerado aplicado quando o desenvolvimento segue
consistentemente:

-   O roadmap oficial.
-   Os padrões arquiteturais.
-   As convenções de código.
-   As práticas de documentação.
-   Os critérios de qualidade definidos.

------------------------------------------------------------------------

# 11. Próximo Documento

Após aprovação deste manual, iniciar:

**EX-04 --- Definition of Done**
