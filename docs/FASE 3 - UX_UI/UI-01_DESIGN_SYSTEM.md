# UI-01 — Design System

**Versão:** 1.0  
**Status:** Draft  
**Documento:** UI-01_DESIGN_SYSTEM.md

---

# 1. Objetivo

Este documento define o Design System do BORAH, estabelecendo padrões visuais, componentes reutilizáveis, regras de interface e convenções para garantir consistência entre design e desenvolvimento.

O Design System será a única fonte de verdade para toda a interface do aplicativo.

---

# 2. Princípios do Design

O Design System do BORAH deve seguir os seguintes princípios:

- Simplicidade
- Consistência
- Clareza
- Acessibilidade
- Performance
- Escalabilidade
- Reutilização

---

# 3. Estrutura

O Design System será dividido em:

- Design Tokens
- Grid
- Espaçamentos
- Tipografia
- Paleta de cores
- Ícones
- Componentes
- Estados
- Motion
- Acessibilidade

---

# 4. Design Tokens

Todos os estilos deverão utilizar tokens.

Categorias:

- Colors
- Typography
- Spacing
- Radius
- Elevation
- Border
- Motion
- Opacity

Nunca utilizar valores fixos diretamente nos componentes.

---

# 5. Grid

Aplicativo baseado em:

- Grid de 8px
- Espaçamento mínimo de 8px
- Componentes alinhados à grade
- Layout responsivo

---

# 6. Espaçamentos

Escala recomendada:

- 4px
- 8px
- 12px
- 16px
- 24px
- 32px
- 40px
- 48px
- 64px

---

# 7. Bordas

Radius:

- XS
- SM
- MD
- LG
- XL
- Pill

Uso:

- Botões
- Cards
- Inputs
- Avatares
- Bottom Sheets

---

# 8. Elevação

Níveis:

- Level 0
- Level 1
- Level 2
- Level 3
- Level 4

Cada nível deverá possuir sombra padronizada.

---

# 9. Componentes

Componentes base:

- Button
- IconButton
- TextField
- SearchBar
- Card
- Restaurant Card
- Group Card
- Event Card
- Ranking Card
- Avatar
- Badge
- Chip
- Tag
- Snackbar
- Dialog
- Bottom Sheet
- FAB
- Tabs
- Bottom Navigation
- Progress Bar
- Loading
- Skeleton

---

# 10. Estados dos Componentes

Todos os componentes devem prever:

- Default
- Hover
- Focus
- Pressed
- Disabled
- Loading
- Success
- Error

---

# 11. Responsividade

Compatível com:

- Smartphones
- Tablets (futuro)

A interface deve adaptar:

- Espaçamento
- Grid
- Componentes
- Tipografia

---

# 12. Motion

Diretrizes:

- Duração entre 150 e 300 ms
- Curvas suaves
- Evitar animações excessivas
- Priorizar feedback funcional

Microinterações:

- Botões
- Check-in
- Badges
- XP
- Ranking
- Curtidas

---

# 13. Acessibilidade

Requisitos:

- Contraste adequado
- Fontes escaláveis
- Área mínima de toque de 48x48 px
- Compatibilidade com leitores de tela
- Navegação por teclado quando aplicável

---

# 14. Organização no Flutter

Estrutura sugerida:

lib/
  design_system/
    tokens/
    theme/
    components/
    icons/
    animations/

Nenhum componente deverá duplicar estilos.

---

# 15. Organização no Figma

Páginas:

- Foundations
- Components
- Patterns
- Templates
- Prototypes

Utilizar Auto Layout e Variants em todos os componentes.

---

# 16. Governança

Toda alteração no Design System deverá:

- Ser documentada
- Ser aprovada
- Atualizar Figma
- Atualizar Flutter
- Atualizar documentação

---

# 17. Critérios de Aceite

- Tokens definidos
- Componentes reutilizáveis
- Estados completos
- Acessibilidade considerada
- Responsividade prevista
- Organização padronizada

---

# 18. Checklist

- Princípios definidos
- Estrutura criada
- Tokens documentados
- Componentes listados
- Motion documentado
- Acessibilidade registrada
- Governança estabelecida

---

# 19. Arquitetura em Camadas (Implementação FASE 7A)

Implementado em `app/lib/design_system/`, com uma separação explícita
entre identidade de marca e a tradução para Material Design — nunca o
inverso:

```text
Brand Tokens (design_system/brand/)
  BrandColors, BrandGradients, BrandTypography
       ↓
Material Tokens (design_system/tokens/, design_system/typography/)
  AppColors, AppGradients (ThemeExtension), AppRadius, AppShadows,
  AppElevation, AppSpacing, AppTypography — consomem os Brand Tokens
  para derivar o que o ColorScheme/TextTheme/ThemeData conseguem usar
  (escala neutra, semânticas, pares de contraste, tamanhos/pesos)
       ↓
ThemeData (core/theme/app_theme.dart)
       ↓
Widgets (Theme.of(context) — nunca importam Brand Tokens diretamente)
```

**Regra de dependência:** `Brand Tokens` só é importado por
`design_system/tokens/`, `design_system/typography/` e
`core/theme/app_theme.dart`. Nenhum widget de tela deve importar
`design_system/brand/` diretamente — sempre via `Theme.of(context)`.

**Por que essa separação:** `BrandColors`/`BrandGradients`/
`BrandTypography` são a tradução 1:1 do Manual Oficial da Marca — só
mudam se o manual mudar. `AppColors`/`AppGradients`/`AppTypography` são
decisões de engenharia (contraste WCAG, escala neutra, ColorScheme do
Material) que podem evoluir independentemente da marca em si.
