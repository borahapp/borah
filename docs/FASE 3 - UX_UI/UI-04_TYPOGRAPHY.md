# UI-04 — Typography

**Versão:** 1.0  
**Status:** Draft  
**Documento:** UI-04_TYPOGRAPHY.md

---

# 1. Objetivo

Este documento define o sistema tipográfico oficial do BORAH, estabelecendo diretrizes para o uso de fontes, hierarquia textual, escalas, pesos e boas práticas de legibilidade.

O Typography System garante consistência visual, acessibilidade e uma experiência de leitura agradável em todas as interfaces do produto.

---

# 2. Princípios

A tipografia do BORAH deve ser:

- Clara
- Legível
- Moderna
- Consistente
- Escalável
- Acessível

---

# 3. Fonte Principal

**Família recomendada:**

- Inter

Alternativas (fallback):

- Roboto
- SF Pro (iOS)
- Sans-serif

A escolha poderá ser revisada caso haja necessidade de reforçar a identidade visual.

---

# 4. Hierarquia Tipográfica

O sistema deve contemplar:

- Display Large
- Display Medium
- Display Small
- Headline Large
- Headline Medium
- Headline Small
- Title Large
- Title Medium
- Title Small
- Body Large
- Body Medium
- Body Small
- Label Large
- Label Medium
- Label Small

A nomenclatura segue o padrão do Material Design 3 para facilitar a implementação no Flutter.

---

# 5. Escala de Tamanhos

Recomenda-se uma escala tipográfica consistente:

| Categoria | Tamanho |
|-----------|---------:|
| Display Large | 57 px |
| Display Medium | 45 px |
| Display Small | 36 px |
| Headline Large | 32 px |
| Headline Medium | 28 px |
| Headline Small | 24 px |
| Title Large | 22 px |
| Title Medium | 16 px |
| Title Small | 14 px |
| Body Large | 16 px |
| Body Medium | 14 px |
| Body Small | 12 px |
| Label Large | 14 px |
| Label Medium | 12 px |
| Label Small | 11 px |

Os valores poderão ser ajustados conforme os testes de usabilidade.

---

# 6. Pesos da Fonte

Pesos recomendados:

- Light (300)
- Regular (400)
- Medium (500)
- SemiBold (600)
- Bold (700)

Evitar o uso excessivo de pesos muito leves ou muito pesados.

---

# 7. Altura de Linha

As alturas de linha devem favorecer a leitura.

Diretrizes:

- Títulos: 110% a 120%
- Corpo de texto: 140% a 160%
- Labels: 120% a 140%

---

# 8. Espaçamento entre Letras

Utilizar valores próximos aos padrões do Material Design.

Evitar alterações manuais sem necessidade.

---

# 9. Alinhamento

Preferências:

- Esquerda para textos longos
- Centro apenas em elementos de destaque
- Evitar texto justificado

---

# 10. Uso da Tipografia

Aplicações recomendadas:

- Display: campanhas e telas de destaque
- Headline: títulos de páginas
- Title: títulos de seções e cards
- Body: textos descritivos
- Label: botões, chips, badges e campos

---

# 11. Responsividade

A tipografia deve:

- Adaptar-se a diferentes tamanhos de tela
- Respeitar a configuração de tamanho de fonte do sistema operacional
- Manter proporções consistentes

---

# 12. Acessibilidade

Diretrizes:

- Contraste conforme WCAG
- Não utilizar tamanho inferior a 12 px para textos importantes
- Suporte a Dynamic Type (quando aplicável)
- Evitar blocos longos de texto em caixa alta

---

# 13. Implementação

## Flutter

- Centralizar estilos no ThemeData.
- Utilizar TextTheme.
- Evitar estilos inline.

## Figma

- Criar Text Styles para todas as categorias.
- Utilizar nomenclatura padronizada.

---

# 14. Governança

Toda alteração tipográfica deverá:

- Ser documentada
- Atualizar o Figma
- Atualizar o Flutter
- Passar por revisão de acessibilidade

---

# 15. Critérios de Aceite

- Fonte principal definida
- Hierarquia documentada
- Escalas definidas
- Pesos padronizados
- Acessibilidade considerada
- Compatibilidade com Material Design 3

---

# 16. Checklist

- Fonte principal definida
- Hierarquia criada
- Escala documentada
- Pesos registrados
- Regras de acessibilidade definidas
- Integração com Flutter prevista
- Text Styles organizados no Figma
