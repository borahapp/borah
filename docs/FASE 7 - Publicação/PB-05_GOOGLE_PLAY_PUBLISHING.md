# PB-05 --- Google Play Publishing

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `PB-05_GOOGLE_PLAY_PUBLISHING.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir o processo oficial de publicação do BORAH na Google Play Store,
garantindo uma distribuição segura, rastreável e alinhada às políticas
da Google.

------------------------------------------------------------------------

# 2. Escopo

Aplica-se a:

-   Google Play Console
-   Android App Bundle (AAB)
-   Pipeline CI/CD
-   Releases de produção

------------------------------------------------------------------------

# 3. Pré-requisitos

Antes da publicação:

-   Conta Google Play Developer ativa
-   App criado no Play Console
-   Play App Signing habilitado
-   AAB gerado
-   Version Code atualizado
-   Assets e documentação aprovados

------------------------------------------------------------------------

# 4. Estratégia de Publicação

Fluxo recomendado:

Development → Internal Testing → Closed Testing → Open Testing
(opcional) → Production

------------------------------------------------------------------------

# 5. Internal Testing

Objetivos:

-   Validar instalação
-   Smoke Tests
-   Verificar integrações
-   Testar builds iniciais

------------------------------------------------------------------------

# 6. Closed Testing

Validar:

-   Funcionalidades críticas
-   Performance
-   Segurança
-   Compatibilidade

Grupo composto por usuários selecionados.

------------------------------------------------------------------------

# 7. Open Testing

Opcional para:

-   Coleta de feedback
-   Validação em larga escala
-   Identificação de problemas antes da produção

------------------------------------------------------------------------

# 8. Production Release

Antes da publicação:

-   QA aprovado
-   UAT aprovado
-   Release Notes concluídas
-   Checklist validado
-   Plano de rollback disponível

------------------------------------------------------------------------

# 9. Versionamento

Utilizar:

-   Semantic Versioning
-   Version Code incremental

Nunca reutilizar Version Code.

------------------------------------------------------------------------

# 10. Release Notes

Cada versão deve incluir:

-   Novidades
-   Correções
-   Melhorias
-   Problemas conhecidos (quando aplicável)

------------------------------------------------------------------------

# 11. Rollout

Preferencialmente utilizar:

-   5%
-   10%
-   25%
-   50%
-   100%

Expandindo conforme estabilidade.

------------------------------------------------------------------------

# 12. Monitoramento Pós-Release

Acompanhar:

-   Crash Rate
-   ANRs
-   Avaliações
-   Feedback
-   Instalações
-   Desinstalações

------------------------------------------------------------------------

# 13. Ferramentas

-   Google Play Console
-   GitHub Actions
-   Firebase Crashlytics
-   Sentry
-   Supabase Dashboard

------------------------------------------------------------------------

# 14. Boas Práticas

-   Publicações graduais
-   Releases pequenas e frequentes
-   Monitoramento nas primeiras 48 horas
-   Comunicação das mudanças

------------------------------------------------------------------------

# 15. Anti-patterns

Evitar:

-   Publicação direta sem testes
-   Rollout de 100% imediato
-   Ausência de Release Notes
-   Ignorar métricas da Play Console

------------------------------------------------------------------------

# 16. Checklist

-   Build AAB gerada
-   Versionamento atualizado
-   QA aprovado
-   Assets revisados
-   Política de Privacidade publicada
-   Release Notes prontas
-   Rollout configurado
-   Monitoramento ativo

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Aplicativo publicado com sucesso
-   Sem erros críticos
-   Rollout concluído
-   Métricas estáveis
-   Documentação atualizada

------------------------------------------------------------------------

# 18. Evolução prevista (Versão 2.0)

-   Publicação totalmente automatizada via CI/CD
-   Progressive Delivery
-   Feature Flags
-   Rollback automático
-   Dashboards executivos de release
