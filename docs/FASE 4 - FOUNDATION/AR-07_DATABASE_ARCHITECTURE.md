
# AR-07 — Database Architecture

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-07_DATABASE_ARCHITECTURE.md

---

# 1. Objetivo

Definir a arquitetura física do banco de dados PostgreSQL utilizado pelo Supabase, estabelecendo padrões para modelagem, organização, desempenho, segurança e evolução do schema do BORAH.

---

# 2. Princípios

- Modelagem normalizada
- Integridade referencial
- Escalabilidade
- Segurança por padrão
- Alta performance
- Versionamento por migrações

---

# 3. Tecnologia

- PostgreSQL
- Supabase Database
- SQL
- Row Level Security (RLS)

---

# 4. Estrutura do Banco

```text
Supabase
└── PostgreSQL
    ├── Schemas
    ├── Tables
    ├── Views
    ├── Functions
    ├── Triggers
    ├── Policies
    └── Indexes
```

---

# 5. Schemas

| Schema | Finalidade |
|---------|------------|
| public | Dados da aplicação |
| auth | Gerenciado pelo Supabase |
| storage | Arquivos |
| realtime | Eventos em tempo real |

Evitar criar schemas sem necessidade.

---

# 6. Convenções

## Tabelas

- snake_case
- plural

Exemplos:

- users
- groups
- group_members
- events
- restaurants
- reviews
- rankings

## Colunas

- snake_case
- nomes descritivos

## Chaves Primárias

- UUID

## Datas

- created_at
- updated_at
- deleted_at (soft delete quando aplicável)

---

# 7. Relacionamentos

- Utilizar chaves estrangeiras.
- Definir ações ON DELETE e ON UPDATE explicitamente.
- Evitar relacionamentos circulares.

---

# 8. Índices

Criar índices para:

- Chaves estrangeiras
- Colunas de busca
- Ordenações frequentes
- Filtros recorrentes

Revisar periodicamente índices não utilizados.

---

# 9. Constraints

Utilizar:

- PRIMARY KEY
- FOREIGN KEY
- UNIQUE
- CHECK
- NOT NULL

Toda regra estrutural deve ser aplicada no banco sempre que possível.

---

# 10. Views

Utilizar para:

- Relatórios
- Consultas complexas
- Dashboards
- Agregações

Evitar lógica de negócio em Views.

---

# 11. Functions e Triggers

Functions:

- Regras reutilizáveis
- Processamentos internos

Triggers:

- Auditoria
- Atualização automática de timestamps
- Consistência de dados

Triggers devem ser pequenas e previsíveis.

---

# 12. Segurança

- RLS habilitada em todas as tabelas.
- Políticas baseadas em autenticação.
- Menor privilégio possível.
- Service Role apenas no backend.

---

# 13. Performance

Boas práticas:

- Evitar SELECT *
- Paginação
- EXPLAIN ANALYZE para consultas críticas
- Índices revisados
- Consultas otimizadas

---

# 14. Migrações

Todas as alterações deverão:

- Ser versionadas
- Ser revisadas
- Ser aplicadas via Supabase CLI
- Nunca ser feitas manualmente em produção

---

# 15. Backup

Prever:

- Backup automático
- Testes de restauração
- Estratégia de recuperação

---

# 16. Observabilidade

Monitorar:

- Tempo de consulta
- Locks
- Conexões
- Crescimento do banco
- Índices

---

# 17. Boas Práticas

- UUID como identificador.
- Soft delete apenas quando necessário.
- Evitar duplicação de dados.
- Documentar novas tabelas.
- Revisar consultas críticas.

---

# 18. Anti-patterns

Evitar:

- Chaves inteiras auto incrementais para entidades principais.
- Ausência de índices.
- Dados duplicados.
- Constraints apenas na aplicação.
- Alterações diretas em produção.

---

# 19. Critérios de Aceite

- Schemas definidos
- Convenções documentadas
- Relacionamentos consistentes
- Índices planejados
- Segurança prevista
- Estratégia de migrações definida

---

# 20. Checklist

- Schemas organizados
- Convenções definidas
- Relacionamentos documentados
- Constraints previstas
- Índices planejados
- Views definidas
- Functions e Triggers documentadas
- RLS prevista
- Migrações padronizadas
- Backup planejado
