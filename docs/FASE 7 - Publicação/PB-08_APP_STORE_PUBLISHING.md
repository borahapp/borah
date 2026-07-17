# PB-08 --- App Store Publishing

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `PB-08_APP_STORE_PUBLISHING.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir o processo oficial de publicação do BORAH na Apple App Store,
garantindo uma distribuição segura, rastreável e em conformidade com as
diretrizes da Apple.

------------------------------------------------------------------------

# 2. Escopo

Aplica-se a:

-   App Store Connect
-   TestFlight
-   Builds iOS
-   Pipeline CI/CD
-   Releases de produção

------------------------------------------------------------------------

# 3. Pré-requisitos

Antes da publicação:

-   Conta Apple Developer ativa
-   App cadastrado no App Store Connect
-   Certificados válidos
-   Provisioning Profiles configurados
-   Build assinada
-   Assets e documentação aprovados

------------------------------------------------------------------------

# 4. Estratégia de Publicação

Fluxo recomendado:

Development

↓

Internal QA

↓

TestFlight

↓

Beta Testing

↓

App Review

↓

Production

------------------------------------------------------------------------

# 5. TestFlight

Utilizar para:

-   Testes internos
-   Testes externos
-   Validação de funcionalidades
-   Coleta de feedback
-   Smoke Tests

------------------------------------------------------------------------

# 6. Beta Testing

Validar:

-   Fluxos críticos
-   Performance
-   Compatibilidade
-   Segurança
-   Usabilidade

Registrar e acompanhar feedback antes da submissão final.

------------------------------------------------------------------------

# 7. App Review

Antes do envio:

-   QA aprovado
-   UAT aprovado
-   Privacy Labels preenchidos
-   Política de Privacidade publicada
-   Release Notes revisadas

Responder rapidamente a eventuais solicitações da Apple.

------------------------------------------------------------------------

# 8. Production Release

Definir estratégia de disponibilização:

-   Manual Release
-   Automatic Release
-   Scheduled Release (quando disponível)

------------------------------------------------------------------------

# 9. Versionamento

Utilizar:

-   Semantic Versioning
-   Build Number incremental

Nunca reutilizar Build Number.

------------------------------------------------------------------------

# 10. Release Notes

Cada versão deve informar:

-   Novidades
-   Correções
-   Melhorias
-   Alterações relevantes

------------------------------------------------------------------------

# 11. Monitoramento Pós-Release

Acompanhar:

-   Crash Rate
-   Avaliações
-   Downloads
-   Feedback dos usuários
-   Performance
-   Incidentes

------------------------------------------------------------------------

# 12. Ferramentas

-   App Store Connect
-   TestFlight
-   Xcode
-   GitHub Actions
-   Firebase Crashlytics
-   Sentry

------------------------------------------------------------------------

# 13. Boas Práticas

-   Testar todas as builds no TestFlight
-   Publicar releases pequenas e frequentes
-   Monitorar as primeiras 48 horas
-   Documentar todas as mudanças

------------------------------------------------------------------------

# 14. Anti-patterns

Evitar:

-   Enviar builds sem testes
-   Ignorar feedback do TestFlight
-   Publicar sem plano de rollback
-   Não acompanhar métricas após o lançamento

------------------------------------------------------------------------

# 15. Checklist

-   Build arquivada
-   Upload realizado
-   TestFlight validado
-   QA aprovado
-   Assets revisados
-   Privacy Labels preenchidos
-   Release Notes prontas
-   Publicação configurada
-   Monitoramento ativo

------------------------------------------------------------------------

# 16. Critérios de Aceite

-   Aplicativo aprovado pela Apple
-   Publicação concluída
-   Métricas estáveis
-   Sem falhas críticas
-   Documentação atualizada

------------------------------------------------------------------------

# 17. Evolução prevista (Versão 2.0)

-   Publicação totalmente automatizada via CI/CD
-   Fastlane integrado
-   Progressive Rollout por regiões
-   Feature Flags
-   Dashboards executivos de release
-   Auditoria completa das publicações
