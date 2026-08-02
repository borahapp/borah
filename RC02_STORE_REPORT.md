# RC-02C — Store Report

**Data:** 2026-08-02. **Nada foi publicado** — só revisão, conforme pedido.

## Achado principal — a ficha de loja descreve um app que não existe mais

`docs/store/google_play_listing.md`, `app_store_listing.md`, `branding.md`, `faq.md` e `app_preview.md` foram escritos no commit `2877e47` (BETA-10E) — **antes** de toda a família de commits que introduziu Grupos/Rolês/Avaliação Coletiva/Ranking do Grupo (`63da4d4` em diante) e antes da decisão de tornar Grupos a aba inicial no lugar do Feed (`656e558`). Confirmado por `git log --oneline`: `2877e47` aparece depois (mais antigo) de todos esses commits no histórico.

O texto atual da Descrição Longa (Google) e da Description (Apple) fala em:
- "Feed social", "siga seus amigos, curta e comente as avaliações deles"
- "Ranking de Restaurantes"/"Ranking de Usuários" como se fossem individuais, não por grupo fechado

E **nunca menciona**:
- Grupos fechados por convite (a mecânica central do produto hoje)
- Criar um rolê, confirmar presença
- Avaliação coletiva (nota conjunta do grupo, não avaliação individual solta)
- Ranking do Grupo / Estatísticas / Memórias

Isso não é um erro cosmético — é a ficha de loja descrevendo a versão anterior do produto (feed individual + follower graph) em vez da atual (grupos fechados de amigos que organizam rolês juntos). Publicar como está enganaria quem instalar o app sobre o que ele realmente faz.

**Isso também contamina itens dependentes**: `docs/launch/google_play_checklist.md` diz que o conteúdo de Data Safety/Content Rating "já está pronto", mas a base dele é exatamente `google_play_listing.md` — a mesma fonte desatualizada.

**Atualização — reescrito nesta sessão.** Reescrevi `branding.md`, `google_play_listing.md`, `app_store_listing.md`, `faq.md`, `screenshots.md` e `app_preview.md` para colocar Grupo fechado → Rolê → Confirmar presença → Avaliação Coletiva → Ranking do Grupo/Estatísticas/Memórias como o núcleo da narrativa, mantendo Feed/avaliação individual/gamificação como camada secundária (existem no app, só não são mais o produto principal). Todos os limites de caracteres foram recontados com `wc -m` (não estimados). Mudanças concretas:

- Short/Full Description (Google) e Subtitle/Promotional Text/Description (Apple): reescritas, lideram com grupo/rolê/avaliação coletiva.
- `branding.md`: proposta de valor, elevator pitch e lista de funcionalidades reconferidas contra `app_router.dart`.
- `faq.md`: pergunta 1 reescrita + 3 perguntas novas (como funciona um grupo, o que é Avaliação Coletiva, o que são Memórias/Estatísticas).
- `screenshots.md`/`app_preview.md`: telas 2 e 6 (que mostravam Feed/curtidas) substituídas por criar rolê/confirmar presença e avaliação coletiva/memórias.

Categoria, classificação indicativa, keywords e URLs não mudaram — não dependiam do achado.

## Revisão dos demais itens pedidos

| Item | Status |
|---|---|
| Google Play — ficha | ✅ Reescrita nesta sessão |
| TestFlight/App Store — ficha | ✅ Reescrita nesta sessão |
| Screenshots | 🟡 Roteiro corrigido (`docs/store/screenshots.md`) — imagens ainda não produzidas (depende de build instalada em dispositivo real) |
| Feature Graphic | 🔴 Não produzido |
| Descrição curta/longa | ✅ Reescritas nesta sessão |
| Categoria | 🟡 "Social" sugerido — continua razoável independente da reescrita, não precisa mudar |
| Classificação indicativa | 🟡 Estimativa preliminar registrada, só confirmável no questionário real do Console/App Store Connect |
| Data Safety (Google) | 🟡 Inventário técnico ainda válido (dados coletados não mudaram) — texto de referência agora aponta para a versão corrigida de `google_play_listing.md`, mas o formulário do Console continua não preenchido |
| App Privacy (Apple) | 🟡 Mesmo status — `docs/apple/PrivacyInfo.draft.xcprivacy` é sobre categorias técnicas de dados (não sobre narrativa de produto), provavelmente não afetado |
| Privacy Policy / Terms | ✅ Conteúdo pronto (`docs/legal/`) — não fala de features específicas do produto, não afetado por este achado |

## Resposta objetiva

A cópia de loja (`docs/store/*.md`) agora corresponde ao produto real: Grupo fechado → Rolê → Confirmar presença → Avaliação Coletiva → Ranking do Grupo/Estatísticas/Memórias como núcleo, Feed/gamificação/avaliação individual como camada secundária. O que falta antes de submeter a qualquer loja é só produção (não mais texto): assets visuais reais (Feature Graphic, screenshots, ícone já pronto), formulário de Data Safety/Content Rating preenchido no Console/App Store Connect, e uma conta de desenvolvedor Google/Apple provisionada — nenhum desses depende de mim neste ambiente.
