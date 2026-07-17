
# AR-06 — Supabase Setup

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-06_SUPABASE_SETUP.md

---

# 1. Objetivo

Definir a arquitetura, configuração e boas práticas para utilização do Supabase como Backend-as-a-Service (BaaS) do BORAH, garantindo segurança, escalabilidade e facilidade de manutenção.

---

# 2. Papel do Supabase

O Supabase será responsável por:

- Autenticação
- Banco de Dados PostgreSQL
- Storage
- Realtime
- Edge Functions
- Row Level Security (RLS)
- Logs e observabilidade

---

# 3. Arquitetura

```text
Flutter App
      │
      ▼
Supabase SDK
      │
 ┌────┼─────────────┐
 ▼    ▼             ▼
Auth Database   Storage
 │      │           │
 ▼      ▼           ▼
Realtime Edge Functions
```

---

# 4. Ambientes

Cada ambiente deverá possuir um projeto Supabase independente.

| Ambiente | Finalidade |
|----------|------------|
| Development | Desenvolvimento |
| Staging | Homologação |
| Production | Produção |

Nunca compartilhar banco ou chaves entre ambientes.

---

# 5. Estrutura Local

```text
backend/
└── supabase/
    ├── config/
    ├── migrations/
    ├── seed/
    ├── functions/
    ├── policies/
    ├── storage/
    └── types/
```

---

# 6. Autenticação

Métodos previstos:

- E-mail e senha
- Google
- Apple
- Refresh Token
- Sessões persistentes

Toda autenticação deverá utilizar o Supabase Auth.

---

# 7. Banco de Dados

Padrões:

- PostgreSQL
- Migrações versionadas
- Índices documentados
- Constraints explícitas
- Chaves estrangeiras obrigatórias

Nenhuma alteração deverá ser feita diretamente em produção.

---

# 8. Storage

Buckets sugeridos:

- avatars
- restaurants
- groups
- events
- feed
- temp

Aplicar políticas específicas para cada bucket.

---

# 9. Realtime

Utilizar apenas quando necessário para:

- Atualização de rankings
- Eventos
- Check-ins
- Notificações em tempo real

Evitar inscrições desnecessárias em canais.

---

# 10. Edge Functions

Responsabilidades:

- Integrações externas
- Processamentos seguros
- Webhooks
- Tarefas agendadas
- Lógica que não deve ficar no cliente

As funções devem ser pequenas, independentes e reutilizáveis.

---

# 11. Segurança

Implementar:

- Row Level Security (RLS)
- Policies por tabela
- Chaves de serviço protegidas
- Secrets em ambiente seguro
- Auditoria de acessos

Nunca expor a Service Role Key ao aplicativo.

---

# 12. Integração com Flutter

Fluxo:

```text
Riverpod
   ↓
Repository
   ↓
Datasource
   ↓
Supabase SDK
```

Toda comunicação deverá ocorrer por meio da camada Data.

---

# 13. Migrações

Regras:

- Versionadas
- Pequenas
- Reversíveis quando possível
- Revisadas antes da aplicação

Nunca editar migrações já executadas em produção.

---

# 14. Geração de Tipos

Gerar tipos do banco para Dart após alterações no schema.

Benefícios:

- Segurança de tipos
- Menos erros
- Melhor produtividade

---

# 15. Monitoramento

Acompanhar:

- Logs
- Uso de banco
- Consumo de Storage
- Execução das Edge Functions
- Erros de autenticação

---

# 16. Boas Práticas

- Utilizar RLS em todas as tabelas.
- Criar políticas com menor privilégio.
- Versionar todas as migrações.
- Separar ambientes.
- Documentar alterações estruturais.

---

# 17. Anti-patterns

Evitar:

- Desabilitar RLS
- Alterações manuais em produção
- Buckets públicos sem necessidade
- Service Role Key no aplicativo
- Funções monolíticas

---

# 18. Critérios de Aceite

- Projetos separados por ambiente
- Auth configurado
- Storage estruturado
- Migrações definidas
- Edge Functions organizadas
- Segurança documentada

---

# 19. Checklist

- Projeto Supabase criado
- Ambientes definidos
- Auth configurado
- Storage planejado
- Estrutura de migrações criada
- Realtime definido
- Edge Functions organizadas
- RLS prevista
- Tipos gerados
- Monitoramento planejado
