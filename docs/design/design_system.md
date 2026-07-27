# Design System para Produção de Assets — BORAH

**Contexto:** BETA-10E1. Consolida a identidade visual **já oficial** do BORAH (Manual da Marca v1.0/jul-2026, implementada em código desde a FASE 7A/UI-01 e reconciliada na IV-01 a IV-09) para uso por qualquer designer ou ferramenta de geração de imagem na produção dos assets finais de loja. **Nada aqui é novo — tudo é extraído diretamente dos tokens de marca já em produção** (`app/lib/design_system/brand/`), para garantir que os assets de loja tenham exatamente a mesma identidade do app real.

---

## 1. Paleta principal

| Token | Hex | Papel |
|---|---|---|
| Roxo BORAH | `#5B2EFF` | Cor dominante — estrutura, fundo principal, áreas de marca |
| Verde BORAH | `#B8FF3B` | Cor de ação — destaca notas, conquistas e o elemento mais importante da tela. **Nunca deve competir com vários outros elementos verdes na mesma composição** (regra oficial do Manual da Marca) |
| Preto Uva | `#0B0714` | Fundo escuro oficial / cor de tinta |

## 2. Paleta secundária (gradientes oficiais)

| Gradiente | Valores exatos | Uso |
|---|---|---|
| Gradiente Roxo (oficial, reconciliado na IV-05) | `#6C47FF` → `#5B2EFF` → `#3D19C7` (3 tons, esquerda→direita) | Ícone do app, fundos de destaque, Feature Graphic |
| Gradiente Verde (por amostragem, sem valor exato no pacote oficial) | `#C2FF02` → `#97D702` | Elementos de conquista/energia, uso pontual |

## 3. Cores de apoio

Não há uma escala neutra "de marca" — cinzas/tons de superfície são responsabilidade da camada de tokens Material (`app_colors.dart`), não da marca em si. **Para assets de loja, usar branco (`#FFFFFF`) como cor de apoio neutra principal** (mesma escolha já validada para o logo sobre o gradiente roxo na tela de Login, IV-04 — decisão de contraste já aprovada).

## 4. Tipografia

| Família | Papel | Pesos oficiais |
|---|---|---|
| **Fredoka** | Títulos e chamadas | Semibold 600, Bold 700 |
| **Manrope** | Textos, interface, dados | Regular 400, Semibold 600, Bold 700 |

Regra oficial: **a logo é um desenho próprio em curvas — nunca recriá-la digitando "BORAH" em Fredoka.** Qualquer texto de marca em asset de loja (ex.: chamadas na Feature Graphic) deve usar Fredoka como fonte de texto normal, nunca tentando imitar o logotipo.

## 5. Espaçamento

Grid de 8px (`AppSpacing`, já em produção): `4 · 8 · 12 · 16 · 24 · 32 · 40 · 48 · 64`. Usar esses múltiplos para qualquer margem/respiro em composições de asset, mantendo consistência com o app real.

## 6. Estilo de ícones

Cantos generosamente arredondados, nunca retos, mas sem exagero infantil (raio: `4 · 8 · 12 · 16 · 24px`, ou totalmente arredondado para chips/badges — escala `AppRadius` já em produção). Ícones dentro do app usam o padrão Material, sempre coloridos com os tokens acima — nenhum ícone de terceiros com estilo visual divergente.

## 7. Estilo de ilustrações

As únicas ilustrações oficiais são as **expressões do símbolo BORAH** (`symbol_smiling`, `symbol_winking`, `symbol_surprised`, `symbol_celebrating`) e os **elementos decorativos** (`bite_shape`, `smile_shape`, `curved_arrow`, `burst_shape`, padrões repetidos) do pacote oficial de identidade visual. Regras já estabelecidas (IV-06):
- Usar **uma expressão por tela/estado** — nunca combinar várias na mesma composição.
- Elementos decorativos com **baixa competição visual** — nunca mais de um elemento visual protagonista por bloco.
- **Não criar novas ilustrações** — usar exclusivamente o que já existe em `identidade visual-borah/.../assets/borah/ui/`.

## 8. Linguagem visual / personalidade da marca

Social, espontânea, competitiva, memorável — divertida sem ser infantil, digital sem ser fria, ousada sem ser confusa (definição oficial do Manual da Marca, já usada para orientar todo o app). Tom de voz: fala como alguém do grupo, nunca como uma plataforma corporativa — convida em vez de ordenar, humor leve sem forçar piada.

## 9. Regras invioláveis (Manual da Marca — aplicam-se a qualquer asset novo)

1. Textos, números, notas e posições de ranking são sempre dados dinâmicos — nunca "queimados" numa imagem estática de asset (screenshots são a exceção óbvia, já que capturam a tela real).
2. Área livre ao redor da logo/símbolo equivalente a **metade da altura do próprio símbolo**.
3. Nunca rotacionar a logo, nunca aplicar sombra externa/contorno/glow fora do sistema de animação oficial.
4. Preservar contraste: versão `white`/`black` (aplicação de uma cor) sobre fundos saturados; `dark`/`light` (coloridas) só quando o fundo permitir contraste real.
5. Nunca esticar — sempre `BoxFit.contain`/proporção original preservada.

---

## Fontes de verdade (não reescrever, só referenciar)

- `app/lib/design_system/brand/brand_colors.dart`
- `app/lib/design_system/brand/brand_gradients.dart`
- `app/lib/design_system/brand/brand_typography.dart`
- `app/lib/design_system/tokens/app_spacing.dart`, `app_radius.dart`
- `identidade visual-borah/BORAH_Pacote_Implementacao_Claude/BORAH_Pacote_Implementacao_Claude/CLAUDE.md` (Manual de regras de implementação)
- `docs/FASE 9 - Execution/IV-06_A_09_BRAND_IDENTITY_COMPLETION.md` (decisões de aplicação já tomadas)
