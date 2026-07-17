# EX-01 --- Project Bootstrap

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `EX-01_PROJECT_BOOTSTRAP.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a estrutura inicial do projeto BORAH para que o desenvolvimento
possa iniciar de forma padronizada, escalável e reproduzível.

------------------------------------------------------------------------

# 2. Escopo

Este documento estabelece:

-   Estrutura do repositório
-   Stack tecnológica
-   Organização de diretórios
-   Ambientes
-   Convenções de desenvolvimento
-   Git Flow
-   CI/CD
-   Ferramentas obrigatórias

------------------------------------------------------------------------

# 3. Stack Oficial

## Mobile

-   Flutter (última versão estável)
-   Dart
-   Riverpod
-   GoRouter

## Backend

-   Go
-   Clean Architecture
-   REST API

## Banco de Dados

-   PostgreSQL
-   Redis (cache)

## Infraestrutura

-   Docker
-   Docker Compose
-   GitHub Actions

------------------------------------------------------------------------

# 4. Estrutura do Monorepo

``` text
BORAH/
├── apps/
│   ├── mobile/
│   └── admin/
├── backend/
│   ├── api/
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── tests/
├── docs/
├── database/
│   ├── migrations/
│   └── seeds/
├── infra/
│   ├── docker/
│   └── github/
├── scripts/
├── assets/
└── README.md
```

------------------------------------------------------------------------

# 5. Ambientes

-   Development
-   Homologação
-   Produção

Cada ambiente deve possuir:

-   Variáveis próprias
-   Banco independente
-   Chaves de API independentes
-   Pipeline específico

------------------------------------------------------------------------

# 6. Convenções

## Branches

-   main
-   develop
-   feature/\*
-   fix/\*
-   hotfix/\*
-   release/\*

## Commits

Seguir Conventional Commits:

-   feat:
-   fix:
-   refactor:
-   docs:
-   test:
-   chore:
-   ci:

------------------------------------------------------------------------

# 7. Qualidade

Obrigatório antes de qualquer merge:

-   Formatter
-   Lint
-   Testes unitários
-   Build sem erros
-   Revisão de código

------------------------------------------------------------------------

# 8. CI/CD

Pipeline mínimo:

1.  Instalação de dependências
2.  Lint
3.  Testes
4.  Build
5.  Publicação de artefatos
6.  Deploy conforme ambiente

------------------------------------------------------------------------

# 9. Segurança

-   Secrets fora do repositório
-   Variáveis via ambiente
-   HTTPS obrigatório
-   Autenticação centralizada
-   Dependências verificadas regularmente

------------------------------------------------------------------------

# 10. Documentação

Toda alteração relevante deve atualizar:

-   README
-   Documentação técnica
-   ADRs (quando aplicável)
-   Changelog

------------------------------------------------------------------------

# 11. Ferramentas

-   Git
-   GitHub
-   Docker
-   VS Code
-   Claude Code
-   Figma
-   PostgreSQL
-   Firebase (Analytics/Crashlytics, se adotado)

------------------------------------------------------------------------

# 12. Critérios de Aceite

O projeto estará pronto para desenvolvimento quando:

-   Estrutura criada
-   Ambientes definidos
-   CI configurado
-   Convenções documentadas
-   Ferramentas instaladas
-   Repositório inicializado

------------------------------------------------------------------------

# 13. Próximo Documento

Após concluir este bootstrap, iniciar obrigatoriamente:

**EX-02 --- Development Roadmap**
