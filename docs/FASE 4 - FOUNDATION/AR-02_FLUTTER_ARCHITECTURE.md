
# AR-02 — Flutter Architecture

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-02_FLUTTER_ARCHITECTURE.md

---

# 1. Objetivo

Definir a arquitetura oficial do aplicativo BORAH em Flutter, estabelecendo as camadas, responsabilidades, fluxo de dados e padrões de desenvolvimento.

---

# 2. Princípios

- Feature First
- Clean Architecture Simplificada
- SOLID
- Separation of Concerns
- DRY
- KISS
- Baixo acoplamento
- Alta coesão

---

# 3. Stack

- Flutter
- Material 3
- Riverpod
- GoRouter
- Freezed
- Json Serializable
- Supabase Flutter SDK

---

# 4. Arquitetura Geral

```text
Presentation
      │
      ▼
Controller / Provider
      │
      ▼
Use Cases
      │
      ▼
Repository
      │
      ▼
Datasource
      │
      ▼
Supabase
```

---

# 5. Camadas

## Presentation

Responsável por:

- Pages
- Widgets
- Providers
- Controllers
- Estados da interface

Não acessa banco de dados diretamente.

---

## Domain

Responsável por:

- Entities
- Use Cases
- Contratos (Repositories)

Não depende de Flutter nem de Supabase.

---

## Data

Responsável por:

- Models
- DTOs
- Mappers
- Datasources
- Implementações dos Repositories

---

# 6. Organização por Feature

```text
feature/
├── data/
├── domain/
├── presentation/
└── feature.dart
```

Cada funcionalidade é independente.

---

# 7. Gerenciamento de Estado

Riverpod será utilizado para:

- Estado global
- Estado local
- Injeção de dependências
- Cache
- Providers assíncronos

---

# 8. Navegação

GoRouter será responsável por:

- Rotas nomeadas
- Deep Links
- Guards de autenticação
- Navegação declarativa

---

# 9. Comunicação com Backend

Todo acesso ao Supabase ocorrerá por meio de:

```text
UI
 ↓
Provider
 ↓
Use Case
 ↓
Repository
 ↓
Datasource
 ↓
Supabase SDK
```

---

# 10. Tratamento de Erros

Utilizar Exceptions específicas na camada Data e Failure/Result na camada Domain.

A interface deve exibir mensagens amigáveis.

---

# 11. Injeção de Dependências

Toda dependência será registrada via Riverpod Providers.

Evitar singletons globais quando possível.

---

# 12. Convenções

- Um Controller por página.
- Um Repository por domínio.
- Um Datasource por origem de dados.
- Um Use Case por ação de negócio.

---

# 13. Performance

- Lazy Loading
- Paginação
- Cache local quando necessário
- Imagens otimizadas
- Rebuilds mínimos com Riverpod

---

# 14. Testabilidade

Cada camada deverá possuir testes independentes:

- Unit Tests
- Widget Tests
- Integration Tests

---

# 15. Critérios de Aceite

- Arquitetura documentada
- Fluxo de dados definido
- Responsabilidades separadas
- Stack padronizada
- Preparada para crescimento

---

# 16. Checklist

- Camadas definidas
- Fluxo documentado
- Gerenciamento de estado escolhido
- Navegação definida
- Estratégia de erros definida
- Testabilidade prevista
