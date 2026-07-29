# IV-06 a IV-09 — Conclusão da Identidade Visual Oficial

**Data:** 2026-07-26
**Branch:** `feature/iv-06-09-brand-identity`
**Status:** Implementado — fases IV-06 a IV-09 concluídas
**Escopo:** integrar os elementos gráficos oficiais restantes (medalhas, expressões, decorativos), padronizar a identidade em gamificação/rankings, auditar Dark Mode e preparar assets de loja. Fonte única de verdade: `identidade visual-borah/BORAH_Pacote_Implementacao_Claude`. Nenhuma regra de negócio alterada.

---

## 1. Objetivo

Concluir a Etapa 1 ("Finalizar a identidade visual") do roadmap operacional pré-Beta, executando IV-06 a IV-09 conforme aprovado, sobre a base já validada em IV-01 a IV-05 (`IV-01_A_05_BRAND_IDENTITY_INTEGRATION.md`).

---

## 2. IV-06 — Elementos gráficos oficiais restantes

### 2.1 Assets copiados

De `identidade visual-borah/.../assets/borah/` para `app/assets/borah/`: `ui/ranking/` (12 arquivos), `ui/expressions/` (4 arquivos), `ui/decorative/` (7 arquivos) — cópia integral, por instrução ("utilizar exclusivamente o pacote oficial"), mesmo para os arquivos sem ponto de consumo nesta rodada (ver §2.3).

### 2.2 Bug crítico encontrado e corrigido: SVG aninhado quebra `flutter_svg`

Ao aplicar `symbol_smiling.svg`/`symbol_surprised.svg` em `EmptyState`/`ErrorState`, `flutter analyze`/`dart format`/`flutter test` passaram normalmente (503/503) — mas esses testes só verificam a árvore de widgets, não o conteúdo visual renderizado. Uma verificação visual real (`flutter build web --release` + preview em navegador, já que não há emulador Android neste ambiente) revelou que a ilustração aparecia **completamente em branco**, apesar do asset carregar com sucesso (200 OK, sem erros de console).

**Causa raiz confirmada**: os 4 arquivos de `ui/expressions/` (e também `ui/decorative/pattern_symbols_purple.svg`, não usado nesta rodada) contêm um elemento `<svg>` aninhado dentro do `<svg>` raiz — um recorte com `x`/`y`/`width`/`height`/`viewBox` próprios, técnica comum em exportações de ferramentas de design para aplicar um crop/transform sem "achatar" as coordenadas. O `vector_graphics_compiler` (usado pelo `flutter_svg` 2.x para compilar SVGs em tempo de build) não suporta esse aninhamento e descarta o conteúdo interno silenciosamente — sem lançar erro em nenhuma camada (rede, console ou teste de widget).

**Correção aplicada** (só nas 4 cópias de execução em `app/assets/borah/ui/expressions/`, conforme a própria regra do material oficial — *"Não modifique os arquivos originais. Se for indispensável gerar uma derivação, preserve o original e documente a nova versão"*): o `<svg>` aninhado foi substituído por um `<g transform="matrix(1.85,0,0,1.85,-450,105)">` matematicamente equivalente — a mesma transformação de posição/escala que o aninhamento expressava (`x=142,y=142,width=740,height=740,viewBox="320 20 400 400"` → escala 740/400=1.85, translação derivada), preservando exatamente o recorte e a posição originais, sem alterar nenhum traço, cor ou proporção do desenho. Os arquivos-fonte em `identidade visual-borah/` permanecem intocados (confirmado: ainda têm a estrutura aninhada original).

**Verificação pós-correção**: novo `flutter build web --release` + recarregamento do preview — a ilustração de `ErrorState` (rota inexistente `/#/this-route-does-not-exist`, acionando o `errorBuilder` do router) agora renderiza corretamente, em Light e Dark Mode (ver §4). `symbol_smiling.svg` também verificado isoladamente (abertura direta do arquivo no navegador).

**`pattern_symbols_purple.svg`** tem o mesmo problema (confirmado via inspeção), mas não é usado nesta rodada (ver §2.3) — meramente sinalizado para quem for aplicá-lo futuramente.

### 2.3 Aplicados

| Asset | Onde | Como |
|---|---|---|
| `symbol_smiling.svg` | `EmptyState` (14 telas) | Ilustração de 64×64, `semanticsLabel` |
| `symbol_surprised.svg` | `ErrorState` (19 telas) | Ilustração de 64×64, `semanticsLabel`; parâmetro `icon` (Material, genérico) removido |
| `medal_1.svg`/`medal_2.svg`/`medal_3.svg` | `RankingCard` (posições 1º/2º/3º) | Substitui o `CircleAvatar` numérico apenas no pódio; posições 4+ inalteradas |

Nenhuma das 14 telas com `EmptyState` nem das 19 com `ErrorState` customizava o ícone anterior (confirmado por busca antes da mudança) — a troca se aplica de forma consistente em todas de uma vez, sem exceção a documentar.

### 2.4 Deliberadamente não aplicados nesta rodada (com justificativa)

| Asset | Motivo de não aplicar agora |
|---|---|
| `crown_best.svg` | Não existe, hoje, uma seção de "melhor rolê" distinta nas telas — aplicar forçaria uma reinterpretação da tela, não uma reconciliação. |
| `star.svg` | O app já tem `ScoreBubble`, componente numérico de nota bem integrado; substituí-lo seria um redesign, fora do pedido de "padronizar", com risco de descaracterizar a identidade já estabelecida. |
| `ranking_up.svg` | Não existe nenhum dado de variação de posição no domínio (`delta`/`previousPosition`/`trend` — confirmado por busca) para justificar um indicador "subiu no ranking". |
| `confetti.svg` | Não existe gatilho de celebração pontual (ex.: evento de "subiu de nível") já modelado — aplicar sem um evento real seria decorativo sem função. |
| `badge_group_approved.svg`, `badge_group_top.svg`, `badge_new_ranking.svg`, `badge_best.svg` | Selos definidos para conceitos específicos ("aprovado pelo grupo", "top do grupo") que dependem de uma entidade "Grupo" **inexistente no modelo de dados do BORAH** (achado já registrado desde a RC-04E) — aplicá-los seria inventar uma feature, não integrar um asset. |
| `location.svg` | É uma ilustração de pino colorida e detalhada (mordida BORAH embutida), pensada para destaque, não um glifo simples — o único ponto de uso atual de ícone de local é um glifo inline de 14×14px ao lado de texto (`favorites_page.dart`, `restaurants_search_page.dart`, `restaurant_detail_page.dart`); aplicar essa ilustração nesse tamanho a tornaria ilegível e violaria a própria regra do material ("baixa competição visual"). O `assets/icons/borah_location.png` atual (simples, proporcionado para esse contexto) foi mantido. Candidato natural para uma futura tela com mapa ou destaque maior, não para esta rodada. |
| `bite_shape.svg`, `smile_shape.svg`, `curved_arrow.svg`, `burst_shape.svg`, `pattern_name_purple.svg`, `pattern_bites_transparent.svg`, `pattern_symbols_purple.svg` | Elementos puramente decorativos, sem um ponto de aplicação já existente nas telas atuais; o próprio material recomenda "baixa competição visual" e "um elemento visual protagonista por bloco" — inseri-los sem um propósito de tela específico seria decoração forçada, na contramão dessas regras. Ficam copiados no repositório, prontos para uso quando uma tela realmente pedir por eles. |

Todos os arquivos acima permanecem em `app/assets/borah/ui/` (cópia integral do pacote), mas **não declarados em `pubspec.yaml`** — convenção já usada desde a UI-03B: só entra no bundle o que tem consumidor real.

---

## 3. IV-07 — Padronização em gamificação e rankings

- **Rankings** (`rankings_page.dart`, restaurantes) e **Ranking de usuários** (`ranking_users_page.dart`) compartilham o mesmo `RankingCard` — a mudança de medalhas em §2.3 já se aplica automaticamente às duas telas.
- **`GamificationProfilePage`** (perfil de gamificação + conquistas + badges) foi revisada: usa `Icons.emoji_events`/`Icons.emoji_events_outlined` (Material genérico) por conquista, e o componente `AppBadge` (pílula do design system) para o rótulo "Conquistado"/"Bloqueado". **Decisão: manter como está.** As conquistas (`allBadges`) são uma lista dinâmica vinda do backend (`GamificationBadge.id`/`name`/`description`), sem relação 1:1 com os 4 selos oficiais nomeados (`badge_best`, `badge_group_*`, `badge_new_ranking`) — aplicar um selo oficial fixo a uma conquista arbitrária representaria errado o que ela significa, e os selos de grupo dependem da mesma entidade "Grupo" inexistente já apontada em §2.4. A barra de XP já usa o gradiente institucional (`AppGradients.of(context).green`) desde a base do design system — sem inconsistência a corrigir aqui.
- **Estados vazios/placeholders** de rankings e gamificação já herdam `EmptyState`/`ErrorState` (§2.3) — mesma expressão oficial em todo o app, sem exceção por tela.

Conclusão: consistência visual garantida onde há correspondência real entre asset e dado; nenhuma tela de gamificação/rankings ficou com um estado genérico do Flutter sem justificativa registrada.

---

## 4. IV-08 — Auditoria de Dark Mode

### Metodologia

Sem emulador Android/Docker disponível neste ambiente (limitação já registrada desde o início do projeto), a verificação visual real foi feita via `flutter build web --release` servido localmente (`.claude/launch.json`, config `borah-web-development`) e inspecionado com as ferramentas de preview de navegador (screenshot, `resize_window` com `colorScheme: dark`, console, rede).

### Superfícies verificadas (Light + Dark)

| Tela/componente | Resultado |
|---|---|
| `LoginPage` (logo oficial + gradiente roxo institucional) | ✅ Contraste e legibilidade corretos nos dois temas |
| `ErrorState` (ilustração `symbol_surprised`, texto, botão "Tentar novamente") — via rota 404 do router | ✅ Após a correção do §2.2: ilustração, texto branco e borda do botão outline com contraste adequado sobre `#0B0714` (Preto Uva) no Dark, e sobre fundo claro no Light |

### Limitação honesta

A maior parte das telas do app exige sessão autenticada no Supabase, indisponível neste build web offline (sem backend real conectado) — não foi possível verificar visualmente, nesta rodada, o Dark Mode de telas como Rankings, Gamificação, Feed, Favoritos, etc. O Dark Theme (`AppTheme.dark`) já herda os mesmos tokens de `BrandColors`/`BrandGradients`/`AppGradients` usados no Light (validado desde a FASE 7A/UI-01), e nenhuma tela usa cor "hardcoded" fora do sistema de tema (verificado por busca) — o que reduz o risco, mas não substitui uma verificação visual real. Fica registrado como pendência para quando um dispositivo/emulador real ou credenciais de Supabase estiverem disponíveis para teste.

Nenhuma inconsistência visual foi corrigida além do bug do §2.2 — nenhuma regra de negócio foi tocada, conforme escopo.

---

## 5. IV-09 — Preparação de assets para publicação

| Asset | Situação |
|---|---|
| Ícone do app (Android/iOS, todas as densidades) | ✅ Já resolvido na IV-02 |
| Splash nativo (Android/iOS) | ✅ Já resolvido na IV-03 |
| **Ícone Google Play 512×512** | ✅ **Resolvido nesta rodada** — `BORAH_google_play_512.png` existia pronto no pacote oficial (`platform/android/google_play/`) e nunca havia sido copiado para o projeto; copiado para `app/assets/borah/platform/android/google_play/` (não declarado no `pubspec.yaml` — é um asset de upload manual na Play Console, não consumido em runtime pelo Flutter). Resolve o item 3 pendente em `RC-04D_RELEASE_READINESS.md` §13 na parte referente ao ícone. |
| Ícones adaptativos Android pré-gerados (`platform/android/adaptive/`), conjunto legado (`platform/android/legacy/`), `AppIcon.appiconset` iOS pré-gerado | Existem no pacote oficial, mas **deliberadamente não usados** — a rota escolhida desde a IV-02 é gerar via `flutter_launcher_icons`/`flutter_native_splash` a partir da matriz 1024px, e o próprio material adverte para "não misturar as duas rotas". Permanecem apenas no pacote-fonte, não copiados ao projeto. |
| Screenshots de loja (Google Play / App Store) | 🔴 **Ausentes no pacote oficial** — nenhum arquivo de screenshot ou feature graphic existe em `identidade visual-borah/`. Documentado como pendência; não foi criada nenhuma arte nova, conforme instrução. Depende de capturas reais do app rodando (dispositivo/emulador), item já bloqueado pela mesma limitação de ambiente registrada em rodadas anteriores. |
| Feature graphic (Google Play, 1024×500) | 🔴 Ausente no pacote oficial — mesma situação acima. |
| Descrição curta/completa da loja | 🔴 Já registrado como pendência em `RC-04D_RELEASE_READINESS.md` §13 — conteúdo de marketing, fora do escopo de código. Sem mudança nesta rodada. |
| Nomenclatura/organização dos assets no repositório | ✅ Auditada — `app/assets/borah/` espelha a estrutura do pacote oficial (`logos/`, `symbol/`, `app_icon/`, `animations/`, `ui/`, e agora `platform/android/google_play/`); `app/assets/ASSETS.md` documenta a árvore e as convenções. |
| Resoluções | ✅ Auditadas — ícone 1024px (matriz), símbolo 4096px (splash), medalhas/expressões/decorativos em 1024×1024 (viewport SVG), Google Play 512px — todas as resoluções batem com o que cada ferramenta/loja espera. |

---

## 6. Arquivos criados

- `app/assets/borah/ui/ranking/*` (12 arquivos), `app/assets/borah/ui/expressions/*` (4 arquivos, 4 deles corrigidos — ver §2.2), `app/assets/borah/ui/decorative/*` (7 arquivos)
- `app/assets/borah/platform/android/google_play/BORAH_google_play_512.png`
- `docs/FASE 9 - Execution/IV-06_A_09_BRAND_IDENTITY_COMPLETION.md` (este documento)

## 7. Arquivos modificados

- `app/pubspec.yaml` — `assets:` estendido com `symbol_smiling.svg`, `symbol_surprised.svg`, `medal_1/2/3.svg`.
- `app/lib/design_system/components/feedback/empty_state.dart` — ilustração oficial em vez de espaço reservado sem ícone.
- `app/lib/design_system/components/feedback/error_state.dart` — ilustração oficial; parâmetro `icon` removido.
- `app/lib/design_system/components/cards/ranking_card.dart` — medalhas oficiais no pódio (1º/2º/3º).

## 8. Resultado dos testes

- `flutter analyze`: **sem nenhum problema**.
- `dart format --set-exit-if-changed .`: **352 arquivos, 0 alterados**.
- `flutter test`: **503/503** — nenhuma regressão.
- Verificação visual real (não coberta por `flutter test`): `flutter build web --release` + preview em navegador, Light e Dark Mode — ver §4.

## 9. Pendências para as próximas rodadas

- Verificação visual de Dark Mode nas telas autenticadas (Rankings, Gamificação, Feed, Favoritos etc.) quando houver dispositivo/emulador real ou uma sessão Supabase de teste disponível.
- Screenshots de loja e feature graphic — dependem de asset oficial ainda não fornecido (não é possível criar arte nova) e de captura em ambiente com backend real.
- Selos de grupo (`badge_group_approved`, `badge_group_top`) e conceito de "melhor rolê" (`crown_best`, `badge_best`) seguem sem aplicação — dependem de decisões de produto ainda não tomadas (existência de uma entidade "Grupo", de uma seção de destaque), não de um problema técnico.
- Demais pendências de publicação (keystore Android real, `DEVELOPMENT_TEAM` iOS, descrição de loja, suítes pgTAP) permanecem exatamente como registradas em `RC-04D_RELEASE_READINESS.md` §13 — inalteradas por esta rodada.
