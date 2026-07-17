
# AR-04 — Git Strategy

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-04_GIT_STRATEGY.md

---

# 1. Objetivo

Definir a estratégia oficial de versionamento e colaboração do projeto BORAH, garantindo um fluxo de desenvolvimento consistente, seguro e escalável.

---

# 2. Princípios

- Histórico limpo
- Commits pequenos
- Integração contínua
- Revisão obrigatória
- Automatização sempre que possível

---

# 3. Modelo de Branches

```text
main
│
├── develop
│   ├── feature/*
│   ├── bugfix/*
│   ├── release/*
│   └── hotfix/*
```

## Branches

| Branch | Finalidade |
|---------|------------|
| main | Produção |
| develop | Desenvolvimento |
| feature/* | Novas funcionalidades |
| bugfix/* | Correções sem urgência |
| hotfix/* | Correções críticas |
| release/* | Preparação de versão |

---

# 4. Fluxo de Trabalho

1. Criar branch a partir de `develop`.
2. Desenvolver a funcionalidade.
3. Executar lint e testes.
4. Abrir Pull Request.
5. Code Review.
6. Merge em `develop`.
7. Criar `release/*` quando necessário.
8. Publicar em `main`.

---

# 5. Convenção de Commits

Padrão: **Conventional Commits**

Exemplos:

```text
feat(auth): login com Google
fix(groups): corrige convite duplicado
refactor(events): simplifica controller
docs(ui): atualiza design system
test(rankings): adiciona testes
chore(deps): atualiza dependências
ci(actions): ajusta pipeline
```

Tipos:

- feat
- fix
- docs
- style
- refactor
- test
- chore
- ci
- perf
- build

---

# 6. Pull Requests

Todo PR deve conter:

- Objetivo
- Alterações realizadas
- Evidências (prints ou vídeos quando aplicável)
- Checklist preenchido
- Issue relacionada

---

# 7. Code Review

Verificar:

- Arquitetura
- Legibilidade
- Performance
- Segurança
- Testes
- Aderência ao Design System
- Padrões do projeto

Aprovação mínima: 1 revisor.

---

# 8. Proteção de Branches

## main

- Merge direto proibido
- PR obrigatório
- CI obrigatória
- Aprovação obrigatória

## develop

- Merge via PR
- CI obrigatória

---

# 9. Versionamento

Padrão: Semantic Versioning

```text
MAJOR.MINOR.PATCH
```

Exemplos:

- 1.0.0
- 1.1.0
- 1.1.1

---

# 10. Releases

Fluxo:

```text
develop
   ↓
release/x.y.z
   ↓
main
   ↓
tag
```

Cada release deve possuir Release Notes.

---

# 11. Tags

Formato:

```text
v1.0.0
v1.1.0
v2.0.0
```

---

# 12. GitHub

Configurar:

- Branch Protection
- CODEOWNERS
- Issue Templates
- Pull Request Template
- GitHub Actions
- Dependabot

---

# 13. Hooks

Sugestão:

Pré-commit:

- formatter
- analyzer

Pré-push:

- testes
- geração de código

---

# 14. Checklist antes do Merge

- Código compilando
- Testes passando
- Lint sem erros
- Arquivos gerados atualizados
- Documentação atualizada
- Code Review aprovado

---

# 15. Anti-patterns

Evitar:

- Commits genéricos ("update", "ajustes")
- Push direto na main
- PRs muito grandes
- Misturar refatoração e novas funcionalidades
- Ignorar falhas da CI

---

# 16. Critérios de Aceite

- Estratégia de branches definida
- Fluxo de PR documentado
- Commits padronizados
- Versionamento definido
- Processo de release estabelecido

---

# 17. Checklist Final

- Branches documentadas
- Fluxo Git definido
- Conventional Commits adotado
- PR padronizado
- Code Review definido
- Branch Protection prevista
- SemVer documentado
- Releases padronizadas
