# EX-05 --- Release Roadmap

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-05_RELEASE_ROADMAP.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir o planejamento oficial das releases do BORAH, estabelecendo
entregas incrementais, critérios de evolução, marcos do projeto e
governança de versões até a produção.

------------------------------------------------------------------------

# 2. Princípios

-   Entregas pequenas e frequentes.
-   Cada release deve ser estável.
-   Nenhuma release avança sem atender à Definition of Done.
-   Releases devem ser rastreáveis por versão e changelog.

------------------------------------------------------------------------

# 3. Estratégia de Versionamento

Adotar Semantic Versioning (SemVer):

-   MAJOR: mudanças incompatíveis.
-   MINOR: novas funcionalidades compatíveis.
-   PATCH: correções e melhorias.

Exemplos:

-   v0.1.0
-   v0.5.0
-   v1.0.0
-   v1.1.2
-   v2.0.0

------------------------------------------------------------------------

# 4. Roadmap de Releases

## Release 0.1 --- Foundation

Objetivo: - Estrutura do projeto - Autenticação - Configuração inicial -
Banco de dados - APIs base - CI/CD

Critério de aceite: - Projeto executando ponta a ponta.

------------------------------------------------------------------------

## Release 0.5 --- MVP

Objetivo: - Cadastro e login - Perfil - Restaurantes - Avaliações -
Ranking básico - Favoritos

Critério de aceite: - MVP utilizável por usuários internos.

------------------------------------------------------------------------

## Release 0.8 --- Beta Fechado

Objetivo: - Feed - Amigos - Compartilhamentos - Notificações - Melhorias
de UX - Correções

Critério de aceite: - Testes com grupo restrito.

------------------------------------------------------------------------

## Release 0.9 --- Beta Público

Objetivo: - Escalabilidade - Performance - Observabilidade - Correções
finais - Campanhas de pré-lançamento

Critério de aceite: - Aplicativo apto para testes públicos.

------------------------------------------------------------------------

## Release 1.0 --- Lançamento Oficial

Objetivo: - Publicação Android - Publicação iOS - Marketing -
Monitoramento - Suporte inicial

Critério de aceite: - Aplicativo disponível nas lojas.

------------------------------------------------------------------------

## Release 1.1+

Objetivo: - IA para recomendações - Novas funcionalidades - Melhorias
contínuas - Otimizações

------------------------------------------------------------------------

# 5. Processo de Release

1.  Finalizar desenvolvimento.
2.  Executar QA.
3.  Aprovar Code Review.
4.  Gerar Release Notes.
5.  Criar Tag Git.
6.  Executar pipeline.
7.  Publicar.
8.  Monitorar métricas.
9.  Registrar lições aprendidas.

------------------------------------------------------------------------

# 6. Critérios para Publicação

-   Build aprovado.
-   Testes aprovados.
-   Documentação atualizada.
-   Changelog atualizado.
-   Rollback definido.
-   Aprovação do responsável técnico.

------------------------------------------------------------------------

# 7. Governança

Toda release deve possuir:

-   Número da versão
-   Data
-   Responsável
-   Escopo
-   Riscos
-   Critérios de rollback
-   Release Notes

------------------------------------------------------------------------

# 8. Indicadores

-   Frequência de releases
-   Taxa de sucesso
-   Tempo de recuperação (MTTR)
-   Bugs pós-release
-   Tempo médio entre releases

------------------------------------------------------------------------

# 9. Critérios de Aceite

O roadmap é considerado implementado quando:

-   Todas as releases possuem escopo definido.
-   Versionamento segue SemVer.
-   Processo de release está documentado.
-   Governança está estabelecida.

------------------------------------------------------------------------

# 10. Próximo Documento

Após aprovação deste documento, iniciar:

**EX-06 --- AI Development Workflow**
