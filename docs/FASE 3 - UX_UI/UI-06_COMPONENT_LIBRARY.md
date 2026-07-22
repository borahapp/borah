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

---

# 16. Implementação Atual (UI-02)

Esta seção documenta o que **realmente existe** em
`app/lib/design_system/components/`, complementando as seções acima
(intenção/arquitetura recomendada).

## 16.1 Arquitetura

Continuação direta das 3 camadas do UI-01 (`AR-05`/`UI-01_DESIGN_SYSTEM.md`
§19), com uma quarta camada explícita para os componentes:

```text
Brand Tokens (design_system/brand/)
       ↓
Material Tokens (design_system/tokens/, typography/)
       ↓
ThemeData (core/theme/app_theme.dart)
       ↓
Components (design_system/components/) — este documento
       ↓
Telas/widgets de feature (lib/features/**/presentation/)
```

**Regra de dependência (nunca o inverso):** todo componente consome
`Theme.of(context).colorScheme`/`textTheme` para cor e tipografia.
Nenhum componente importa `BrandColors`/`BrandTypography`/
`BrandGradients` diretamente. Componentes **podem** usar os tokens
Material (`AppSpacing`, `AppRadius`, `AppShadows`, `AppElevation`)
diretamente para estrutura (raio, espaçamento) — são exatamente a
camada intermediária feita para isso; o que é proibido é pular direto
de um componente para a camada de identidade da marca, ou usar valores
literais fora de qualquer token.

Telas de feature devem importar
`package:app/design_system/components/components.dart` (não o barrel
`design_system.dart` completo, que também expõe `brand/` — necessário
internamente por `app_theme.dart`, mas não deveria vazar para código
de tela).

## 16.2 Componentes reaproveitados (não duplicados) — localização temporária

`AppPrimaryButton` e `AppTextField` já existiam antes do UI-02, em
`app/lib/core/widgets/`, e já eram 100% orientados a tema. **Essa
localização é temporária, não definitiva.** Permaneceram em
`core/widgets/` nesta rodada por decisão arquitetural deliberada:
mover os arquivos exigiria atualizar imports em todas as telas que já
os usam, o que o UI-02 explicitamente proibiu ("nenhuma tela deve ser
migrada") — a prioridade era reduzir o risco de regressão introduzindo
a biblioteca nova sem tocar em código de tela já testado e em
produção. São, ainda assim, parte oficial da biblioteca desde já.

**Etapa futura planejada — UI-03A (Component Migration):** migrar
definitivamente `AppPrimaryButton` e `AppTextField` (e qualquer outro
componente que permaneça fora do lugar até lá) para
`design_system/components/`, atualizando os imports das telas que os
usam, e **remover `core/widgets/`** como localização paralela depois
que a migração for concluída e validada. Até o UI-03A ser executado e
aprovado, `core/widgets/` continua sendo a localização oficial desses
dois componentes — não é uma pendência silenciosa, é uma decisão
registrada.

`AppTextField` recebeu uma extensão aditiva e retrocompatível nesta
rodada: parâmetros opcionais `prefixIcon`, `suffixIcon`,
`onSuffixIconTap`, `onChanged` (todos `null` por padrão, sem afetar
nenhuma tela existente) — necessários para compor `AppSearchField` e
`AppPasswordField` sem duplicar a implementação de `TextFormField`.

## 16.3 Componentes novos (24)

| Categoria | Componente | Arquivo |
|---|---|---|
| Botões | `AppSecondaryButton` | `components/buttons/app_secondary_button.dart` |
| Botões | `AppOutlinedButton` | `components/buttons/app_outlined_button.dart` |
| Botões | `AppTextButton` | `components/buttons/app_text_button.dart` |
| Botões | `AppIconButton` | `components/buttons/app_icon_button.dart` |
| Botões | `AppFab` | `components/buttons/app_fab.dart` |
| Campos | `AppSearchField` | `components/inputs/app_search_field.dart` |
| Campos | `AppPasswordField` | `components/inputs/app_password_field.dart` |
| Cards | `AppCard` | `components/cards/app_card.dart` |
| Cards | `RestaurantCard` | `components/cards/restaurant_card.dart` |
| Cards | `RankingCard` | `components/cards/ranking_card.dart` |
| Cards | `ReviewCard` | `components/cards/review_card.dart` |
| Feedback | `AppChip` | `components/feedback/app_chip.dart` |
| Feedback | `ScoreBubble` | `components/feedback/score_bubble.dart` |
| Feedback | `EmptyState` | `components/feedback/empty_state.dart` |
| Feedback | `SkeletonLoader` | `components/feedback/skeleton_loader.dart` |
| Feedback | `LoadingIndicator`/`LoadingScreen` | `components/feedback/loading_indicator.dart` |
| Navegação | `AppTopBar` | `components/navigation/app_top_bar.dart` |
| Navegação | `AppBottomNavigation` | `components/navigation/app_bottom_navigation.dart` |
| Navegação | `SectionHeader` | `components/navigation/section_header.dart` |
| Avatar | `UserAvatar` | `components/avatars/user_avatar.dart` |
| Badge | `AppBadge` | `components/badges/app_badge.dart` |
| Dialogs | `AppDialog` | `components/dialogs/app_dialog.dart` |
| Dialogs | `ConfirmationDialog` | `components/dialogs/confirmation_dialog.dart` |
| Bottom Sheet | `AppBottomSheet` | `components/bottom_sheets/app_bottom_sheet.dart` |

`AppChip`/`AppBadge` (não `Chip`/`Badge`) evitam colisão de nome com as
classes homônimas do próprio Flutter — mesmo cuidado já adotado no
código para `GamificationBadge`/`EarnedBadge`.

`components/layout/` existe como pasta vazia (`.gitkeep`), preparada
para primitivos estruturais futuros — nenhum componente foi atribuído
a ela nesta rodada.

## 16.4 Motivação (levantamento real, não especulação)

Cada componente novo resolve um achado concreto do levantamento do
UI-02 sobre `lib/features/**/presentation/`:

- **`ScoreBubble`** — a nota era `Text` cru em 5 lugares com formatação
  inconsistente; um caso (`rankings_page.dart`) renderizava a string
  literal `"null (3)"` quando a nota era nula.
- **`EmptyState`** — 13 mensagens de estado vazio hardcoded, cada uma
  um `Center(child: Text(...))` isolado.
- **`LoadingIndicator`/`LoadingScreen`** — canoniza o padrão uniforme
  (~25 arquivos) de `Center(child: CircularProgressIndicator())` e a
  variante pequena já usada ad hoc em `public_profile_page.dart`.
- **`AppIconButton`** — força `tooltip` obrigatório; metade dos
  `IconButton` do app não tinha (achado de acessibilidade real).
- **`ConfirmationDialog`** — nenhuma confirmação existe hoje para
  exclusão de avaliação/comentário (disparam direto).
- **`RestaurantCard`/`RankingCard`/`ReviewCard`** — hoje são `ListTile`
  cru duplicado entre 2+ arquivos cada.
- **`UserAvatar`** — versão desacoplada de `ProfileAvatar`
  (`features/users/.../profile_avatar.dart`), que resolve URL assinada
  via provider e por isso não é um componente de design system puro
  (UI-06 §2: "independentes de regras de negócio"). `ProfileAvatar`
  continua em uso, sem alteração.
- **`AppBottomNavigation`** — não existe shell de navegação inferior
  hoje (`/home` é `_BootstrapPlaceholderPage`, um placeholder
  explícito); componente pronto, não conectado a nenhuma tela ainda.

## 16.5 Exemplo de uso

```dart
import 'package:app/design_system/components/components.dart';

RestaurantCard(
  name: restaurant.name,
  category: restaurant.category,
  city: restaurant.city,
  rating: restaurant.averageRating,
  reviewCount: restaurant.totalReviews,
  onTap: () => context.push('/restaurants/${restaurant.id}'),
);
```

## 16.6 Convenções

- Todo componente é `StatelessWidget` (ou `StatefulWidget` só quando
  precisa de estado local de UI puro, ex.: `AppPasswordField` alterna
  visibilidade) — nunca lê `ProviderScope`/Riverpod diretamente.
- Cor sempre via `Theme.of(context).colorScheme`; tipografia sempre via
  `Theme.of(context).textTheme`.
- Estrutura (raio, espaçamento, sombra) via os tokens Material
  (`AppRadius`, `AppSpacing`, `AppShadows`, `AppElevation`) quando o
  Material não já oferece um slot de tema para isso.
- Toda API recebe dados primitivos (`String`, `double?`, `int?`,
  callbacks) — nenhum componente importa uma entidade de domínio de
  `features/`, mantendo o Design System desacoplado.
- Nenhum componente foi conectado a uma tela nesta rodada.

## 16.7 Pendências para o UI-03A (Component Migration)

Etapa futura específica, ainda não iniciada nem autorizada — apenas
registrada aqui como decisão arquitetural:

- Migrar `AppPrimaryButton` e `AppTextField` de `core/widgets/` para
  `design_system/components/`, atualizando os imports em todas as
  telas que os usam (ver §16.2).
- **Remover `core/widgets/`** como localização paralela depois que essa
  migração for concluída e validada (sem regressão).
- Migrar telas reais para consumir os demais novos componentes
  (substituir os `ListTile`/`Text`/`Center(CircularProgressIndicator())`
  crus identificados no levantamento do UI-02).
- Popular `components/layout/`, `design_system/icons/` e
  `design_system/animations/` (ainda `.gitkeep`).
- Avaliar promover `UserAvatar` como substituto de `ProfileAvatar` nas
  2 telas que o usam, ou aceitar a duplicação como decisão permanente.
