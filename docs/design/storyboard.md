# Storyboard — App Preview

**Contexto:** BETA-10E1. Transforma o roteiro de `docs/store/app_preview.md` (BETA-10E) em storyboard detalhado, cena a cena, pronto para produção. Especificações técnicas de vídeo (duração total, resolução, formato) já definidas lá — não repetidas aqui.

---

## Cena 1 — Abertura (0:00–0:04)

| Item | Especificação |
|---|---|
| Tela | Fundo Gradiente Roxo oficial em tela cheia |
| Animação | Símbolo BORAH surge com leve escala (90%→100%) e fade-in, ~0,8s — reaproveitar a assinatura de marca já produzida (`animations/borah_signature_*`, referenciada no pacote oficial), não animar do zero |
| Transição de entrada | Fade-in a partir de preto, 0,3s |
| Transição de saída | Corte direto (sem crossfade) para a Cena 2, mantendo energia |
| Narração | Nenhuma (silêncio ou trilha instrumental leve) |
| Legenda | Nenhuma nesta cena |

## Cena 2 — Problema (0:04–0:09)

| Item | Especificação |
|---|---|
| Tela | Ilustração ou tela de busca/descoberta de restaurantes (mostrar variedade de opções, sugerindo indecisão) |
| Animação | Leve movimento de câmera (zoom lento, ~5% ao longo dos 5s) sobre a lista de opções |
| Transição de entrada | Corte direto |
| Transição de saída | Corte para a Cena 3, sincronizado com o fim da frase narrada |
| Narração | *"Todo grupo já teve aquela discussão sem fim sobre onde ir."* — tom leve, conversacional, não institucional |
| Legenda | Mesmo texto da narração, Manrope Regular, branco com contorno sutil escuro para legibilidade sobre qualquer fundo |

## Cena 3 — Solução (0:09–0:14)

| Item | Especificação |
|---|---|
| Tela | Corte para a tela de Ranking de Restaurantes já populada (mesma composição da screenshot 1) |
| Animação | A tela "monta-se" — cards do ranking entrando um a um de baixo para cima, ~1,5s, depois assentam |
| Transição de entrada | Corte seco, criando contraste com o movimento lento da Cena 2 |
| Transição de saída | Corte direto para a sequência rápida da Cena 4 |
| Narração | *"O BORAH transforma isso em ranking."* |
| Legenda | Idem, sincronizada |

## Cena 4 — Funcionalidades (0:14–0:22, ~2s por sub-cena)

| Sub-cena | Tela | Animação |
|---|---|---|
| 4a | Criação de avaliação (nota + foto) | Dedo tocando as estrelas, nota preenchendo com leve bounce |
| 4b | Feed do grupo | Scroll vertical suave revelando 2-3 posts |
| 4c | Perfil com XP/nível/conquista | Barra de XP enchendo (usa o `AppGradients.green` já existente no componente real) + selo de conquista com leve "pop" de escala |
| 4d | Ranking de Usuários | Mesmo estilo de entrada de cards da Cena 3, mas aplicado a pessoas |

| Item | Especificação |
|---|---|
| Transição entre sub-cenas | Corte seco em ritmo acelerado (sem crossfade), reforçando a sensação de "app cheio de coisas para fazer" |
| Narração | Nenhuma nesta sequência — deixar a música/ritmo carregar o momento |
| Legenda | Rótulos curtos sobrepostos e sincronizados a cada sub-cena: "Avalie" / "Acompanhe" / "Suba de nível" / "Ranking" — Fredoka Bold, cantos inferiores |

## Cena 5 — Reforço social (0:22–0:27)

| Item | Especificação |
|---|---|
| Tela | Detalhe de uma avaliação com curtidas/comentários visíveis |
| Animação | Um coração/curtida "pulsando" ao ser tocado (reaproveitar o componente de pulso já existente no app, `AppPulseIcon`, para consistência com a experiência real) |
| Transição de entrada | Corte direto vindo da Cena 4d |
| Transição de saída | Corte para a Cena 6 |
| Narração | *"Siga seu grupo, curta, comente, suba no ranking."* |
| Legenda | Idem, sincronizada |

## Cena 6 — Encerramento (0:27–0:30)

| Item | Especificação |
|---|---|
| Tela | Fundo Gradiente Roxo, símbolo + logo (`borah_logo_white`) centralizados |
| Animação | Fade-in do símbolo (reaproveitando a mesma assinatura da Cena 1, criando simetria de abertura/fechamento) |
| Transição de entrada | Corte seco vindo da Cena 5 |
| Transição de saída | Fade-out final para preto, 0,3s |
| Narração | *"Todo grupo tem seus rolês. Agora eles têm um ranking."* |
| Legenda | Tagline completa, Fredoka Bold, branco, centralizada |

---

## Trilha sonora

Não especificada nesta rodada — recomenda-se uma faixa instrumental leve, ritmo ascendente (acompanhando a energia crescente do roteiro), sem letra (evita concorrer com a narração/legendas). Escolha da faixa é decisão de produção, não de design de marca.

## Pendências

- Nenhum vídeo produzido — este é o storyboard de produção.
- Depende das mesmas capturas de tela reais já necessárias para `screenshots_spec.md`.
- A narração pode ser feita em voz humana ou só como legenda (decisão de produção) — o roteiro funciona nos dois casos, já que todo texto falado também aparece como legenda.
