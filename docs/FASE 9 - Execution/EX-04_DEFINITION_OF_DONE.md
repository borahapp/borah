# EX-04 --- Definition of Done (DoD)

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-04_DEFINITION_OF_DONE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir os critérios obrigatórios para considerar uma tarefa,
funcionalidade, módulo ou release do BORAH como concluída, garantindo
qualidade, consistência e prontidão para produção.

------------------------------------------------------------------------

# 2. Escopo

Aplica-se a:

-   Funcionalidades
-   Correções
-   Refatorações
-   Integrações
-   APIs
-   Componentes Flutter
-   Banco de dados
-   Infraestrutura
-   Releases

------------------------------------------------------------------------

# 3. Critérios Gerais

Uma entrega somente poderá ser considerada **Done** quando todos os
critérios abaixo forem atendidos.

------------------------------------------------------------------------

# 4. Critérios Funcionais

-   Requisitos implementados conforme a documentação.
-   Casos de uso concluídos.
-   Regras de negócio respeitadas.
-   Fluxos principais funcionando.
-   Fluxos de exceção tratados.

------------------------------------------------------------------------

# 5. Critérios Técnicos

-   Código seguindo Clean Architecture.
-   Princípios SOLID aplicados.
-   Código sem duplicação relevante (DRY).
-   Padrões de nomenclatura respeitados.
-   Sem código morto ou comentado.

------------------------------------------------------------------------

# 6. Qualidade

Obrigatório:

-   Lint sem erros.
-   Formatter executado.
-   Build concluído com sucesso.
-   Análise estática sem problemas críticos.
-   Dependências atualizadas e sem vulnerabilidades conhecidas.

------------------------------------------------------------------------

# 7. Testes

-   Testes unitários implementados.
-   Testes de integração (quando aplicável).
-   Testes de widgets/UI (Flutter, quando aplicável).
-   Testes de regressão executados.
-   Cobertura mínima definida pelo projeto atingida.

------------------------------------------------------------------------

# 8. Segurança

-   Segredos fora do código.
-   Validação de entradas.
-   Controle de autenticação e autorização.
-   Logs sem informações sensíveis.
-   Comunicação segura (HTTPS/TLS).

------------------------------------------------------------------------

# 9. Documentação

Atualizar sempre que necessário:

-   README
-   Documentação técnica
-   ADRs
-   Changelog
-   Diagramas impactados

------------------------------------------------------------------------

# 10. Revisão

Antes do merge:

-   Code Review aprovado.
-   Nenhum bloqueio crítico.
-   Feedback incorporado.
-   Aprovação do responsável técnico.

------------------------------------------------------------------------

# 11. Deploy

Para releases:

-   Pipeline CI/CD executado.
-   Artefatos gerados.
-   Deploy realizado no ambiente correto.
-   Monitoramento habilitado.
-   Rollback documentado.

------------------------------------------------------------------------

# 12. Checklist Final

-   [ ] Requisitos concluídos
-   [ ] Testes aprovados
-   [ ] Build aprovado
-   [ ] Lint e formatter executados
-   [ ] Segurança revisada
-   [ ] Documentação atualizada
-   [ ] Code Review aprovado
-   [ ] Pipeline executado
-   [ ] Critérios de aceite atendidos

------------------------------------------------------------------------

# 13. Critérios de Aceite

Uma entrega é considerada concluída apenas quando:

-   Todos os itens do checklist final estiverem completos.
-   Não existirem defeitos críticos conhecidos.
-   A implementação estiver alinhada ao roadmap e à documentação
    oficial.

------------------------------------------------------------------------

# 14. Próximo Documento

Após aprovação deste documento, iniciar:

**EX-05 --- Release Roadmap**
