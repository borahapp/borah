# Especificação Visual Detalhada dos Screenshots

**Contexto:** BETA-10E1. Aprofunda o roteiro já aprovado em `docs/store/screenshots.md` (BETA-10E) com especificação de composição pronta para produção. Dimensões exatas já definidas em `docs/store/screenshots.md` §1/§2 (Google Play: 1080×1920 recomendado; Apple: 1320×2868 para 6.9" e 2064×2752 para iPad 13"), não repetidas aqui.

**Padrão de composição comum a todos os 6 screenshots:**
- Faixa superior (~25% da altura): mensagem/overlay de texto, fundo sólido ou gradiente da marca.
- Faixa inferior (~75% da altura): captura de tela real do app, sem alteração de conteúdo.
- Tipografia do overlay: Fredoka Bold (mensagem principal), Manrope Regular (subtítulo, se houver).
- Cor de fundo do overlay: Gradiente Roxo oficial (padrão) ou Preto Uva sólido (variação, ver abaixo) — nunca fundo branco puro no overlay, para manter identidade de marca visível mesmo em miniatura.

---

## 1. Ranking de Restaurantes (hero)

- **Composição**: overlay superior com fundo Gradiente Roxo; captura da tela de Ranking ocupando a faixa inferior, mostrando pelo menos o pódio (medalhas de 1º/2º/3º lugar, já implementadas via `RankingCard`).
- **Texto principal (overlay)**: "O ranking do seu grupo, sempre atualizado." — Fredoka Bold, branco, alinhado à esquerda.
- **Texto secundário**: tagline completa em Manrope Regular, branco com opacidade ~80%, abaixo do texto principal.
- **Callout**: nenhum — a tela por si só já mostra as medalhas, dispensando seta/destaque adicional.
- **Posicionamento**: overlay no topo, tela ocupando o restante — dispositivo mockup **sem moldura** (tela a sangria total), já que é a primeira impressão e deve parecer "o app de verdade", não uma peça publicitária.
- **Dispositivo**: iPhone 6.9" (fonte primária) + réplica em Android phone e iPad 13".
- **Cores**: gradiente roxo oficial no overlay; nenhuma cor fora da paleta.

## 2. Feed

- **Composição**: overlay + captura do feed mostrando pelo menos 2-3 posts de atividade (avaliações recentes do grupo).
- **Texto principal**: "Veja o que seu grupo está avaliando." — Fredoka Bold.
- **Texto secundário**: "Acompanhe cada rolê em tempo real." — Manrope Regular.
- **Callout**: um círculo/destaque sutil (cor Verde BORAH, `#B8FF3B`) ao redor de uma curtida ou comentário no feed, chamando atenção para a interação social — único elemento de callout permitido nesta tela (regra de "um protagonista por bloco").
- **Posicionamento**: mesmo padrão overlay-superior/tela-inferior.
- **Dispositivo**: iPhone 6.9".
- **Cores**: overlay em gradiente roxo; callout em verde BORAH (única exceção à regra "não competir com outros verdes", já que é o único elemento verde desta composição).

## 3. Detalhe de restaurante

- **Composição**: captura da tela de detalhe mostrando nota, fotos e comentários de um restaurante já avaliado.
- **Texto principal**: "Cada lugar, com a nota de quem importa: seu grupo." — Fredoka Bold.
- **Texto secundário**: "Nada de nota genérica de desconhecido." — Manrope Regular.
- **Callout**: nenhum — a composição real da tela (nota + fotos + comentários) já comunica a mensagem sem necessidade de destaque adicional.
- **Posicionamento**: overlay-superior/tela-inferior padrão.
- **Dispositivo**: iPhone 6.9".
- **Cores**: overlay em Preto Uva sólido (`#0B0714`) — **variação de cor de fundo** desta screenshot especificamente, para dar ritmo visual à sequência de 6 (nem todas devem usar o mesmo fundo, senão a sequência fica monótona no carrossel da loja).

## 4. Criação de avaliação

- **Composição**: captura do formulário de nova avaliação (seleção de nota, campo de comentário, seleção de foto).
- **Texto principal**: "Avalie em segundos." — Fredoka Bold.
- **Texto secundário**: "Nota, comentário e fotos — registre antes que esqueçam." — Manrope Regular.
- **Callout**: destaque sutil (verde BORAH) no seletor de estrelas/nota, reforçando a ação central da tela.
- **Posicionamento**: padrão.
- **Dispositivo**: iPhone 6.9".
- **Cores**: overlay em gradiente roxo.

## 5. Perfil / Gamificação

- **Composição**: captura do perfil mostrando nível, XP e ao menos uma conquista desbloqueada.
- **Texto principal**: "Suba de nível a cada avaliação." — Fredoka Bold.
- **Texto secundário**: "Quem mais participa, mais sobe." — Manrope Regular.
- **Callout**: destaque na barra de progresso de XP (já usa o Gradiente Verde oficial internamente, `AppGradients.green` — reforçar esse elemento, não adicionar um novo).
- **Posicionamento**: padrão.
- **Dispositivo**: iPhone 6.9".
- **Cores**: overlay em Preto Uva sólido (segunda variação, criando um padrão alternado roxo/preto/roxo/preto ao longo da sequência de 6).

## 6. Ranking de Usuários

- **Composição**: captura do ranking de usuários, mostrando o pódio de gamificação (mesmas medalhas do `RankingCard`, aplicadas aqui a pessoas em vez de restaurantes).
- **Texto principal**: "Quem é o especialista em bons rolês do seu grupo?" — Fredoka Bold.
- **Texto secundário**: "Curta, comente, suba no ranking." — Manrope Regular.
- **Callout**: nenhum — fecha a sequência com a mesma composição de pódio da primeira tela, criando simetria (screenshot 1 = ranking de lugares; screenshot 6 = ranking de pessoas).
- **Posicionamento**: padrão.
- **Dispositivo**: iPhone 6.9".
- **Cores**: overlay em gradiente roxo (fecha o ciclo cromático iniciado na primeira screenshot).

---

## Sequência cromática do carrossel (visão geral)

| # | Overlay |
|---|---|
| 1 | Gradiente Roxo |
| 2 | Gradiente Roxo |
| 3 | Preto Uva |
| 4 | Gradiente Roxo |
| 5 | Preto Uva |
| 6 | Gradiente Roxo |

Alternância deliberada entre as duas cores de fundo oficiais (nunca o Verde como fundo de overlay — reservado para callouts pontuais, conforme regra de "não competir").

## Pendências

- Nenhuma imagem produzida — depende de build de Produção instalável (Android já validado, BETA-10B; iOS depende de macOS, BETA-10C) para capturar as telas reais.
- Overlays de texto e callouts são trabalho de composição gráfica (Figma/Sketch ou equivalente), fora do escopo desta especificação.
