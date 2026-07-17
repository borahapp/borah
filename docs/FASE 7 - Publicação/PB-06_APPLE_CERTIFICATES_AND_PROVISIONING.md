# PB-06 --- Apple Certificates & Provisioning

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `PB-06_APPLE_CERTIFICATES_AND_PROVISIONING.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir o processo de configuração de certificados, identificadores e
perfis de provisionamento necessários para distribuir o BORAH no
ecossistema Apple de forma segura e padronizada.

------------------------------------------------------------------------

# 2. Escopo

Aplica-se a:

-   Apple Developer Program
-   App Store Connect
-   Flutter iOS
-   Xcode
-   CI/CD
-   Ambientes Development, TestFlight e Production

------------------------------------------------------------------------

# 3. Pré-requisitos

-   Conta Apple Developer ativa
-   App Store Connect configurado
-   Acesso administrativo ao projeto
-   Bundle ID definido
-   Projeto iOS inicializado

------------------------------------------------------------------------

# 4. Bundle Identifier

Produção: `com.borah.app`

Staging: `com.borah.app.staging`

Development: `com.borah.app.dev`

O Bundle Identifier não deve ser alterado após a publicação.

------------------------------------------------------------------------

# 5. Certificados

Configurar:

-   Apple Development
-   Apple Distribution

Diretrizes:

-   Armazenamento seguro
-   Renovação antes do vencimento
-   Controle de acesso

------------------------------------------------------------------------

# 6. Provisioning Profiles

Criar perfis para:

-   Development
-   Ad Hoc (quando necessário)
-   App Store Distribution

Associar corretamente certificados, dispositivos e Bundle ID.

------------------------------------------------------------------------

# 7. App IDs e Capabilities

Habilitar apenas os recursos utilizados, como:

-   Push Notifications
-   Associated Domains
-   Sign in with Apple (quando aplicável)
-   Keychain Sharing
-   Background Modes

------------------------------------------------------------------------

# 8. APNs

Configurar:

-   Chave APNs (.p8)
-   Team ID
-   Key ID
-   Integração com Firebase ou serviço equivalente

------------------------------------------------------------------------

# 9. Assinatura Automática

Preferencialmente utilizar assinatura automática do Xcode para ambientes
de desenvolvimento e gerenciamento controlado para produção.

------------------------------------------------------------------------

# 10. CI/CD

Automatizar:

-   Importação segura de certificados
-   Provisioning Profiles
-   Build iOS
-   Archive
-   Upload para TestFlight

------------------------------------------------------------------------

# 11. Ferramentas

-   Apple Developer
-   App Store Connect
-   Xcode
-   Fastlane (opcional)
-   GitHub Actions

------------------------------------------------------------------------

# 12. Boas Práticas

-   Renovar certificados antecipadamente
-   Utilizar contas institucionais
-   Armazenar segredos em cofres seguros
-   Documentar todas as capacidades habilitadas

------------------------------------------------------------------------

# 13. Anti-patterns

Evitar:

-   Certificados compartilhados sem controle
-   Chaves privadas em repositórios
-   Capabilities desnecessárias
-   Perfis expirados em produção

------------------------------------------------------------------------

# 14. Checklist

-   Conta Apple Developer ativa
-   Bundle ID criado
-   Certificados emitidos
-   Provisioning Profiles configurados
-   APNs configurado
-   Capabilities revisadas
-   CI/CD preparado

------------------------------------------------------------------------

# 15. Critérios de Aceite

-   Certificados válidos
-   Perfis funcionais
-   Build assinada corretamente
-   Upload para TestFlight realizado com sucesso

------------------------------------------------------------------------

# 16. Evolução prevista (Versão 2.0)

-   Fastlane completo
-   Rotação automatizada de certificados
-   Gerenciamento centralizado de segredos
-   Publicação iOS totalmente automatizada
