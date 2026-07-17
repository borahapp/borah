# AR-17 --- Environments

**Versão:** 2.0\
**Status:** Recommended\
**Documento:** `AR-17_ENVIRONMENTS.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a arquitetura dos ambientes do BORAH, garantindo isolamento,
segurança, consistência e previsibilidade durante o desenvolvimento,
testes, homologação e produção.

------------------------------------------------------------------------

# 2. Objetivos

-   Isolamento entre ambientes
-   Segurança das informações
-   Reprodutibilidade
-   Facilidade de promoção entre ambientes
-   Redução de riscos em produção

------------------------------------------------------------------------

# 3. Ambientes

  Ambiente      Finalidade
  ------------- -------------------------------------------
  Development   Desenvolvimento local
  QA            Testes funcionais e integração
  Staging       Homologação antes da produção
  Production    Ambiente oficial dos usuários
  Sandbox       Testes experimentais e provas de conceito

------------------------------------------------------------------------

# 4. Arquitetura

``` text
Developer
    │
    ▼
Development
    │
    ▼
QA
    │
    ▼
Staging
    │
    ▼
Production
```

Cada ambiente deverá possuir infraestrutura e configurações
independentes.

------------------------------------------------------------------------

# 5. Recursos por Ambiente

Cada ambiente deverá possuir:

-   Projeto Supabase dedicado
-   Banco de dados independente
-   Buckets do Storage independentes
-   Edge Functions próprias
-   Secrets específicos
-   Pipeline de deploy correspondente

------------------------------------------------------------------------

# 6. Banco de Dados

Não compartilhar bancos entre ambientes.

Cada ambiente possuirá:

-   Esquema atualizado
-   Migrações versionadas
-   Dados apropriados ao ambiente

------------------------------------------------------------------------

# 7. Dados

## Development

-   Dados fictícios
-   Massa para desenvolvimento

## QA

-   Dados controlados
-   Cenários de teste

## Staging

-   Dados anonimizados quando necessário
-   Simulação fiel da produção

## Production

-   Dados reais dos usuários

------------------------------------------------------------------------

# 8. Configurações

Cada ambiente deverá possuir:

-   Arquivo `.env`
-   Secrets próprios
-   Chaves exclusivas
-   URLs específicas

Nunca reutilizar credenciais entre ambientes.

------------------------------------------------------------------------

# 9. Controle de Acesso

  Ambiente      Acesso
  ------------- ---------------------------
  Development   Equipe de desenvolvimento
  QA            QA e Engenharia
  Staging       Engenharia e Produto
  Production    Equipe autorizada

------------------------------------------------------------------------

# 10. Promoção entre Ambientes

Fluxo oficial:

``` text
Development
      ↓
QA
      ↓
Staging
      ↓
Production
```

A promoção somente ocorrerá após validação do ambiente anterior.

------------------------------------------------------------------------

# 11. Deploy

Cada ambiente deverá possuir pipeline própria, com aprovações
compatíveis com o nível de criticidade.

------------------------------------------------------------------------

# 12. Monitoramento

Monitorar separadamente:

-   Logs
-   Métricas
-   Falhas
-   Consumo de recursos

Não misturar informações entre ambientes.

------------------------------------------------------------------------

# 13. Segurança

-   Secrets independentes
-   Buckets separados
-   Banco isolado
-   Controle de acesso por função
-   Auditoria de alterações

------------------------------------------------------------------------

# 14. Convenções

Exemplos:

``` text
borah-dev
borah-qa
borah-staging
borah-prod
```

------------------------------------------------------------------------

# 15. Boas Práticas

-   Nunca testar diretamente em produção.
-   Automatizar promoções.
-   Validar migrações em Staging.
-   Utilizar dados anonimizados fora da produção.
-   Revisar acessos periodicamente.

------------------------------------------------------------------------

# 16. Anti-patterns

Evitar:

-   Compartilhar banco entre ambientes
-   Reutilizar Secrets
-   Testes em produção
-   Dados reais em Development
-   Deploy direto para produção sem homologação

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Ambientes documentados
-   Infraestrutura isolada
-   Fluxo de promoção definido
-   Segurança aplicada
-   Controle de acesso estabelecido

------------------------------------------------------------------------

# 18. Checklist

-   Ambientes definidos
-   Recursos separados
-   Banco isolado
-   Storage independente
-   Secrets separados
-   Fluxo de promoção documentado
-   Segurança prevista
-   Boas práticas registradas

------------------------------------------------------------------------

# Evolução prevista (Versão 3.0)

Recomenda-se incluir:

-   Diagramas Mermaid da arquitetura dos ambientes.
-   Estratégia de criação automática de ambientes efêmeros para Pull
    Requests.
-   Catálogo de configurações por ambiente.
-   Matriz de permissões por equipe.
-   Estratégia de sincronização de esquemas e dados.
-   Processo de desativação e recriação de ambientes.
-   Indicadores de custo e utilização por ambiente.
