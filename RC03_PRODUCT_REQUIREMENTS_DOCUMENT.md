# RC-03 — PRD Oficial do BORAH 2.0

**Status:** Draft para aprovação do usuário — documento de consolidação, nenhum código/schema/arquivo de produto foi alterado.
**Data:** 2026-08-04
**Natureza deste documento:** este PRD não é uma nova auditoria — é a **consolidação** dos 5 documentos já aprovados como oficiais da RC-03 ([`RC03_PRODUCT_AUDIT.md`](RC03_PRODUCT_AUDIT.md), [`RC03_UX_AUDIT.md`](RC03_UX_AUDIT.md), [`RC03_UI_AUDIT.md`](RC03_UI_AUDIT.md), [`RC03_DESIGN_GAP.md`](RC03_DESIGN_GAP.md), [`RC03_FEATURE_GAP.md`](RC03_FEATURE_GAP.md)) em uma especificação única. Nenhum achado novo é introduzido aqui. Onde uma pergunta da estrutura pedida não tem resposta documentada em nenhuma das 5 auditorias, isso é declarado explicitamente como "não documentado", em vez de inferido.
**A partir da aprovação deste documento:** este PRD passa a ser a única fonte oficial de requisitos do BORAH 2.0. O `RC03_IMPLEMENTATION_PLAN.md` deverá derivar exclusivamente dele.

---

## 1. Visão do Produto

**Missão** (fonte: `UI-02_BRAND_GUIDELINES.md`, lido e verificado durante a FASE 3/4): *"Transformar encontros entre amigos em experiências memoráveis por meio da descoberta de restaurantes, gamificação e interação social."*

**Visão** (mesma fonte): *"Ser o principal aplicativo para organizar experiências gastronômicas em grupo na América Latina."*

**Propósito**: não existe, nas 5 auditorias, uma declaração de "propósito" distinta de Missão/Visão — o par acima é o mais próximo documentado e é tratado como a formulação oficial.

**Problema resolvido**: consolidando o achado central do `RC03_PRODUCT_AUDIT.md §1` (o pivô de produto confirmado) com a proposta de valor já publicada na loja (`RC03_PRODUCT_AUDIT.md`, citando `docs/store/app_store_listing.md`/`google_play_listing.md`): grupos de amigos hoje decidem onde comer de forma dispersa (mensagens de WhatsApp, memória individual, nenhum histórico compartilhado) — o BORAH resolve isso dando ao grupo um espaço fechado onde a escolha, a confirmação de presença, a avaliação coletiva e o histórico de experiências gastronômicas viram um registro vivo e competitivo do grupo, não uma lembrança dispersa entre indivíduos.

**Público-alvo**: consolidando `UX-00_UX_PRINCIPLES.md §3` (3 personas documentadas — Organizador, que cria grupos/agenda eventos/busca praticidade; Participante, que recebe convites/confirma presença/avalia/acompanha rankings; Explorador, que descobre restaurantes/coleciona badges/busca desafios) com a política de idade já registrada para o Beta Fechado (`RC02_STORE_REPORT.md`, via `google_play_listing.md`: 18+ durante o Beta Fechado, decisão registrada, sem verificação de idade implementada). Categoria de loja sugerida: Social (alternativa: Lifestyle).

**Proposta de valor** (tagline oficial, já publicada e confirmada como a mensagem pós-pivô nas fichas de loja atuais): **"Todo grupo tem seus rolês. Agora eles têm um ranking."**

---

## 2. Pilares do Produto

Cada pilar consolida: (a) o que já existe e funciona hoje, confirmado no código/banco (`RC03_PRODUCT_AUDIT.md`), e (b) o que falta para o pilar atingir sua forma final no BORAH 2.0 (`RC03_FEATURE_GAP.md §11`).

### Descoberta
Hoje: busca manual de restaurantes por nome/cidade/categoria, cadastro 100% manual, favoritos individuais. No BORAH 2.0: cadastro inteligente via Google Places (F12) elimina a digitação manual; descoberta guiada pelo histórico do próprio grupo — favoritos do grupo e restaurantes ainda não visitados sugeridos no momento de criar um rolê (F13).

### Grupos
Hoje: criação/edição, papéis (Owner/Admin/Membro), convite por código de 8 caracteres, RLS reforçando hierarquia. No BORAH 2.0: mesmo núcleo, mais um canal de entrada sem fricção (deep link de convite, F35, item Core) e identidade visual própria por grupo (`GroupCard`, F46, item Core).

### Rolês
Hoje: criação com restaurante/data/hora, confirmação de presença (confirmado/recusado, sem "talvez"), cancelamento/reagendamento por admin/dono; liberação de avaliação por confirmação prévia + passagem de tempo (não por check-in físico geolocalizado, decisão já registrada como definitiva, `RC03_FEATURE_GAP.md §1`). No BORAH 2.0: mesmo mecanismo (correto e não deve ser reconstruído), com identidade visual própria (`EventCard`, F46) e, opcionalmente, sugestão de rodízio de quem escolhe o próximo (F36, sempre como sugestão, nunca obrigação).

### Avaliações
Hoje: dois sistemas paralelos — avaliação individual de restaurante (`reviews`, nota única 1-5 + comentário + até 5 fotos, gera XP) e avaliação coletiva de rolê (`event_reviews`, 5 critérios: comida/atendimento/ambiente/custo-benefício/geral, não gera XP hoje). No BORAH 2.0: avaliação coletiva passa a gerar XP simetricamente (parte de F29, Core), e a avaliação individual pode adotar os mesmos 5 critérios da coletiva (F16), unificando a experiência de "avaliar" no app inteiro.

### Memórias
Hoje: parcial — cards de "mais visitado"/"campeão" no topo da lista de rolês do grupo, atualizados automaticamente por trigger. No BORAH 2.0: métricas expandidas ("quem mais participou"/"quem mais escolheu", F44/F45) e integradas visualmente à tela unificada "Meu Grupo" (F23, Core), não mais 2 cards isolados.

### Ranking
Hoje: ranking geral de restaurantes (por nota), ranking de usuários (global/amigos, por XP), ranking do grupo (por rolês participados) — todos existentes e funcionais, mas o ranking do grupo está hoje escondido atrás de um menu sem rótulo. No BORAH 2.0: nenhum ranking novo é necessário (achado explícito do `RC03_FEATURE_GAP.md §5.7`) — o que muda é visibilidade, via "Meu Grupo" (F23).

### Gamificação
Hoje: XP/nível/badges funcionam plenamente para avaliação individual, curtida e comentário — e **zero** para Grupos/Rolês/Avaliação Coletiva, o gap mais citado em todas as 5 auditorias. No BORAH 2.0: XP automático estendido a confirmar presença e avaliar coletivamente (F29, Core), badges novos ligados a atividade de grupo (F30).

### Comunidade
Hoje: Feed (avaliações de quem o usuário segue), Seguidores, Comentários — todos implementados, mas o Feed tem um ponto de entrada não confirmado na UI (suspeita de funcionalidade pronta e paga, porém inacessível — `RC03_UX_AUDIT.md §2.11`). No BORAH 2.0: entrada do Feed verificada/corrigida (F24, Core, a ação de menor custo e maior retorno de toda a lista), e um Feed automático de atividade de grupo (F25) complementando o Feed social individual já existente.

---

## 3. Jornada Completa do Usuário

Descrita na forma-alvo do BORAH 2.0 (após o fechamento dos itens Core do `RC03_FEATURE_GAP.md`), com nota explícita onde a etapa já funciona hoje sem mudança.

1. **Primeiro acesso**: instala o app, chega à Splash (já com identidade de marca — gradiente + loop do símbolo), sem etapa de onboarding com tutorial (não existe hoje, não está no escopo do BORAH 2.0 conforme Feature Gap — nenhum item da lista oficial cria uma tela de onboarding nova).
2. **Cadastro**: e-mail/senha (funciona hoje) ou, no BORAH 2.0, um botão de Login com Google visível (F02) — reduzindo a etapa de digitação. Verificação de e-mail continua existindo; o retorno automático ao app após confirmar (via deep link) **não está no escopo oficial do BORAH 2.0** (não aparece na lista do `RC03_FEATURE_GAP.md §11` — só o deep link de convite de grupo, F35, foi aprovado).
3. **Entrar em grupo**: recebe um convite — no BORAH 2.0, via link direto (deep link, F35, Core) em vez de copiar/colar um código manualmente (o formulário de código continua existindo como alternativa).
4. **Criar grupo**: preenche nome/descrição, é levado direto para o grupo recém-criado (já funciona assim hoje, dead-end corrigido em rodada anterior), vê o `GroupCard` do grupo já com identidade visual própria na lista (F46, Core) e pode compartilhar o convite.
5. **Criar rolê**: busca ou cadastra o restaurante (no BORAH 2.0, com sugestão de restaurantes favoritos/não visitados pelo grupo, F13, e cadastro assistido por Google Places quando o restaurante não existe, F12), escolhe data/hora, cria — o rolê aparece na lista com identidade própria (`EventCard`, F46).
6. **Participar**: confirma ou recusa presença (já funciona bem hoje, fluxo de menor fricção do app).
7. **Avaliar**: depois do rolê, recebe uma notificação automática avisando que a avaliação está liberada (F41, Core — hoje esse aviso não existe) e avalia coletivamente (5 critérios, já existente).
8. **Publicar**: não existe, nas 5 auditorias, um conceito de "publicação manual" no BORAH 2.0 — o produto pós-pivô não tem um botão de "postar"; o que existe é o Feed automático de atividade de grupo (F25, item Importante), que nasce de ações já feitas (avaliar, confirmar presença), não de um post redigido pelo usuário. Isso é uma diferença deliberada frente à visão pré-pivô do produto (`ET-09_FEED_AND_SHARING.md`), já descartada.
9. **Ganhar XP**: hoje só acontece ao avaliar restaurante individualmente, comentar ou receber curtida. No BORAH 2.0, também acontece ao confirmar presença e ao avaliar coletivamente (F29, Core) — a mesma ação do passo 6/7 acima passa a gerar recompensa visível.
10. **Subir no ranking**: o XP ganho reflete no Ranking de Usuários (já existe) e a participação reflete no Ranking do Grupo — ambos acessíveis, no BORAH 2.0, por um caminho direto e visível ("Meu Grupo", F23, Core), não mais por um menu escondido.
11. **Criar memórias**: os rolês realizados alimentam automaticamente os cards de Memórias (já existe parcialmente hoje); no BORAH 2.0, com métricas expandidas (F44/F45) dentro da mesma tela unificada "Meu Grupo".
12. **Retornar ao aplicativo**: hoje o retorno depende quase inteiramente de o usuário lembrar sozinho (nenhuma notificação de avaliação liberada, nenhuma notificação de que o ranking do grupo mudou). No BORAH 2.0, a notificação de avaliação liberada (F41) e a visibilidade do "Meu Grupo" (F23) são os 2 mecanismos oficialmente aprovados para motivar o retorno — não existe, nas 5 auditorias, nenhum mecanismo de retorno adicional aprovado além desses (push notifications via FCM está classificado Futuro, explicitamente fora do escopo do BORAH 2.0).

---

## 4. Funcionalidades Oficiais

Lista definitiva, herdada sem alteração de `RC03_FEATURE_GAP.md §11` (única fonte de verdade sobre escopo de funcionalidade).

### Core
1. XP automático para Grupos/Rolês/Avaliação Coletiva
2. Notificação de avaliação liberada
3. "Meu Grupo" (Ranking + Estatísticas + Memórias unificados)
4. Componentes `GroupCard`/`EventCard`
5. Deep link de convite de grupo
6. Verificação e correção do ponto de entrada do Feed

### Muito importantes
7. Botão de Login com Google
8. Perfil redesenhado (atalhos com prévia de dado)
9. Preferências de notificação completas (categoria Grupos)
10. Badges automáticos de atividade de grupo
11. Descoberta de restaurantes guiada pelo grupo
12. Cadastro inteligente de restaurantes via Google Places

### Importantes
13. Galeria de fotos unificada (restaurante + rolê)
14. Avaliação por categorias em avaliações individuais de restaurante
15. Feed automático de atividade de grupo
16. Sistema de rodízio/sugestão de escolha
17. Memórias expandidas

### Opcionais
18. @username único
19. Desempate de ranking (4 níveis)

### Futuro (fora do escopo formal do BORAH 2.0)
20. Privacidade de perfil
21. Desafios diário/semanal/sazonal
22. Temporadas de grupo
23. Push notifications (FCM)

*(A lista de itens a Descartar — check-in físico geolocalizado, nomenclatura "Wrapped", backend NestJS/Prisma, bottom nav antiga — não é repetida aqui por não fazer parte do escopo de nenhuma implementação futura; está registrada em `RC03_FEATURE_GAP.md §1`/§2` para referência histórica.)*

---

## 5. Princípios do Produto

Consolidados a partir de padrões repetidos nas 5 auditorias — cada princípio abaixo cita a evidência que o sustenta, não é uma aspiração nova.

1. **Uma única ação deve alimentar múltiplos módulos.** Evidência: a Matriz de Automação (`RC03_UX_AUDIT.md §8`) mostrou que o padrão hoje já existe para avaliação individual (uma avaliação recalcula nota do restaurante, concede XP, verifica badges, pode gerar notificação de curtida/comentário) — e está ausente para o cluster Grupos/Rolês, que é exatamente o gap que o BORAH 2.0 fecha.
2. **Nenhum dado deve ser digitado duas vezes.** Evidência: o cadastro de restaurante inline durante a criação de um rolê já reaproveita a mesma tela (`CreateRestaurantPage` com `returnToCaller`, `RC03_UX_AUDIT.md §2.4`) — esse padrão é o modelo a seguir, não a exceção.
3. **Toda funcionalidade deve gerar valor para outras funcionalidades.** Evidência: o achado central da Matriz de Reutilização (`RC03_UX_AUDIT.md §10`) — `award_gamification_points()` e `create_notification()` são "motores genéricos" já usados por múltiplas funcionalidades diferentes; nenhuma funcionalidade nova aprovada (§4 deste PRD) deveria criar um motor paralelo a esses dois.
4. **Sempre privilegiar automação.** Evidência: a diretriz explícita da FASE 2 do UX Audit e o exemplo dado pelo usuário no início da RC-03 (uma ação → múltiplas consequências automáticas) — mas sempre como incentivo, nunca como obrigatoriedade (Matriz de Engajamento, `RC03_UX_AUDIT.md §11`).
5. **Sempre privilegiar reutilização.** Evidência: `RC03_FEATURE_GAP.md §4` confirmou que 9 das 15 funcionalidades Core/Muito importantes/Importantes analisadas não exigem nenhuma tabela nova no banco.
6. **Sempre privilegiar integração, nunca duplicação.** Evidência: `RC03_FEATURE_GAP.md §6` identificou size funcionalidades "novas" pedidas pelo usuário que já nascem de conectar peças existentes (Galeria+Álbum unificados, "Novo Ranking" já resolvido por "Meu Grupo", Feed automático de grupo construído sobre `notifications` em vez de uma fonte paralela).

---

## 6. Arquitetura de Produto

**Nota**: esta seção descreve como os módulos de negócio se relacionam entre si — não a arquitetura de software Flutter/Riverpod (essa está congelada e documentada separadamente, ver `project_rc02d_bundle_integration.md` na memória do projeto). É a tradução para linguagem de produto do modelo relacional confirmado em `rc03_supabase_inventory.md §6`.

```
Usuário (Perfil + Autenticação)
   │
   ├── é dono/membro de ──► Grupo
   │                          │
   │                          ├── organiza ──► Rolê (em um Restaurante)
   │                          │                  │
   │                          │                  ├── gera ──► Confirmações de Presença (por Usuário)
   │                          │                  └── gera ──► Avaliação Coletiva (por Usuário)
   │                          │
   │                          └── agrega em ──► Ranking do Grupo / Estatísticas / Memórias
   │                                             (derivados de Rolês + Avaliações Coletivas do grupo)
   │
   ├── avalia individualmente ──► Restaurante (fora do contexto de grupo)
   │                                 │
   │                                 └── agrega em ──► Ranking Geral de Restaurantes
   │
   ├── segue ──► outros Usuários ──► alimenta ──► Feed (avaliações de quem segue)
   │
   ├── toda ação relevante (avaliar, comentar, curtir — e, no BORAH 2.0, confirmar
   │   presença/avaliar coletivamente) ──► alimenta ──► Gamificação (XP/Nível/Badges)
   │                                                       │
   │                                                       └── exibida no ──► Perfil / Ranking de Usuários
   │
   └── toda mudança de estado relevante (novo grupo, novo rolê, resposta de presença,
       avaliação liberada — no BORAH 2.0) ──► gera ──► Notificação (central de avisos do Usuário)
```

**Relação entre pilares**: Grupo é o container que dá contexto a Rolê; Rolê é o evento que dá contexto a Avaliação Coletiva; Avaliação Coletiva e participação em Rolê são os insumos de Ranking/Estatísticas/Memórias do grupo. Gamificação e Notificações são **transversais** — não pertencem a nenhum módulo específico, consomem eventos de todos os outros (esse é precisamente o papel dos "motores genéricos" citados no §5). Descoberta (Restaurantes) é o único pilar que existe tanto dentro do contexto de Grupo (ao criar um Rolê) quanto fora dele (busca/avaliação individual) — é o ponto de entrada compartilhado entre o modelo social (Grupos) e o modelo individual (avaliação solo) que convivem no produto hoje.

---

## 7. Experiência Esperada

Consolidado de `RC03_DESIGN_GAP.md §2` (comparação com identidade de marca) e `§8` (BORAH 2.0).

**Como o usuário deve sentir o aplicativo**: não como uma plataforma neutra de avaliações, mas como "alguém do grupo, comemorando com você" — tom de voz documentado no Manual da Marca (`identidade visual-borah/.../CLAUDE.md`, citado em `RC03_UI_AUDIT.md §2`) e ainda pouco expresso na maioria das telas hoje (só 2 das 44 telas auditadas usam o gradiente de marca).

**Como a marca deve ser percebida**: social, espontânea, competitiva, memorável, divertida sem ser infantil, digital sem ser fria, ousada sem ser confusa (personalidade documentada em `identidade visual-borah/.../CLAUDE.md`, `RC03_UI_AUDIT.md §2`). Hoje o app está "corretamente dentro da paleta" (nenhuma tela usa cor fora do `ColorScheme`) mas majoritariamente sem a energia de marca (gradientes, motion celebratório, medalhas da Biblioteca Visual Oficial) fora das 2 telas de referência — `login_page.dart` e `gamification_profile_page.dart`.

**Como os grupos funcionam**: como comunidades fechadas por convite, com hierarquia clara (Owner/Admin/Membro) mas leve — o objetivo documentado não é controle burocrático, é dar a cada grupo de amigos um espaço próprio e visualmente distinto (`GroupCard`, item Core do BORAH 2.0).

**Como os rolês evoluem**: de "agendados" a "realizados" através de um ciclo simples — criar, confirmar presença, acontecer, avaliar — sem check-in físico geolocalizado (decisão definitiva, o mecanismo atual de confirmação prévia + passagem de tempo funciona e não deve ser substituído).

**Como as memórias são criadas**: automaticamente, a partir de rolês e avaliações já registradas — nunca por curadoria manual do usuário (não existe, em nenhuma das 5 auditorias, nenhuma funcionalidade de "criar uma memória" manualmente; todas nascem de triggers sobre dado já existente).

---

## 8. Regras Oficiais

**Nota de precisão**: esta seção distingue regras **já confirmadas no schema/código hoje** de regras que só passam a valer **após o fechamento dos itens Core do BORAH 2.0** — misturar as duas categorias sem essa marcação seria inventar comportamento, o que este documento foi explicitamente instruído a não fazer.

### Regras já confirmadas hoje (schema/código, `rc03_supabase_inventory.md`)
- Toda avaliação individual (`review`) pertence a exatamente um restaurante e a exatamente um usuário; no máximo 1 avaliação individual por usuário por restaurante (`reviews_user_restaurant_unique`).
- Toda avaliação coletiva (`event_review`) pertence a exatamente um rolê e a exatamente um usuário; no máximo 1 avaliação coletiva por usuário por rolê (`event_reviews_unique`).
- Todo rolê pertence a exatamente um grupo e a exatamente um restaurante.
- Toda foto hoje pertence a uma **avaliação individual de restaurante** (`review`), limitada a 5 por avaliação — **avaliação coletiva não suporta foto hoje** (confirmado, gap coberto pela funcionalidade Importante "Galeria unificada", item 13 do §4).
- Toda resposta de presença pertence a exatamente um usuário e um rolê; no máximo 1 resposta por usuário por rolê (`event_attendances_unique`).
- Todo grupo tem exatamente 1 dono e um código de convite único de 8 caracteres.
- Toda avaliação individual, comentário e curtida geram XP automaticamente. **Confirmar presença e avaliar coletivamente não geram XP hoje.**

### Regras que passam a valer no BORAH 2.0 (após os itens Core, §4)
- Toda participação confirmada em rolê passa a gerar XP (item Core 1).
- Toda avaliação coletiva passa a gerar XP e pode desbloquear badge (itens Core 1 e Muito importante 10).
- Toda avaliação coletiva liberada gera uma notificação automática para os participantes confirmados (item Core 2).
- Toda foto — de avaliação individual ou, no BORAH 2.0, de avaliação coletiva — passa a alimentar uma galeria unificada, escopada por restaurante ou por rolê (item Importante 13; hoje só a metade "restaurante" é tecnicamente possível).

### Regras explicitamente não documentadas em nenhuma auditoria
- "Toda avaliação pode alimentar ranking": parcialmente verdadeiro hoje (avaliação individual alimenta o ranking geral de restaurantes; avaliação coletiva alimenta a nota do rolê e as estatísticas do grupo, mas não o ranking de usuários por XP, porque não gera XP) — não existe uma regra unificada de "toda avaliação alimenta todo ranking" em nenhuma das 5 auditorias; tratar como não documentado além do que está descrito acima.
- "Toda ação deve reaproveitar dados existentes": este é um princípio de produto (já registrado no §5, item 5/6), não uma regra de dado verificável no schema — não redeclarado aqui como regra para não duplicar o §5.

---

## 9. Princípios Técnicos

Consolidado de `RC03_UX_AUDIT.md §10`, `RC03_UI_AUDIT.md §3`, `RC03_FEATURE_GAP.md §6`, e da decisão de arquitetura já congelada em sessões anteriores da RC-03 (memória do projeto).

- **Nenhuma duplicação**: confirmado como princípio ativo, não aspiracional — a limpeza de 6 componentes de design system genuinamente não utilizados (`AppFab`, `AppSecondaryButton`, `AppChip`, `AppBottomSheet`, `SkeletonLoader`, `ReviewCard`) já removidos em `4d856b7` é o precedente a seguir: não reconstruir sem necessidade concreta nova.
- **Reutilização máxima**: os "motores genéricos" (`award_gamification_points()`, `create_notification()`) e os componentes já prontos e subutilizados (`RestaurantCard`, `ScoreBubble`) devem ser a primeira opção antes de qualquer construção nova, confirmado repetidamente como o padrão de maior retorno em todas as 5 auditorias.
- **Design System único**: já existe e está bem fundamentado (`RC03_UI_AUDIT.md §2/§3`) — a fundação (cores/tipografia/espaçamento/tema) é sólida; o trabalho do BORAH 2.0 é de adoção e expressão, não de reconstrução da fundação.
- **Componentes globais**: `GroupCard`/`EventCard` (itens Core) devem ser construídos como componentes de design system reutilizáveis, não como widgets locais de uma tela só — mesmo padrão já usado por `RestaurantCard`/`RankingCard`.
- **Automações**: preferir trigger de banco (SECURITY DEFINER, padrão já estabelecido em 33 triggers existentes) a lógica replicada no cliente, sempre que a automação depender de estado do banco — é o padrão confirmado em toda a base atual.
- **Baixo acoplamento**: a arquitetura Feature-First + Clean Architecture (domain/data/application/presentation por módulo) está congelada por decisão do usuário desde a aprovação da RC-02D — nenhuma funcionalidade do §4 deste PRD deve alterar essa estrutura de camadas.

---

## 10. Visão BORAH 2.0

Imagine um grupo de amigos que, toda semana, decide entre 5 mensagens de WhatsApp e uma enquete perdida qual restaurante visitar. O BORAH existe para substituir essa bagunça por um espaço que pertence só a esse grupo — fechado, por convite, sem ruído de outras pessoas.

O grupo se forma em segundos: um cria, compartilha um link, os outros entram com um toque — sem precisar copiar e colar código nenhum. Cada grupo criado já aparece com identidade própria na tela inicial do app, não como mais uma linha de texto em uma lista.

Organizar o próximo encontro deixa de ser uma decisão do zero: o BORAH já sabe quais restaurantes o grupo favoritou, quais ainda não foram visitados, e sugere — sem nunca decidir por ninguém. Se o restaurante não estiver cadastrado, o BORAH busca o endereço, a categoria e a foto automaticamente, em vez de pedir que alguém digite tudo à mão.

No dia do encontro, confirmar presença leva um toque. Depois que o rolê acontece, o BORAH avisa — sem que ninguém precise lembrar sozinho — que chegou a hora de avaliar. E quando o grupo avalia, uma única ação já dispara uma cadeia inteira por trás da cena: a nota do rolê é calculada, o ranking do grupo se atualiza, cada participante ganha experiência e pode desbloquear uma conquista, e a memória daquele encontro passa a fazer parte da história do grupo — tudo isso automaticamente, sem nenhum passo extra.

Descobrir como o grupo está indo deixa de exigir procurar um menu escondido: "Meu Grupo" é um destino direto, visível, onde ranking, estatísticas e memórias vivem juntos, tratados com a mesma energia visual — gradiente, celebração, medalha — que hoje só a tela de evolução pessoal do usuário recebe.

E evoluir, no BORAH, para de significar só avaliar restaurantes sozinho: cada rolê organizado, cada presença confirmada, cada avaliação em grupo passa a valer experiência — o mesmo motor que já recompensa quem avalia um restaurante individualmente passa a reconhecer, com a mesma força, quem participa ativamente da vida do seu grupo.

O resultado não é um aplicativo com mais telas. É um aplicativo com menos fricção e mais retorno por cada ação: você confirma presença, e o BORAH cuida do resto — do ranking à lembrança de que aquele rolê aconteceu, e valeu a pena.

---

**Aguardando revisão do usuário antes de prosseguir para `RC03_IMPLEMENTATION_PLAN.md`, que deverá derivar exclusivamente deste PRD.**
