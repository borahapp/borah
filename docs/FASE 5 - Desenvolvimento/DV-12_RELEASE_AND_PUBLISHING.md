# DV-12 --- Release & Publishing

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-12_RELEASE_AND_PUBLISHING.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir o processo de empacotamento, versionamento, aprovação e
publicação do BORAH para garantir entregas previsíveis, seguras e
rastreáveis nas lojas de aplicativos.

------------------------------------------------------------------------

# 2. Escopo

Este documento contempla:

-   Versionamento
-   Processo de Release
-   Publicação Android
-   Publicação iOS
-   Distribuição para QA
-   Hotfix
-   Rollback
-   Release Notes
-   Go Live
-   Pós-release

------------------------------------------------------------------------

# 3. Estratégia de Versionamento

Adotar **Semantic Versioning (SemVer)**.

Formato:

``` text
MAJOR.MINOR.PATCH
```

Exemplos:

-   1.0.0
-   1.1.0
-   1.1.1

------------------------------------------------------------------------

# 4. Fluxo de Release

``` text
Development
      ↓
QA
      ↓
Staging
      ↓
Release Candidate
      ↓
Google Play / App Store
      ↓
Produção
```

------------------------------------------------------------------------

# 5. Critérios para Release

Antes da publicação:

-   Todos os testes aprovados
-   Build sem erros
-   Aprovação do QA
-   Release Notes concluídas
-   Checklist validado

------------------------------------------------------------------------

# 6. Android (Google Play)

Publicação utilizando:

-   Android App Bundle (AAB)
-   Assinatura oficial
-   Internal Testing
-   Closed Testing
-   Production

------------------------------------------------------------------------

# 7. iOS (App Store)

Distribuição utilizando:

-   TestFlight
-   App Store Connect
-   Aprovação da Apple
-   Publicação em Produção

------------------------------------------------------------------------

# 8. Gestão de Certificados

Controlar:

-   Keystore Android
-   Certificados Apple
-   Provisioning Profiles
-   Chaves de Assinatura

Armazenar segredos apenas em ambientes seguros.

------------------------------------------------------------------------

# 9. Release Notes

Cada release deverá conter:

-   Novidades
-   Correções
-   Melhorias
-   Bugs conhecidos
-   Número da versão
-   Data

------------------------------------------------------------------------

# 10. Feature Flags

Utilizar Feature Flags para:

-   Lançamentos graduais
-   Testes A/B
-   Recursos experimentais
-   Desativação rápida de funcionalidades

------------------------------------------------------------------------

# 11. Rollback

Planejar rollback para:

-   Releases críticos
-   Falhas de produção
-   Problemas de desempenho
-   Incidentes de segurança

Todo rollback deve ser registrado.

------------------------------------------------------------------------

# 12. Hotfix

Fluxo:

1.  Identificar incidente
2.  Criar branch de Hotfix
3.  Corrigir
4.  Executar testes mínimos
5.  Publicar
6.  Mesclar alterações na branch principal

------------------------------------------------------------------------

# 13. Pós-Release

Monitorar:

-   Crash Rate
-   Erros
-   Performance
-   Feedback dos usuários
-   KPIs do produto

------------------------------------------------------------------------

# 14. Segurança

-   Assinatura obrigatória dos builds
-   Proteção de certificados
-   Controle de acesso aos consoles
-   Auditoria das publicações

------------------------------------------------------------------------

# 15. Ferramentas

-   Flutter
-   GitHub Actions
-   Google Play Console
-   App Store Connect
-   TestFlight
-   Supabase
-   Firebase Crashlytics
-   Sentry

------------------------------------------------------------------------

# 16. Critérios de Go Live

-   Aprovação técnica
-   Aprovação do produto
-   Infraestrutura disponível
-   Monitoramento ativo
-   Plano de rollback validado

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Processo documentado
-   Versionamento definido
-   Publicação reproduzível
-   Rollback planejado
-   Go Live aprovado

------------------------------------------------------------------------

# 18. Checklist

-   Versionamento atualizado
-   Build gerado
-   Testes aprovados
-   Release Notes publicadas
-   Certificados válidos
-   Publicação realizada
-   Monitoramento iniciado

------------------------------------------------------------------------

# Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Deploy contínuo (CD)
-   Publicação automática nas lojas
-   Releases canário
-   Progressive Rollout
-   Automação de Release Notes
-   Aprovações eletrônicas
-   Métricas DORA por release
-   Dashboard de distribuição
