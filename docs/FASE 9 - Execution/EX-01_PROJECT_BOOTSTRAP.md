# EX-01 --- Project Bootstrap

**Versão:** 1.1\
**Status:** EX-01A — Concluído · EX-01B — Pendente\
**Documento:** `EX-01_PROJECT_BOOTSTRAP.md`

> **Nota de revisão (v1.1):** este documento foi dividido em duas fases
> independentes, EX-01A e EX-01B (ver Seção 2.1), para refletir que a
> preparação do repositório não depende de ferramentas de ambiente
> (Flutter SDK, FVM, Supabase CLI, Docker), enquanto o bootstrap técnico
> depende. A Seção 3 (Stack Oficial) e a Seção 4 (Estrutura do Monorepo)
> permanecem como registro histórico da concepção original deste
> documento e não foram alteradas por esta revisão — a arquitetura de
> backend vigente do projeto é a definida no
> `docs/knowledge-base/adr/ADR-0001-backend-architecture-supabase.md`.

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

# 2.1. Divisão em Fases — EX-01A e EX-01B

O bootstrap do BORAH é dividido em duas fases independentes, com
critérios de aceite e status próprios (ver Seção 12).

## EX-01A — Estrutura do Projeto

Preparação do repositório, executável em qualquer ambiente, sem
dependência de Flutter SDK, Docker, Supabase CLI ou outras ferramentas
externas:

-   Estrutura de diretórios
-   README mínimo
-   `.gitignore`
-   `.env.example`
-   Estrutura de pastas do Supabase
-   Workflow inicial de CI
-   Preparação do repositório (inicialização Git, commit inicial)

**Status: Concluído.**

## EX-01B — Bootstrap Técnico

Atividades dependentes do ambiente de desenvolvimento:

-   `flutter create`
-   `pubspec.yaml`
-   FVM
-   Flutter SDK
-   Plataformas Android/iOS/Web
-   Supabase CLI
-   `supabase init`
-   `flutter doctor`
-   `flutter analyze`
-   `flutter test`
-   `flutter build`

**Status: Pendente**, até que um ambiente com essas ferramentas esteja disponível.

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

Os critérios foram divididos entre as duas fases do bootstrap (ver
Seção 2.1).

## 12.1. Critérios da EX-01A (concluídos)

-   [x] Estrutura de diretórios criada
-   [x] Repositório inicializado (Git + commit inicial)
-   [x] README mínimo criado
-   [x] `.gitignore` configurado
-   [x] `.env.example` criado
-   [x] Estrutura de pastas do Supabase criada
-   [x] Workflow inicial de CI criado
-   [x] Convenções documentadas (branches, commits)

## 12.2. Critérios da EX-01B (pendentes)

-   [ ] Flutter SDK instalado
-   [ ] FVM configurado
-   [ ] Dart disponível
-   [ ] `flutter create` executado (`pubspec.yaml`, `main.dart` gerados)
-   [ ] Plataformas nativas geradas (Android/iOS/Web)
-   [ ] Supabase CLI instalado
-   [ ] `supabase init` executado
-   [ ] `flutter doctor` sem erros
-   [ ] `flutter analyze` sem erros
-   [ ] `flutter test` executado
-   [ ] `flutter build` validado
-   [ ] Ambientes (Development/Homologação/Produção) configurados com
    chaves e projetos Supabase reais

O EX-01 só poderá ser considerado integralmente concluído quando os
critérios da EX-01B também forem atendidos.

------------------------------------------------------------------------

# 13. Próximo Documento

A EX-01A concluída já permite avançar para os documentos de
planejamento/documentação que não dependem de ambiente técnico. O
avanço para etapas de implementação (ex.: AR-02, DV-01) depende da
conclusão da EX-01B.

Após concluir integralmente este bootstrap (EX-01A + EX-01B), iniciar
obrigatoriamente:

**EX-02 --- Development Roadmap**
