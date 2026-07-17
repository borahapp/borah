# UI-06 — Component Library

**Versão:** 1.0  
**Status:** Draft  
**Documento:** UI-06_COMPONENT_LIBRARY.md

---

# 1. Objetivo

Definir a biblioteca oficial de componentes do BORAH, estabelecendo padrões de construção, comportamento e reutilização para todas as interfaces do aplicativo.

Este documento serve como referência para designers (Figma) e desenvolvedores (Flutter).

---

# 2. Princípios

Todos os componentes devem ser:

- Reutilizáveis
- Consistentes
- Acessíveis
- Responsivos
- Configuráveis
- Independentes de regras de negócio

---

# 3. Estrutura da Biblioteca

Os componentes serão organizados em quatro níveis:

- Foundations
- Base Components
- Composite Components
- Templates

---

# 4. Foundations

Elementos básicos:

- Cores
- Tipografia
- Espaçamentos
- Radius
- Elevação
- Ícones
- Motion

---

# 5. Base Components

## Buttons

Variantes:

- Primary
- Secondary
- Tertiary
- Text
- Icon Button
- FAB

Estados:

- Default
- Hover
- Focus
- Pressed
- Disabled
- Loading

---

## Inputs

Componentes:

- Text Field
- Password
- Search
- Number
- Date
- Dropdown
- Multi-line

Estados:

- Default
- Focus
- Filled
- Error
- Disabled

---

## Selection

- Checkbox
- Radio
- Switch
- Chip
- Segmented Control

---

## Feedback

- Snackbar
- Dialog
- Bottom Sheet
- Tooltip
- Banner
- Progress Indicator
- Skeleton
- Loading Spinner

---

## Navigation

- Bottom Navigation
- Top App Bar
- Navigation Drawer (futuro)
- Tabs
- Breadcrumb (Admin)

---

# 6. Composite Components

## Restaurant Card

Conteúdo:

- Foto
- Nome
- Categoria
- Nota
- Distância
- Favorito

Ações:

- Abrir detalhes
- Favoritar

---

## Group Card

- Nome
- Integrantes
- Próximo evento
- Ranking

---

## Event Card

- Restaurante
- Data
- Hora
- Participantes
- Status

---

## Ranking Card

- Avatar
- Nome
- XP
- Nível
- Posição

---

## Badge Card

- Ícone
- Nome
- Descrição
- Raridade

---

## Notification Card

- Ícone
- Título
- Mensagem
- Data
- Estado

---

# 7. Templates

Layouts reutilizáveis:

- Lista de restaurantes
- Lista de grupos
- Lista de eventos
- Perfil
- Ranking
- Feed
- Configurações
- Formulários

---

# 8. Estados

Todos os componentes interativos devem possuir:

- Default
- Hover
- Focus
- Pressed
- Disabled
- Loading
- Success
- Error
- Empty

---

# 9. Responsividade

Compatível com:

- Smartphones
- Tablets (futuro)

Adaptar:

- Espaçamento
- Grid
- Tipografia
- Componentes

---

# 10. Acessibilidade

Requisitos:

- Área mínima de toque de 48x48 px
- Labels acessíveis
- Navegação por teclado quando aplicável
- Contraste conforme WCAG
- Feedback visual e textual

---

# 11. Organização

## Flutter

lib/
  design_system/
    components/
      buttons/
      inputs/
      cards/
      navigation/
      feedback/
      layouts/

## Figma

Pages:

- Foundations
- Components
- Patterns
- Templates

Todos os componentes devem utilizar Auto Layout, Variants e Component Properties.

---

# 12. Convenções

Cada componente deverá documentar:

- Objetivo
- Anatomia
- Propriedades
- Variantes
- Estados
- Regras de uso
- Casos em que não utilizar
- Exemplo visual
- Widget Flutter correspondente

---

# 13. Governança

Novos componentes deverão:

- Ser aprovados
- Ser documentados
- Ser implementados no Figma
- Ser implementados no Flutter
- Possuir testes

---

# 14. Critérios de Aceite

- Biblioteca organizada
- Componentes reutilizáveis
- Estados documentados
- Compatibilidade entre Figma e Flutter
- Acessibilidade considerada

---

# 15. Checklist

- Foundations definidos
- Base Components documentados
- Composite Components definidos
- Templates identificados
- Estados completos
- Organização Flutter definida
- Organização Figma definida
- Governança estabelecida
