# DV-02 --- Users Module

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `DV-02_USERS_MODULE.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a implementação completa do módulo de usuários do BORAH,
responsável pelo gerenciamento do perfil, preferências e informações
pessoais do usuário autenticado.

------------------------------------------------------------------------

# 2. Escopo

Este módulo contempla:

-   Perfil
-   Editar Perfil
-   Avatar (Foto)
-   Preferências
-   Configurações da Conta
-   Privacidade
-   Visualização de Perfil

------------------------------------------------------------------------

# 3. Regras de Negócio

-   Todo perfil pertence a um único usuário autenticado.
-   O usuário pode editar apenas o próprio perfil.
-   O e-mail é gerenciado pelo módulo de autenticação.
-   A foto de perfil será armazenada no Supabase Storage.
-   Alterações devem refletir imediatamente na aplicação.

------------------------------------------------------------------------

# 4. Fluxo Funcional

``` text
Login
   ↓
Carregar Perfil
   ↓
Visualizar Perfil
   ↓
Editar Dados
   ↓
Salvar Alterações
   ↓
Atualizar Banco
   ↓
Atualizar Interface
```

------------------------------------------------------------------------

# 5. Funcionalidades

## Perfil

-   Nome
-   Username (futuro)
-   Biografia
-   Cidade
-   Estado
-   Foto
-   Data de cadastro

## Editar Perfil

-   Alterar nome
-   Alterar biografia
-   Alterar localização
-   Alterar foto

## Preferências

-   Tema (futuro)
-   Idioma (futuro)
-   Notificações
-   Privacidade

------------------------------------------------------------------------

# 6. Telas

-   Perfil
-   Editar Perfil
-   Alterar Foto
-   Preferências
-   Configurações

------------------------------------------------------------------------

# 7. Arquitetura

``` text
Presentation
      ↓
Controller
      ↓
Use Case
      ↓
Repository
      ↓
Datasource
      ↓
Supabase Database
        +
Supabase Storage
```

------------------------------------------------------------------------

# 8. Estrutura do Módulo

``` text
users/
├── data/
├── domain/
├── presentation/
├── providers/
├── widgets/
└── users.dart
```

------------------------------------------------------------------------

# 9. Modelo de Dados

  Campo        Tipo
  ------------ -----------
  id           UUID
  full_name    String
  bio          String
  avatar_url   String
  city         String
  state        String
  created_at   Timestamp
  updated_at   Timestamp

------------------------------------------------------------------------

# 10. Estados

-   Initial
-   Loading
-   Loaded
-   Updating
-   Success
-   Error

------------------------------------------------------------------------

# 11. Upload da Foto

Fluxo:

``` text
Selecionar Imagem
      ↓
Validar
      ↓
Comprimir
      ↓
Upload Storage
      ↓
Atualizar avatar_url
      ↓
Atualizar Interface
```

Regras:

-   Máximo 5 MB
-   JPG, PNG ou WEBP
-   Compressão antes do upload

------------------------------------------------------------------------

# 12. Tratamento de Erros

Casos previstos:

-   Perfil não encontrado
-   Falha no upload
-   Arquivo inválido
-   Sem conexão
-   Erro de atualização
-   Permissão negada

------------------------------------------------------------------------

# 13. Segurança

-   RLS habilitada na tabela de usuários
-   Usuário altera apenas o próprio perfil
-   Upload protegido por políticas do Storage
-   URLs assinadas quando necessário

------------------------------------------------------------------------

# 14. Integração

## Banco

-   Buscar perfil
-   Atualizar perfil

## Storage

-   Upload de avatar
-   Remoção da foto anterior (quando aplicável)

------------------------------------------------------------------------

# 15. Testes

Executar:

-   Carregamento do perfil
-   Atualização dos dados
-   Upload de foto
-   Atualização de preferências
-   Falhas de upload
-   Tentativa de editar outro usuário

------------------------------------------------------------------------

# 16. Critérios de Aceite

-   Perfil carregado corretamente
-   Edição funcionando
-   Upload de foto operacional
-   Preferências persistidas
-   Segurança validada

------------------------------------------------------------------------

# 17. Checklist

-   Perfil implementado
-   Edição implementada
-   Avatar implementado
-   Preferências implementadas
-   Integração com Storage
-   Testes concluídos

------------------------------------------------------------------------

# 18. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Username exclusivo
-   Redes sociais
-   Foto de capa
-   Histórico de alterações
-   Perfil público/privado
-   Estatísticas do usuário
-   Conta verificada
-   Exportação de dados (LGPD)
-   Exclusão da conta
