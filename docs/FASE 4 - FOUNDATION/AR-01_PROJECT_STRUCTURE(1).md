
# AR-01 — Project Structure (v2.0)

**Versão:** 2.0  
**Status:** Recommended  
**Documento:** AR-01_PROJECT_STRUCTURE.md

---

# 1. Objetivo

Definir a estrutura física, lógica e organizacional do projeto BORAH para garantir escalabilidade, padronização, baixo acoplamento e facilidade de manutenção.

---

# 2. Stack

- Flutter (Material 3)
- Riverpod
- GoRouter
- Freezed
- Json Serializable
- Supabase
- PostgreSQL
- Edge Functions
- GitHub Actions

---

# 3. Estrutura do Repositório

```text
borah/
├── app/
├── backend/
├── docs/
├── scripts/
├── assets/
├── .github/
├── .vscode/
├── README.md
├── LICENSE
└── .gitignore
```

---

# 4. Estrutura Completa do Flutter

```text
app/
└── lib/
    ├── core/
    │   ├── config/
    │   ├── constants/
    │   ├── environment/
    │   ├── errors/
    │   ├── extensions/
    │   ├── logger/
    │   ├── network/
    │   ├── router/
    │   ├── services/
    │   ├── theme/
    │   └── utils/
    │
    ├── design_system/
    │   ├── colors/
    │   ├── typography/
    │   ├── icons/
    │   ├── animations/
    │   ├── components/
    │   └── tokens/
    │
    ├── features/
    │   ├── auth/
    │   ├── home/
    │   ├── groups/
    │   ├── events/
    │   ├── restaurants/
    │   ├── rankings/
    │   ├── reviews/
    │   ├── notifications/
    │   ├── profile/
    │   └── settings/
    │
    ├── shared/
    ├── l10n/
    ├── app.dart
    └── main.dart
```

---

# 5. Estrutura Padrão de uma Feature

```text
feature/
├── data/
│   ├── datasources/
│   ├── dto/
│   ├── mappers/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── presentation/
│   ├── controllers/
│   ├── pages/
│   ├── providers/
│   ├── states/
│   └── widgets/
│
└── feature.dart
```

---

# 6. Regras de Dependência

- Presentation → Domain
- Data → Domain
- Domain não depende de nenhuma camada.
- Core pode ser utilizado por todas.
- Features não podem depender diretamente umas das outras.

---

# 7. Convenções

## Arquivos

- snake_case

## Classes

- PascalCase

## Variáveis

- camelCase

## Providers

Sufixo `Provider`

## Controllers

Sufixo `Controller`

## Repositories

Sufixo `Repository`

## Use Cases

Nome iniciado por verbo:

- CreateEvent
- JoinGroup
- SearchRestaurant

---

# 8. Testes

```text
test/
├── unit/
├── widget/
├── integration/
└── golden/
```

Cada feature deverá possuir testes próprios.

---

# 9. Internacionalização

```text
l10n/
├── app_pt.arb
├── app_en.arb
└── generated/
```

---

# 10. Geração de Código

Utilizar:

- build_runner
- freezed
- json_serializable

Arquivos gerados nunca devem ser editados manualmente.

---

# 11. Backend

```text
backend/
└── supabase/
    ├── migrations/
    ├── seed/
    ├── functions/
    ├── storage/
    ├── policies/
    └── config/
```

---

# 12. Documentação

```text
docs/
├── et/
├── ux/
├── ui/
├── architecture/
├── diagrams/
└── adr/
```

---

# 13. Fluxo Arquitetural

```text
UI
 ↓
Controller
 ↓
UseCase
 ↓
Repository
 ↓
Datasource
 ↓
Supabase
```

---

# 14. Critérios de Aceite

- Estrutura padronizada
- Feature First implementada
- Baixo acoplamento
- Alta reutilização
- Testabilidade
- Preparado para expansão

---

# 15. Checklist

- Estrutura definida
- Features documentadas
- Dependências padronizadas
- Convenções estabelecidas
- Testes organizados
- Internacionalização prevista
- Code Generation definida
- Backend organizado
