# EX-01 --- Project Bootstrap

**Versão:** 1.2\
**Status:** EX-01A — Concluído · EX-01B — Concluído\
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

## 12.2. Critérios da EX-01B (concluídos)

-   [x] Flutter SDK instalado (3.44.6, stable)
-   [x] FVM configurado (4.1.2; `app/.fvm/fvm_config.json` fixa a versão do projeto)
-   [x] Dart disponível (3.12.2, via Flutter)
-   [x] `flutter create` executado (`pubspec.yaml`, `main.dart` gerados; org `com.borah`, bundle id `com.borah.app`)
-   [x] Plataformas nativas geradas (Android/iOS/Web)
-   [x] Supabase CLI instalado (2.109.1, binário oficial com checksum verificado)
-   [x] `supabase init` executado (`supabase/config.toml` gerado)
-   [x] `flutter doctor` sem erros críticos (Android toolchain OK; Visual Studio/apps desktop Windows não instalado — fora do escopo do projeto, que é mobile-only)
-   [x] `flutter analyze` sem erros
-   [x] `flutter test` executado (1 teste, aprovado)
-   [x] `flutter build apk --debug` validado (build concluído com sucesso)
-   [ ] Ambientes (Development/Homologação/Produção) configurados com
    chaves e projetos Supabase reais — depende da criação dos projetos
    Supabase (AR-06), fora do escopo do bootstrap técnico local

O EX-01 (EX-01A + EX-01B) está integralmente concluído para fins de
bootstrap local. A configuração de projetos Supabase reais por
ambiente é tratada como escopo do AR-06, não deste documento.

------------------------------------------------------------------------

# 13. Próximo Documento

Com a EX-01A e a EX-01B concluídas, o bootstrap está integralmente
finalizado. Conforme a ordem de implementação definida no
EX-02 --- Development Roadmap (Fase 4 --- Arquitetura), o próximo
documento é:

**AR-02 --- Flutter Architecture**

Sujeito a plano prévio e aprovação, conforme o fluxo operacional
vigente.
