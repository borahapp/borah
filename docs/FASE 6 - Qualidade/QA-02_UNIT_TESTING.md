# QA-02 --- Unit Testing

**Versão:** 1.0\
**Status:** Approved\
**Documento:** `QA-02_UNIT_TESTING.md`

------------------------------------------------------------------------

# 1. Objetivo

Definir a estratégia de testes unitários do BORAH para garantir que
regras de negócio, casos de uso e componentes críticos funcionem
corretamente de forma isolada, reduzindo regressões e aumentando a
confiabilidade do código.

------------------------------------------------------------------------

# 2. Escopo

Aplica-se a todos os módulos:

-   Authentication
-   Users
-   Restaurants
-   Reviews
-   Rankings
-   Favorites
-   Social
-   Administration
-   Notifications
-   Gamification

------------------------------------------------------------------------

# 3. Objetivos

-   Validar regras de negócio
-   Garantir previsibilidade
-   Facilitar refatorações
-   Detectar regressões rapidamente
-   Aumentar a qualidade do domínio

------------------------------------------------------------------------

# 4. Princípios

-   Testes independentes
-   Execução rápida
-   Dados determinísticos
-   Sem dependência de serviços externos
-   Um comportamento por teste

------------------------------------------------------------------------

# 5. Cobertura

  Camada          Cobertura mínima
  ------------- ------------------
  Domain                       90%
  Application                  85%
  Data                         80%
  Global                       85%

------------------------------------------------------------------------

# 6. Componentes Testáveis

-   Use Cases
-   Services
-   Validators
-   Mappers
-   Extensions
-   Helpers
-   Providers (quando aplicável)

------------------------------------------------------------------------

# 7. Estrutura

``` text
test/
├── unit/
│   ├── authentication/
│   ├── users/
│   ├── restaurants/
│   ├── reviews/
│   ├── rankings/
│   ├── favorites/
│   ├── social/
│   ├── notifications/
│   ├── gamification/
│   └── shared/
```

------------------------------------------------------------------------

# 8. Convenções

-   Um arquivo de teste por classe
-   Nomes descritivos
-   Padrão AAA (Arrange, Act, Assert)
-   Um cenário por teste

Exemplo:

``` text
should_return_user_when_credentials_are_valid()
```

------------------------------------------------------------------------

# 9. Mocking

Utilizar mocks apenas para:

-   Repositories
-   APIs
-   Storage
-   Clock/Date
-   Serviços externos

Evitar mockar regras de negócio.

------------------------------------------------------------------------

# 10. Casos Obrigatórios

Cada caso de uso deve validar:

-   Fluxo de sucesso
-   Entradas inválidas
-   Exceções
-   Limites
-   Regras de autorização
-   Valores nulos

------------------------------------------------------------------------

# 11. Ferramentas

-   flutter_test
-   mocktail
-   build_runner
-   coverage

------------------------------------------------------------------------

# 12. Execução

Executar automaticamente:

-   Em Pull Requests
-   Antes de merge
-   Antes da geração de Release

------------------------------------------------------------------------

# 13. Critérios de Aprovação

-   Cobertura mínima atingida
-   Todos os testes aprovados
-   Sem testes ignorados
-   Sem flakiness

------------------------------------------------------------------------

# 14. Boas Práticas

-   Dados previsíveis
-   Evitar dependência de ordem
-   Não acessar banco de dados
-   Não acessar internet
-   Não reutilizar estado entre testes

------------------------------------------------------------------------

# 15. Anti-patterns

Evitar:

-   Testes lentos
-   Testes duplicados
-   Mocks excessivos
-   Asserções genéricas
-   Dependência de tempo real

------------------------------------------------------------------------

# 16. Métricas

Monitorar:

-   Cobertura
-   Tempo de execução
-   Taxa de sucesso
-   Regressões detectadas
-   Testes por módulo

------------------------------------------------------------------------

# 17. Critérios de Aceite

-   Estratégia documentada
-   Estrutura padronizada
-   Cobertura mínima definida
-   Pipeline automatizado
-   Boas práticas aplicadas

------------------------------------------------------------------------

# 18. Checklist

-   Estrutura criada
-   Ferramentas configuradas
-   Cobertura monitorada
-   Mocks padronizados
-   Testes automatizados no CI
-   Relatórios gerados

------------------------------------------------------------------------

# 19. Evolução prevista (Versão 2.0)

Planejar suporte para:

-   Mutation Testing
-   Property-Based Testing
-   Geração automática de dados de teste
-   Relatórios históricos
-   Quality Gates por módulo
