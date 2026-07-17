# AR-16 --- Deployment

**Versão:** 2.0\
**Status:** Recommended\
**Documento:** `AR-16_DEPLOYMENT.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a estratégia oficial de implantação (Deployment) do BORAH,
estabelecendo processos padronizados para publicação, rollback, controle
de versões e disponibilização da aplicação em todos os ambientes.

O objetivo é garantir que cada deploy seja:

-   Seguro
-   Reproduzível
-   Automatizado
-   Auditável
-   Reversível

------------------------------------------------------------------------

# 2. Escopo

Este documento contempla:

-   Flutter
-   Supabase
-   Banco de Dados
-   Edge Functions
-   Storage
-   CI/CD
-   Publicação nas lojas
-   Rollback
-   Releases

------------------------------------------------------------------------

# 3. Objetivos

-   Reduzir riscos
-   Evitar indisponibilidades
-   Automatizar processos
-   Permitir rollback rápido
-   Garantir rastreabilidade
-   Facilitar auditorias

------------------------------------------------------------------------

# 4. Arquitetura de Deployment

``` text
Developer
      │
      ▼
GitHub
      │
      ▼
GitHub Actions
      │
 ┌────┴───────────┐
 ▼                ▼
Flutter       Supabase
 │                │
 ▼                ▼
Stores      Database
 │                │
 ▼                ▼
Production Environment
```

------------------------------------------------------------------------

# 5. Estratégia de Deploy

Fluxo:

``` text
Commit
↓
Pull Request
↓
CI
↓
Build
↓
Testes
↓
Deploy Staging
↓
Homologação
↓
Deploy Produção
```

------------------------------------------------------------------------

# 6. Deploy do Flutter

-   APK (Debug)
-   AAB (Release)
-   IPA
-   TestFlight

------------------------------------------------------------------------

# 7. Deploy do Backend

Sempre incluir:

-   Migrações
-   Edge Functions
-   Configurações
-   Policies RLS
-   Storage Policies

------------------------------------------------------------------------

# 8. Ordem do Deployment

1.  Banco
2.  Policies
3.  Edge Functions
4.  Storage
5.  Flutter
6.  Publicação

------------------------------------------------------------------------

# 9. Versionamento

Semantic Versioning:

``` text
MAJOR.MINOR.PATCH
```

Exemplos:

-   1.0.0
-   1.2.5
-   2.0.0

------------------------------------------------------------------------

# 10. Releases

Cada release deverá conter:

-   Número da versão
-   Data
-   Responsável
-   Changelog
-   Correções
-   Novas funcionalidades
-   Migrações executadas

------------------------------------------------------------------------

# 11. Rollback

Todo deploy deverá possuir plano de rollback para:

-   Flutter
-   Banco
-   Edge Functions
-   Storage

------------------------------------------------------------------------

# 12. Feature Flags

Utilizar sempre que possível para liberar funcionalidades gradualmente.

------------------------------------------------------------------------

# 13. Checklist Pré-Deploy

-   Testes aprovados
-   Build sem erros
-   Migrações validadas
-   RLS revisada
-   Edge Functions testadas
-   Changelog atualizado

------------------------------------------------------------------------

# 14. Checklist Pós-Deploy

Validar:

-   Login
-   Cadastro
-   Eventos
-   Restaurantes
-   Avaliações
-   Notificações
-   Uploads
-   APIs
-   Logs

------------------------------------------------------------------------

# 15. Critérios de Go Live

-   Testes aprovados
-   Aprovação técnica
-   Aprovação do Product Owner
-   Monitoramento ativo
-   Plano de rollback disponível

------------------------------------------------------------------------

# 16. Comunicação

Cada release deverá possuir:

-   Release Notes
-   Changelog
-   Registro da implantação

------------------------------------------------------------------------

# 17. Segurança

-   Nunca expor Secrets
-   Validar variáveis de ambiente
-   Registrar auditoria

------------------------------------------------------------------------

# 18. Boas Práticas

-   Deploys pequenos
-   Automação
-   Validação antes da publicação
-   Documentação das alterações

------------------------------------------------------------------------

# 19. Anti-patterns

-   Deploy manual sem validação
-   Publicação sem testes
-   Alterações diretas em produção
-   Rollback inexistente

------------------------------------------------------------------------

# 20. Critérios de Aceite

-   Estratégia documentada
-   Fluxo definido
-   Rollback previsto
-   Checklists definidos

------------------------------------------------------------------------

# 21. Checklist

-   Estratégia definida
-   Pipeline documentado
-   Ordem de deploy registrada
-   Versionamento definido
-   Rollback planejado
-   Feature Flags previstas
-   Critérios de Go Live documentados
