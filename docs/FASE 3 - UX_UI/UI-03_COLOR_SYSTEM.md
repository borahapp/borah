# UI-03 — Color System

**Versão:** 1.0  
**Status:** Draft  
**Documento:** UI-03_COLOR_SYSTEM.md

---

# 1. Objetivo

Este documento define o Sistema de Cores do BORAH, estabelecendo a paleta oficial, regras de utilização, hierarquia visual e diretrizes para Light Mode e Dark Mode.

O Color System garante consistência visual, acessibilidade e escalabilidade em todas as interfaces do produto.

---

# 2. Princípios

O sistema de cores deve:

- Facilitar a identificação das ações.
- Garantir contraste e legibilidade.
- Reforçar a identidade da marca.
- Funcionar em diferentes dispositivos.
- Ser compatível com acessibilidade (WCAG).

---

# 3. Estrutura do Sistema

As cores serão organizadas em:

- Brand Colors
- Semantic Colors
- Neutral Colors
- Background Colors
- Surface Colors
- Border Colors
- Text Colors
- Overlay Colors

Todas deverão ser implementadas como Design Tokens.

---

# 4. Brand Colors

## Primary

Cor principal da marca.

Aplicações:

- Botões primários
- Links
- Componentes ativos
- Destaques

## Secondary

Utilizada para:

- Componentes auxiliares
- Ícones
- Estados secundários

## Accent

Utilizada para:

- Gamificação
- XP
- Badges
- Conquistas
- Elementos promocionais

---

# 5. Semantic Colors

## Success

Utilizada para:

- Confirmações
- Operações concluídas
- Check-in realizado

## Warning

Utilizada para:

- Alertas
- Informações importantes

## Error

Utilizada para:

- Falhas
- Validações
- Erros críticos

## Info

Utilizada para:

- Mensagens informativas
- Dicas
- Tutoriais

---

# 6. Neutral Colors

Escala recomendada:

- Neutral 50
- Neutral 100
- Neutral 200
- Neutral 300
- Neutral 400
- Neutral 500
- Neutral 600
- Neutral 700
- Neutral 800
- Neutral 900

Aplicações:

- Fundos
- Bordas
- Textos
- Cards

---

# 7. Background

Tipos:

- Background Primary
- Background Secondary
- Background Elevated

---

# 8. Surface

Tipos:

- Surface Primary
- Surface Secondary
- Surface Inverse

Utilizadas para:

- Cards
- Bottom Sheets
- Dialogs
- Menus

---

# 9. Text Colors

Categorias:

- Primary Text
- Secondary Text
- Disabled Text
- Inverse Text
- Link Text

Todo texto deve respeitar contraste mínimo recomendado.

---

# 10. Border Colors

Categorias:

- Default
- Focus
- Disabled
- Error

---

# 11. Overlay

Utilizado em:

- Modais
- Bottom Sheets
- Menus
- Loading

Opacidade recomendada:

40% a 70%.

---

# 12. Light Mode

No modo claro:

- Fundo predominantemente claro.
- Textos escuros.
- Superfícies claras.
- Alto contraste.

---

# 13. Dark Mode

No modo escuro:

- Fundo predominantemente escuro.
- Superfícies elevadas.
- Textos claros.
- Contraste preservado.

---

# 14. Estados dos Componentes

Cada componente deverá possuir cores específicas para:

- Default
- Hover
- Focus
- Pressed
- Disabled
- Loading
- Success
- Error

---

# 15. Tokens

Exemplo de nomenclatura:

- color.brand.primary
- color.brand.secondary
- color.semantic.success
- color.semantic.error
- color.background.primary
- color.surface.primary
- color.text.primary
- color.border.default

---

# 16. Acessibilidade

Todos os pares de cores deverão atender às recomendações WCAG:

- Texto normal: contraste mínimo de 4.5:1
- Texto grande: contraste mínimo de 3:1
- Elementos interativos claramente distinguíveis

Nunca depender apenas da cor para transmitir significado.

---

# 17. Implementação

No Flutter:

- Todas as cores deverão ser centralizadas no ThemeData.
- Não utilizar valores HEX diretamente nos widgets.
- Utilizar apenas Design Tokens.

No Figma:

- Utilizar Variables.
- Organizar por categorias.
- Evitar cores duplicadas.

---

# 18. Governança

Alterações no sistema de cores deverão:

- Ser documentadas.
- Atualizar os tokens.
- Atualizar o Figma.
- Atualizar o Flutter.
- Passar por revisão de acessibilidade.

---

# 19. Critérios de Aceite

- Sistema de cores documentado.
- Tokens definidos.
- Light Mode previsto.
- Dark Mode previsto.
- Acessibilidade considerada.
- Estrutura compatível com o Design System.

---

# 20. Checklist

- Estrutura definida.
- Categorias documentadas.
- Tokens nomeados.
- Light Mode previsto.
- Dark Mode previsto.
- Acessibilidade validada.
- Governança estabelecida.
