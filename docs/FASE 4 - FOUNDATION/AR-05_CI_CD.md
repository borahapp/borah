
# AR-05 — CI/CD

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-05_CI_CD.md

---

# 1. Objetivo

Definir a estratégia de Integração Contínua (CI) e Entrega Contínua (CD) do BORAH, automatizando validações, builds, testes e deploys para garantir qualidade, segurança e rapidez na entrega.

---

# 2. Objetivos da Pipeline

- Automatizar validações
- Garantir qualidade do código
- Reduzir erros manuais
- Padronizar builds
- Facilitar releases
- Permitir deploys reproduzíveis

---

# 3. Ferramentas

| Ferramenta | Finalidade |
|------------|------------|
| GitHub Actions | CI/CD |
| Flutter | Build |
| FVM | Controle da versão do Flutter |
| Supabase CLI | Migrações e Edge Functions |
| GitHub Releases | Distribuição |
| Google Play Console | Android |
| App Store Connect | iOS |

---

# 4. Fluxo da Pipeline

```text
Commit
   ↓
Pull Request
   ↓
CI
   ↓
Lint
   ↓
Testes
   ↓
Build
   ↓
Review
   ↓
Merge
   ↓
CD
   ↓
Deploy
```

---

# 5. Integração Contínua (CI)

Executar automaticamente em Pull Requests:

- Instalação de dependências
- Análise estática
- Formatação
- Geração de código
- Testes unitários
- Testes de widget
- Build de validação

---

# 6. Entrega Contínua (CD)

Após merge em `main`:

- Gerar artefatos
- Criar Release
- Publicar Tags
- Executar deploy do backend
- Publicar aplicativo (quando aplicável)

---

# 7. Ambientes

## Development
- Testes rápidos
- Builds internos

## Staging
- Validação da equipe
- Testes de integração

## Production
- Usuários finais
- Deploy aprovado

---

# 8. Qualidade

Critérios mínimos:

- Lint sem erros
- Testes aprovados
- Cobertura mínima definida pelo time
- Build concluído com sucesso

---

# 9. Segurança

- Secrets no GitHub Secrets
- Tokens nunca versionados
- Permissões mínimas para workflows
- Assinatura de artefatos quando aplicável

---

# 10. Pipeline do Backend

Automatizar:

- Migrações do banco
- Publicação de Edge Functions
- Atualização de políticas RLS
- Validação do schema

---

# 11. Pipeline do Flutter

Automatizar:

- flutter pub get
- dart format
- flutter analyze
- build_runner
- flutter test
- flutter build

---

# 12. Artefatos

Gerar:

- APK (debug)
- AAB (release)
- IPA (quando disponível)
- Relatórios de testes
- Logs da pipeline

---

# 13. Rollback

Toda release deve permitir:

- Reversão do backend
- Reversão do aplicativo
- Recuperação de migrações quando possível

---

# 14. Monitoramento

Após deploy acompanhar:

- Falhas
- Tempo de execução
- Logs
- Taxa de sucesso
- Erros críticos

---

# 15. Boas Práticas

- Workflows pequenos e reutilizáveis
- Cache de dependências
- Execução paralela quando possível
- Aprovação manual para produção

---

# 16. Anti-patterns

Evitar:

- Deploy manual recorrente
- Secrets no repositório
- Ignorar falhas da pipeline
- Builds sem testes

---

# 17. Critérios de Aceite

- Pipeline documentada
- CI automatizada
- CD automatizada
- Ambientes separados
- Segurança configurada

---

# 18. Checklist

- GitHub Actions definidos
- CI documentada
- CD documentada
- Build automatizado
- Testes automatizados
- Deploy automatizado
- Estratégia de rollback definida
- Monitoramento previsto
