# Especificação da Feature Graphic — Google Play

**Contexto:** BETA-10E1. Especificação de composição para a peça de 1024×500px exigida pelo Google Play (`docs/store/screenshots.md` já registra a dimensão exata; este documento especifica o conteúdo visual). **Nenhuma imagem foi produzida** — só a especificação para produção.

---

## 1. Layout

Composição horizontal (1024×500, proporção ~2:1), dividida em duas metades:

```
┌─────────────────────────────┬──────────────────────────┐
│                             │                            │
│   Símbolo BORAH + tagline   │   Recorte de tela real     │
│   (metade esquerda)         │   (Ranking de Restaurantes)│
│                             │   levemente inclinada,     │
│                             │   mockup de dispositivo    │
└─────────────────────────────┴──────────────────────────┘
```

- **Metade esquerda**: fundo com o Gradiente Roxo oficial (`#6C47FF → #5B2EFF → #3D19C7`), símbolo BORAH em destaque + tagline em Fredoka Bold, branco.
- **Metade direita**: recorte da tela de Ranking de Restaurantes (primeira screenshot já roteirizada em `docs/store/screenshots.md`), dentro de um mockup de dispositivo simples, levemente inclinado para dar dinamismo — nunca a tela "flutuando" sem moldura, para manter legibilidade em miniatura (a Feature Graphic aparece pequena em muitos contextos da Play Store).

## 2. Hierarquia visual

1. **Símbolo BORAH** — maior elemento, âncora visual esquerda.
2. **Tagline** ("Todo grupo tem seus rolês. Agora eles têm um ranking.") — segundo elemento em destaque, mas **considerar uma versão reduzida** para a Feature Graphic especificamente, já que o espaço é limitado: `"Seus rolês. Seu ranking."` (variação já usada como exemplo de tom de voz no Manual da Marca) — mais compacta, mesma mensagem.
3. **Recorte de tela** — reforça "é um produto real", não apenas uma peça de marketing abstrata.
4. Nenhum outro elemento — **regra de "um elemento visual protagonista por bloco"** aplicada literalmente aqui: símbolo domina a esquerda, tela domina a direita, nada mais compete por atenção.

## 3. Mensagem

A mesma proposta de valor central já definida em `docs/store/branding.md` — não criar uma mensagem nova só para este asset. Reduzir, não reinterpretar.

## 4. Elementos

- Símbolo BORAH (`assets/borah/symbol/`)
- Tagline reduzida, Fredoka Bold, branco, sobre o gradiente roxo
- Mockup de dispositivo com a tela de Ranking de Restaurantes
- Nenhum elemento decorativo adicional (evitar poluição visual num espaço já apertado de 500px de altura)

## 5. CTA

A Feature Graphic do Google Play **não tem botão/CTA clicável** — é puramente visual, exibida no topo da ficha da loja. Não desenhar um botão falso "Baixar agora" (não é um padrão usado nesse contexto e pode confundir).

## 6. Área segura

Manter todo texto e elementos-chave dentro de uma margem de **~40px** (`AppSpacing.xxxl`) das bordas — a Play Store pode recortar levemente a peça em alguns contextos de exibição (ex.: carrossel em telas menores).

## 7. Variações

- **Variação única necessária**: a Feature Graphic do Google Play não tem variantes claras/escuras nem por idioma nesta fase (app só em português). Uma única versão é suficiente.
- Se o site institucional (`docs/release/hosting.md`) precisar de um banner de hero similar, reaproveitar a mesma composição em proporção diferente, não recriar do zero.

## Pendências

- Nenhuma imagem produzida — aguardando BETA-10E1 (produção real) ou rodada de design dedicada.
- Depende de uma captura real da tela de Ranking (build de Produção instalável).
