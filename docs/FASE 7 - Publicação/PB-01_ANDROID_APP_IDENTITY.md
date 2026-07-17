# PB-01 --- Android App Identity

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `PB-01_ANDROID_APP_IDENTITY.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a identidade técnica do aplicativo Android do **BORAH**,
incluindo nomenclatura, Application ID, versionamento, assinatura,
idiomas e configurações obrigatórias para publicação na Google Play.

# 2. Escopo

-   Flutter Android
-   Google Play Console
-   CI/CD
-   Development, Staging e Production

# 3. Identificação

  Campo         Valor
  ------------- -----------
  Nome          BORAH
  Organização   com.borah
  Plataforma    Android
  Framework     Flutter

# 4. Application ID

Produção: `com.borah.app`

Staging: `com.borah.app.staging`

Development: `com.borah.app.dev`

O Application ID não deve ser alterado após a primeira publicação.

# 5. Nome do Aplicativo

-   Exibição: BORAH
-   Consistente em todas as plataformas

# 6. Versionamento

Utilizar Semantic Versioning:

`MAJOR.MINOR.PATCH`

Exemplo:

-   1.0.0
-   1.0.1
-   1.1.0
-   2.0.0

# 7. Version Code

Incremental e exclusivo para cada release.

# 8. Idiomas

-   Português (Brasil)
-   Inglês

# 9. Deep Links

-   borah://
-   https://app.borah.com/

# 10. Android App Links

Implementar App Links verificados.

# 11. Assinatura

-   Keystore exclusiva
-   Backup seguro
-   Play App Signing

# 12. Build Variants

-   Development
-   Staging
-   Production

# 13. Configurações Obrigatórias

-   Namespace definido
-   Min SDK
-   Target SDK
-   Compile SDK atualizado

# 14. Boas Práticas

-   Não alterar Application ID
-   Versionar todas as releases
-   Automatizar Version Code
-   Separar ambientes

# 15. Anti-patterns

-   Version Code duplicado
-   Builds de produção usando ambiente de desenvolvimento
-   Reutilização inadequada de certificados

# 16. Checklist

-   Nome definido
-   Application IDs configurados
-   SemVer adotado
-   Version Code incremental
-   Idiomas configurados
-   Deep Links definidos
-   Keystore protegida
-   Play App Signing habilitado

# 17. Critérios de Aceite

-   Identidade documentada
-   Versionamento padronizado
-   Assinatura configurada
-   Aplicativo apto para publicação

# 18. Evolução 2.0

-   White-label
-   Multi-brand
-   Versionamento automático
-   Assinatura automatizada via CI/CD
