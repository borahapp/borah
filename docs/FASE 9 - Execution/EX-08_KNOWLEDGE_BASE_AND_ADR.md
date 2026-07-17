# EX-08 --- Knowledge Base & ADR

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-08_KNOWLEDGE_BASE_AND_ADR.md`

------------------------------------------------------------------------

# 1. Objetivo

Estabelecer uma Base de Conhecimento (Knowledge Base) e um processo
formal de **Architecture Decision Records (ADR)** para preservar o
histórico técnico do BORAH, documentar decisões relevantes e garantir
consistência durante toda a evolução do sistema.

------------------------------------------------------------------------

# 2. Escopo

Aplica-se a:

-   Arquitetura
-   Regras de negócio
-   Infraestrutura
-   Segurança
-   Banco de dados
-   APIs
-   UX técnica
-   DevOps
-   Integrações externas

------------------------------------------------------------------------

# 3. Estrutura da Knowledge Base

``` text
docs/
└── knowledge-base/
    ├── adr/
    ├── architecture/
    ├── backend/
    ├── mobile/
    ├── database/
    ├── devops/
    ├── integrations/
    ├── troubleshooting/
    └── glossary/
```

------------------------------------------------------------------------

# 4. Quando criar um ADR

Criar um ADR sempre que houver:

-   Escolha de tecnologia
-   Mudança arquitetural
-   Alteração de padrão de projeto
-   Mudança de banco de dados
-   Nova estratégia de autenticação
-   Alterações relevantes em APIs
-   Decisões com impacto de longo prazo

------------------------------------------------------------------------

# 5. Modelo Oficial de ADR

Cada ADR deve conter:

-   ID (ADR-0001, ADR-0002...)
-   Título
-   Status (Proposto, Aprovado, Substituído, Obsoleto)
-   Data
-   Contexto
-   Problema
-   Alternativas avaliadas
-   Decisão tomada
-   Justificativa
-   Consequências
-   Impactos
-   Referências relacionadas

------------------------------------------------------------------------

# 6. Base de Conhecimento

A Knowledge Base deve registrar:

-   Padrões de desenvolvimento
-   Convenções
-   Perguntas frequentes
-   Guias de configuração
-   Procedimentos operacionais
-   Lições aprendidas
-   Problemas recorrentes
-   Soluções adotadas

------------------------------------------------------------------------

# 7. Governança

-   Nenhum ADR pode ser removido.
-   ADRs substituídos permanecem arquivados.
-   Toda decisão arquitetural deve referenciar ADRs existentes quando
    aplicável.
-   A documentação deve permanecer sincronizada com o código.

------------------------------------------------------------------------

# 8. Responsabilidades da IA

Durante o desenvolvimento, o Claude Code deve:

1.  Consultar ADRs existentes antes de propor mudanças.
2.  Evitar decisões conflitantes.
3.  Criar novo ADR quando uma decisão estrutural for necessária.
4.  Atualizar a Knowledge Base quando identificar novos padrões ou
    procedimentos.

------------------------------------------------------------------------

# 9. Critérios de Qualidade

Uma entrada na Knowledge Base deve ser:

-   Clara
-   Objetiva
-   Atualizada
-   Rastreável
-   Versionada
-   Referenciada por documentos relacionados

------------------------------------------------------------------------

# 10. Checklist

-   [ ] Estrutura criada
-   [ ] Modelo de ADR disponível
-   [ ] Processo documentado
-   [ ] Responsabilidades definidas
-   [ ] Governança estabelecida

------------------------------------------------------------------------

# 11. Critérios de Aceite

Este documento é considerado implementado quando:

-   Existe uma estrutura oficial para Knowledge Base.
-   O modelo de ADR está definido.
-   O processo de criação e manutenção está documentado.
-   O Claude Code consegue consultar e produzir ADRs de forma
    consistente.

------------------------------------------------------------------------

# 12. Encerramento da Fase 9

Com a aprovação deste documento, a **FASE 9 --- Execution** é
considerada concluída.

O projeto BORAH passa a possuir:

-   Planejamento completo
-   Engenharia documentada
-   UX/UI especificada
-   Arquitetura definida
-   Desenvolvimento especificado
-   QA documentado
-   Publicação planejada
-   Marketing estruturado
-   Processo operacional para IA
-   Governança técnica e memória arquitetural

A partir deste ponto, o desenvolvimento pode ser iniciado seguindo o
EX-02 --- Development Roadmap e o EX-07 --- Master Prompt.
