# RC-03 — FASE 2: UX Audit

**Status:** Draft para aprovação do usuário — análise pura, nenhum código/schema/arquivo de produto foi alterado.
**Data:** 2026-08-04
**Baseline:** este documento assume como verdade do produto os achados do [`RC03_PRODUCT_AUDIT.md`](RC03_PRODUCT_AUDIT.md) (pivô de produto confirmado, gamificação desconectada de Grupos/Rolês, notificação "avaliação liberada" ausente, etc.) — não repete a comparação documento-vs-código, foca em **experiência real de uso** a partir do código verificado.
**Fontes:** `app/lib/` (citações arquivo:linha, via `rc03_flutter_inventory.md`), `rc03_supabase_inventory.md` (triggers/RPCs, para entender o que é automático vs. manual), `BORAH_BETA_PLAYBOOK.md` (único documento existente com dado real de *cognitive walkthrough*, citado onde reforça ou diverge desta análise).
**Nota sobre "tempo estimado":** o projeto não tem telemetria real de uso (nenhum relatório contém dado de analytics de produção — só a lista do que *deveria* ser instrumentado, `UX-02_WIREFRAMES.md §19`). Todo "tempo estimado" abaixo é uma **estimativa heurística** (padrão de UX: ~2-4s por toque simples, ~8-15s por campo de formulário preenchido, ~3-5s por tela de leitura) — marcada explicitamente como estimativa, não medição.

---

## 1. Metodologia

Para cada fluxo: **Objetivo do usuário → Fluxo atual (passo a passo, com citação) → Cliques → Tempo estimado → Atrito → Confusão → Dead Ends → Duplicações → Informações escondidas → Passos desnecessários → Oportunidades de simplificação.** Depois: leitura de Product Manager, leitura de Startup (automação/reuso), matriz de funcionalidades, e Oportunidades Estratégicas priorizadas.

---

## 2. Fluxos auditados

### 2.1 Primeiro acesso (Cadastro → Verificação → Home)

- **Objetivo do usuário:** entrar no app e começar a usar o mais rápido possível.
- **Fluxo atual:** `SplashPage` decide automaticamente `/home` ou `/login` (`splash_page.dart:11`, `_restoreAndRedirect()` :25 — sem interação) → `SignupPage` (nome/e-mail/senha, `signup_page.dart:15`) → tap "Criar conta" (`:90`) → `EmailVerificationPage` (`email_verification_page.dart:12`) — usuário **sai do app**, abre o e-mail, clica no link, **precisa voltar manualmente** e tocar "Voltar para o login" (`:70`) → `LoginPage` preenche e-mail/senha de novo → tap "Entrar" (`login_page.dart:109`) → Home.
- **Cliques:** 3 toques dentro do app (Criar conta / Voltar para login / Entrar) + 1 detour totalmente fora do app (abrir e-mail, tocar link) sem retorno automático.
- **Tempo estimado:** ~40-60s dentro do app (dois formulários) + tempo variável fora do app (abrir e-mail pode levar minutos, especialmente se a mensagem cair em spam) — o tempo real da etapa mais lenta está **fora do controle do produto**.
- **Atrito:** o usuário **digita e-mail e senha duas vezes** (uma no cadastro, outra no login pós-verificação) — nenhum auto-login após confirmar o e-mail.
- **Confusão:** nada indica quanto tempo o e-mail deve levar para chegar, nem o que fazer se não chegar (só "Reenviar e-mail", `_resend()` :23).
- **Dead Ends:** nenhum forçado (há sempre "Reenviar"/"Voltar para login"), mas o retorno ao app depois de clicar o link não é automático — não há deep link/auto-login confirmado (documentado como funcionalidade futura em `UX-01`, nunca implementada).
- **Duplicações:** entrada de e-mail/senha duplicada (cadastro + login).
- **Informações escondidas:** não existe nenhuma etapa de "Completar perfil" (cidade, bio, avatar) prevista em `UX-01_APP_FLOW.md` — o usuário só preenche esses dados se, por conta própria, for em Perfil → Editar depois. Ou seja, a maioria dos perfis provavelmente fica incompleto por padrão, e nada no fluxo de onboarding avisa isso.
- **Passos desnecessários:** reautenticação manual completa após verificação de e-mail (poderia ser sessão já ativa, considerando que o Supabase Auth já suporta client-side session persistence).
- **Oportunidades de simplificação:** login automático assim que o e-mail é confirmado (deep link de retorno); micro-etapa opcional de perfil (cidade + avatar) integrada ao fim do cadastro, não deixada para descoberta espontânea.

---

### 2.2 Criar grupo → convidar amigos

- **Objetivo do usuário:** montar o grupo de amigos e trazer todo mundo para dentro o mais rápido possível.
- **Fluxo atual:** `GroupsListPage` → tap "Criar grupo" (`:41`) → `CreateGroupPage` preenche nome/descrição → tap "Criar" (`create_group_page.dart:107`) → **ao sucesso, navega direto para `GroupDetailPage`** (`extra: true`) — este é o beco-sem-saída §2.2 do Beta Playbook, **já corrigido** (confirmado no `BORAH_RELEASE_CANDIDATE_REPORT.md`, rodada UX-01). Em `GroupDetailPage`, o código de convite e o botão "Compartilhar" (`_shareInviteCode()` :81) já estão visíveis, mas **passivos** — nada destaca ou força essa ação.
- **Cliques:** Criar(1) → Criar/Salvar(2) → [chega no grupo] → Compartilhar(3) → escolher destino no share sheet do SO(4). Mínimo 3 toques no app + 1 fora.
- **Tempo estimado:** ~30-40s (preencher nome/descrição + navegar + compartilhar).
- **Atrito:** nenhum crítico — o dead-end documentado já foi corrigido.
- **Confusão:** nenhuma forte, mas o compartilhamento não é **sugerido/forçado** — um usuário apressado pode criar o grupo, ver a tela de detalhe, e sair sem convidar ninguém, sem qualquer lembrete depois.
- **Dead Ends:** nenhum (corrigido).
- **Duplicações:** nenhuma.
- **Informações escondidas:** o código de convite (`invite_code`, 8 caracteres) é o único mecanismo de entrada — não há QR code nem link universal, então "compartilhar" hoje é compartilhar texto puro (usuário do outro lado tem que copiar o código e colar manualmente na tela "Entrar com código", ver 2.3).
- **Passos desnecessários:** nenhum.
- **Oportunidades de simplificação:** abrir automaticamente o share sheet do SO logo após a criação do grupo (em vez de esperar o usuário notar o botão), com uma mensagem pré-formatada (`buildInviteShareMessage()` já existe, `group_detail_controller.dart:33` — a função já está pronta, só falta ser chamada proativamente no momento certo).

---

### 2.3 Entrar em grupo (código de convite)

- **Objetivo do usuário:** entrar no grupo de um amigo o mais rápido possível a partir de um convite recebido (provavelmente por WhatsApp).
- **Fluxo atual:** `GroupsListPage` → tap "Entrar com código" (`:54`) → `JoinGroupPage` → digita/cola o código de 8 caracteres (auto-uppercase) → tap "Entrar" (`join_group_page.dart:84`).
- **Cliques:** 2 toques + digitação manual de 8 caracteres (ou copiar/colar de outro app).
- **Tempo estimado:** ~20-30s, assumindo o usuário já tem o código copiado.
- **Atrito real e confirmado:** **não existe deep link** — o convite chega como texto puro (mensagem construída por `buildInviteShareMessage()`), e o destinatário precisa: abrir o BORAH manualmente → achar o botão certo → colar o código manualmente. Nenhum pacote de deep link (`uni_links`/`app_links`) está entre as dependências do projeto (confirmado, `rc03_flutter_inventory.md §17`) — isso não é um bug, é uma funcionalidade nunca construída (já prevista como "futuro" em `UX-01`).
- **Confusão:** para um usuário que nunca usou o BORAH, receber "entra no meu grupo, código: XXXXXXXX" por WhatsApp e precisar **primeiro baixar o app, se cadastrar, verificar e-mail, e só então achar a tela certa para colar o código** é uma jornada de ativação longa com múltiplas chances de desistência antes de sequer ver o valor do produto (ver §3, pergunta de PM).
- **Dead Ends:** nenhum dentro da tela em si.
- **Duplicações:** nenhuma.
- **Informações escondidas:** nada.
- **Passos desnecessários:** digitação manual do código quando poderia ser 1 toque (deep link).
- **Oportunidades de simplificação:** deep link `borah://join/{invite_code}` (ou link universal `https://borah.app/join/{code}`) que abre o app direto na tela de confirmação de entrada — colapsaria toda a etapa "abrir app → achar botão → colar código" em um único toque no link recebido.

---

### 2.4 Criar rolê (fluxo mais profundo do app)

- **Objetivo do usuário:** marcar o próximo encontro do grupo com o mínimo de fricção.
- **Fluxo atual:** `GroupDetailPage` → ícone "Rolês" na topbar → `EventsListPage` → tap "+" (`:69`) → `CreateEventPage` Etapa 1: buscar restaurante (`_search()` :55) → selecionar (`_selectRestaurant()` :61) **OU**, se não encontrar, tap "Cadastrar restaurante" (`_createRestaurant()` :82) → preenche 6 campos em `CreateRestaurantPage` → submit → **retorna automaticamente** para a Etapa 2 via `returnToCaller` (bom exemplo de reuso, ver §4) → Etapa 2: escolher data (`_pickDate()` :94) → escolher hora (`_pickTime()` :110) → tap "Criar" (`_create()` :134→:337).
- **Cliques:** confirmado pelo `BORAH_BETA_PLAYBOOK.md §3` como **o fluxo mais profundo do app: ~7 toques / 4 telas** no caminho feliz (restaurante já cadastrado). Se o restaurante não existir, soma-se o formulário completo de cadastro (6 campos) — o caminho mais longo de toques único do produto inteiro.
- **Tempo estimado:** ~60-90s no caminho feliz; **3-5 minutos** se precisar cadastrar o restaurante do zero.
- **Atrito:** o cadastro de restaurante embutido é o ponto mais pesado — nome, categoria, descrição, endereço, cidade, estado, todos texto livre, sem nenhum preenchimento automático (sem Google Places, confirmado no Product Audit §2.3).
- **Confusão:** nenhuma forte na etapa 2 (data/hora é padrão), mas a decisão de "quem escolhe o restaurante" não tem nenhum apoio do produto — o ET-05 previa um **rodízio automático** sugerindo quem escolhe, que nunca foi implementado (Product Audit §2.9); hoje é sempre "quem lembrar/tiver disposição primeiro".
- **Dead Ends:** o antigo dead-end de busca sem resultado (§2.1 do Beta Playbook) **já foi corrigido** — hoje existe o atalho para cadastro inline.
- **Duplicações:** nenhuma — o cadastro de restaurante reaproveita literalmente o mesmo widget (`CreateRestaurantPage` com `returnToCaller`), um exemplo positivo de reuso, não duplicação.
- **Informações escondidas:** nada de grave.
- **Passos desnecessários:** o usuário precisa navegar até "Rolês" (uma tela inteira, `EventsListPage`) antes de conseguir criar um — se o objetivo é "criar rapidamente", isso é uma tela intermediária pura de listagem antes da ação.
- **Oportunidades de simplificação:** (a) atalho direto "Criar rolê" a partir de `GroupDetailPage` sem passar pela lista; (b) sugestão automática de restaurante com base no histórico do grupo (dados de `event_reviews`/`events` já existem para isso — reuso de dado, ver §4); (c) rodízio de escolha automático, mesmo que simples ("é a vez de fulano" com base em quem escolheu por último).

---

### 2.5 Confirmar presença em rolê

- **Objetivo do usuário:** avisar rapidamente se vai ou não.
- **Fluxo atual:** notificação chega automaticamente (trigger `notify_new_event_trigger`, fan-out para todo o grupo exceto o organizador, confirmado live no inventário Supabase §3b) → `EventDetailPage` → tap confirmar/recusar (`_confirm()`/`_decline()` :198,202→:317,323).
- **Cliques:** 1 toque (a partir da notificação ou da tela do rolê).
- **Tempo estimado:** ~10-15s.
- **Atrito:** nenhum — este é um dos fluxos mais bem resolvidos do app.
- **Confusão:** nenhuma.
- **Dead Ends:** nenhum.
- **Duplicações:** nenhuma.
- **Informações escondidas:** nada.
- **Passos desnecessários:** nenhum.
- **Oportunidades de simplificação:** já está próximo do ideal — único ponto de melhora seria ação direta no corpo da notificação push (quando push existir, hoje é só in-app), sem precisar abrir o app.

---

### 2.6 Avaliação coletiva do rolê (maior lacuna de automação confirmada)

- **Objetivo do usuário:** registrar como foi o rolê enquanto ainda está fresco na memória.
- **Fluxo atual:** depois que o rolê acontece e o usuário confirmou presença, o botão "Avaliar rolê" aparece em `EventDetailPage` (`:465`, condicional a `can_review_event()` = presença confirmada + evento no passado) → `SubmitEventReviewPage` → preenche **5 campos numéricos de texto livre** (comida/atendimento/ambiente/custo-benefício/geral) + comentário → tap enviar (`:139`).
- **Cliques:** só 2 toques (Avaliar + Enviar) — a fricção real não está nos toques.
- **Tempo estimado:** ~60-90s para preencher 5 notas + comentário — o preenchimento de dados é o gargalo, não a navegação.
- **Atrito confirmado por 2 fontes:** (1) `BORAH_BETA_PLAYBOOK.md §4` já identificou que 5 campos numéricos em texto livre (não seletor de estrelas) é a única tela do app pedindo 5 números de uma vez — maior risco de abandono de review; (2) **não existe nenhuma notificação avisando que a avaliação está liberada** (confirmado live no inventário Supabase §3b — `event_reviews` não tem nenhum trigger de notificação) — o usuário só descobre que pode avaliar se **voltar por conta própria** ao grupo/rolê.
- **Confusão:** o usuário não sabe, sem verificar manualmente, que uma janela de avaliação está aberta — não há prazo comunicado, nem lembrete.
- **Dead Ends:** funcional, mas silencioso — não é um dead-end de navegação, é um **dead-end de descoberta** (a ação existe, mas ninguém avisa que ela existe agora).
- **Duplicações:** ver §2.7 — este é o segundo de dois sistemas de avaliação paralelos do app (o outro é `Review`, individual, de restaurante).
- **Informações escondidas:** a mecânica de recompensa é a mais escondida do produto: avaliar um rolê **não concede XP nenhum** (confirmado, Product Audit §2.8/§2.11), enquanto avaliar um restaurante individualmente concede 40XP — nada na tela avisa essa diferença, e um usuário engajado em gamificação não tem como adivinhar isso.
- **Passos desnecessários:** nenhum na navegação; o problema é ausência de lembrete, não excesso de passos.
- **Oportunidades de simplificação:** (a) notificação automática "avaliação liberada" assim que `can_review_event()` passa a ser verdadeiro para cada participante confirmado (a infraestrutura de notificação — `create_notification()` — já existe e é genérica, só falta 1 trigger novo); (b) seletor de estrelas em vez de campo numérico livre; (c) conceder XP simetricamente ao review individual.

---

### 2.7 Avaliar restaurante individualmente (fora do grupo)

- **Objetivo do usuário:** deixar uma opinião sobre um restaurante que visitou (não necessariamente em rolê).
- **Fluxo atual:** `RestaurantDetailPage` → "Ver avaliações" → `ReviewsListPage` → tap "+" → `CreateReviewPage` → preenche 1 nota + comentário → submit → `pushReplacement` para `ReviewDetailPage`.
- **Cliques:** 3 toques.
- **Tempo estimado:** ~30-40s.
- **Atrito:** baixo — fluxo simples e curto.
- **Confusão:** ver duplicação abaixo — a maior confusão não está dentro deste fluxo, está na coexistência com o fluxo 2.6.
- **Dead Ends:** nenhum.
- **Duplicações confirmadas (achado central desta auditoria):** o app tem **dois sistemas de avaliação completamente separados e paralelos** — `Review` (este fluxo, nota única 1-5, 40XP, badges) e `EventReview` (fluxo 2.6, 5 notas, zero XP). Do ponto de vista de um usuário, "avaliar" é um único conceito mental; do ponto de vista do produto, são duas entidades de banco diferentes (`reviews` vs. `event_reviews`), duas telas diferentes, duas regras de recompensa diferentes, sem nenhuma navegação cruzada entre elas (avaliar um rolê não sugere "quer avaliar o restaurante também?" e vice-versa).
- **Informações escondidas:** nada além do já citado.
- **Passos desnecessários:** nenhum.
- **Oportunidades de simplificação:** ver Oportunidade Estratégica #6 (§6) — unificar semântica de recompensa entre os dois sistemas, e considerar se avaliar um rolê deveria automaticamente contar como (ou sugerir) uma avaliação do restaurante.

---

### 2.8 Ver Ranking do Grupo / Estatísticas / Memórias

- **Objetivo do usuário:** ver o "placar" do grupo — quem está ganhando, como o grupo está indo.
- **Fluxo atual:** "Memórias" (cards de "mais visitado"/"campeão") aparecem **automaticamente** no topo de `EventsListPage`, sem toque adicional — bem resolvido. Já "Ranking do Grupo" e "Estatísticas" exigem: `GroupDetailPage` → abrir o **menu overflow** da topbar → tap "Ranking" **ou** tap "Estatísticas" (2 itens de menu separados, levando a 2 páginas separadas: `GroupRankingPage` e `GroupStatsPage`).
- **Cliques:** 2 toques por destino (abrir menu + escolher item) — e são necessários 2 fluxos completos separados (4 toques) para ver as duas informações, que um usuário provavelmente pensa como "uma coisa só" (como meu grupo está indo).
- **Tempo estimado:** ~10-15s por tela, mas exige descobrir o menu primeiro.
- **Atrito:** o próprio `BORAH_BETA_PLAYBOOK.md §7` já identificou isso como o "**momento WOW**" do produto (ranking, memórias, estatísticas) e apontou que ele é "estruturalmente tardio" — só aparece depois de rolês acumulados. Esta auditoria acrescenta um achado novo: **mesmo quando os dados já existem, o caminho até vê-los está escondido atrás de um ícone de overflow menu sem rótulo visível**, não é uma aba ou botão primário.
- **Confusão:** um usuário novo dificilmente vai pensar em tocar no menu de 3 pontinhos para achar "o quanto meu grupo já rendeu" — não há nenhuma pista visual de que essa informação existe ali.
- **Dead Ends:** nenhum, mas discoverability muito baixa.
- **Duplicações confirmadas:** `GroupRankingPage` (ranking de membros) e `GroupStatsPage` (estatísticas do grupo/restaurantes/rolês) são duas telas separadas alimentadas pelas mesmas fontes de dado (`group_members` desnormalizado + `events`/`event_reviews`) — do ponto de vista do usuário, é uma fragmentação artificial de uma única pergunta ("como estamos indo?").
- **Informações escondidas:** as métricas "quem mais participou"/"quem mais escolheu" nunca foram implementadas (gap já confirmado no `BORAH_RELEASE_CANDIDATE_REPORT.md` e no Product Audit §2.12) — o que existe hoje (Mais visitado/Campeão) é só uma fração do que "Memórias" prometia.
- **Passos desnecessários:** abrir um menu para achar 2 telas que deveriam ser abas de uma única tela "Meu Grupo".
- **Oportunidades de simplificação:** unificar `GroupRankingPage` + `GroupStatsPage` em uma única tela com abas (Ranking/Estatísticas/Memórias), acessível por um botão primário e visível em `GroupDetailPage` — não escondido em menu.

---

### 2.9 Editar perfil e trocar avatar

- **Objetivo do usuário:** atualizar informações pessoais ou a foto.
- **Fluxo atual:** `ProfilePage` → "Editar perfil" (`:133`) → `EditProfilePage` (nome/bio/cidade/estado) → link **separado** "Alterar foto" → `ChangeAvatarPage` (nova tela inteira) → seleciona imagem → tap upload (`:122`) → volta.
- **Cliques:** editar texto = 2 toques; trocar foto = **outros** 3 toques em uma tela totalmente separada (link → selecionar → upload).
- **Tempo estimado:** ~20s (texto) + ~30s (foto), como dois fluxos desconectados.
- **Atrito:** trocar avatar é uma ação tão comum (e tão associada visualmente a "editar perfil") que a maioria dos apps resolve com um único toque na própria foto dentro da tela de edição — aqui é uma tela à parte.
- **Confusão:** um usuário que só quer trocar a foto precisa entrar em "Editar perfil" primeiro (não há atalho direto de `ProfilePage` para `ChangeAvatarPage`) e depois achar o link dentro do formulário.
- **Dead Ends:** nenhum.
- **Duplicações:** nenhuma direta, mas fragmentação desnecessária de uma única tarefa mental ("editar meu perfil").
- **Informações escondidas:** nada.
- **Passos desnecessários:** uma tela inteira (`ChangeAvatarPage`) para uma ação que poderia ser um avatar tocável dentro de `EditProfilePage`.
- **Oportunidades de simplificação:** fundir `ChangeAvatarPage` em `EditProfilePage` como um avatar tocável no topo do formulário — elimina uma tela inteira.

---

### 2.10 Notificações e preferências

- **Objetivo do usuário:** saber o que aconteceu e controlar o que quer ser avisado.
- **Fluxo atual:** `NotificationsPage` → tap item → `NotificationDetailPage` (marca como lida, navega ao alvo) — funciona bem. Preferências: `NotificationPreferencesPage` é **um único `SwitchListTile`** (categoria "social", `:14`), embora o banco já suporte a categoria `'groups'` desde `20260801130000` (confirmado, Product Audit §2.13).
- **Cliques:** central de notificações, 1-2 toques; preferências, 1 toque (mas só controla 1 de 2 categorias existentes no banco).
- **Tempo estimado:** ~10s.
- **Atrito:** baixo na navegação; o problema é a **incompletude** da tela de preferências.
- **Confusão:** um usuário que quer desligar notificações de rolê/grupo não tem como — só existe o toggle "social", mesmo o banco já tendo a categoria certa pronta.
- **Dead Ends:** nenhum.
- **Duplicações:** nenhuma.
- **Informações escondidas:** a existência da categoria `'groups'` no schema é literalmente invisível na UI — é um caso claro de "back-end pronto, front-end incompleto".
- **Passos desnecessários:** nenhum.
- **Oportunidades de simplificação:** adicionar o segundo `SwitchListTile` para a categoria `'groups'` — mudança pequena, unlock imediato (não é decisão de produto nova, é fechar uma lacuna já mapeada).

---

### 2.11 Feed / Social (achado que precisa de verificação direta)

- **Objetivo do usuário:** ver o que as pessoas que segue andam avaliando.
- **Fluxo atual:** `FeedPage` (lista de avaliações recentes de quem o usuário segue, com pull-to-refresh) e a rota `/feed` existem e estão implementadas (`feed_controller.dart`, `feed_page.dart:19`). **Porém**, no inventário de código verificado, **não foi encontrado nenhum botão, ícone ou item de menu em nenhuma tela principal que navegue explicitamente para `/feed`** — a rota não está na bottom nav (confirmado, só Grupos/Restaurantes/Favoritos/Perfil), e nenhuma das 44 páginas do inventário cita um handler `onTap`/`onPressed` apontando para `/feed`.
- **Atrito/Dead End (achado sinalizado, não 100% confirmado — requer verificação direta antes de agir):** isso sugere fortemente que **o Feed pode ser uma funcionalidade completa e funcional, mas sem nenhum ponto de entrada visível no app** — um recurso inteiro potencialmente inacessível. Como este documento segue a regra de nunca afirmar sem prova direta de código, marco isso como **alta suspeita, não fato confirmado**: é possível que exista um ponto de entrada que o agente de inventário não tenha capturado (ex.: dentro de um widget não documentado linha a linha). **Recomendo verificação direta de código (grep por `'/feed'` em todo `app/lib/`) antes da FASE 5 (Feature Gap)**, porque se confirmado, é o dead-end mais severo do produto — pior que os já documentados, porque não é "difícil de achar", é potencialmente **impossível de achar** pela UI.
- **Oportunidades de simplificação:** se confirmado o achado, a correção é trivial (adicionar um ponto de entrada) — mas a decisão de produto sobre *onde* colocá-lo (dado que Feed foi conscientemente rebaixado no pivô) é do usuário.

---

## 3. Pensando como Product Manager

**"Se eu fosse um usuário novo, onde eu desistiria?"**
O ponto de maior risco de desistência é a ativação por convite (§2.1 + §2.3 combinados): alguém recebe um código de convite por WhatsApp, precisa baixar o app, se cadastrar, sair do app para verificar e-mail, voltar, logar de novo, achar o botão certo, e só então colar manualmente um código de 8 caracteres — **6+ trocas de contexto antes de ver qualquer valor do produto**. Esse funil de ativação é hoje o mais longo e mais frágil do app, mais longo até que o próprio funil de "Criar rolê" (que ao menos é usado por quem já está convencido).

**"Quais funcionalidades eu nunca descobriria?"**
Ranking do Grupo e Estatísticas (escondidos atrás de um menu overflow sem rótulo, §2.8) e, se o achado do §2.11 se confirmar, o Feed inteiro. Também a diferença de recompensa entre avaliar um restaurante (40XP) e avaliar um rolê (0XP) — nada na UI comunica essa regra, então o usuário só percebe "por acaso", comparando notificações de level-up.

**"Quais telas parecem existir apenas porque foram implementadas?"**
`ChangeAvatarPage` como tela separada (§2.9) é o exemplo mais claro — nenhuma razão de produto exige que trocar avatar seja uma jornada de navegação própria, é decisão de implementação, não de UX. `GroupRankingPage`/`GroupStatsPage` como duas telas separadas (§2.8) tem o mesmo cheiro — parecem ser "dois controllers, então duas telas", não "duas perguntas diferentes do usuário".

**"Quais funcionalidades deveriam estar integradas?"**
Avaliação de restaurante (`Review`) e avaliação coletiva de rolê (`EventReview`) deveriam compartilhar pelo menos a lógica de recompensa (XP), mesmo continuando como fluxos de dados distintos. Ranking do Grupo + Estatísticas + Memórias deveriam ser uma única superfície ("Meu Grupo"), não três lugares diferentes. E a criação de rolê deveria estar integrada ao histórico do grupo (sugerir restaurante/data com base em rolês anteriores), não começar sempre do zero.

---

## 4. Pensando como Startup — automação por fluxo

| Fluxo | Reduzir cliques? | Eliminar uma tela? | Automatizar? | Reutilizar dado existente? |
|---|---|---|---|---|
| Primeiro acesso | Sim — pular login manual pós-verificação | Não | Sim — auto-login via deep link de confirmação | — |
| Criar grupo → convidar | Sim — abrir share sheet automaticamente | Não | Sim — `buildInviteShareMessage()` já existe, só falta disparar sozinho | — |
| Entrar em grupo | Sim — deep link elimina digitação | Sim — a tela "colar código" vira um passo intermediário do deep link, não destino final | Sim — deep link `borah://join/{code}` | — |
| Criar rolê | Sim — atalho direto do grupo | Não | Sim — sugestão de restaurante/data por histórico | Sim — `events`/`event_reviews` já têm o histórico completo do grupo |
| Confirmar presença | Já ótimo | — | Já automático (notificação fan-out) | — |
| Avaliar rolê | Já ótimo (2 toques) | Não | **Sim — maior oportunidade do produto**: notificação automática de liberação | Sim — `can_review_event()` já calcula exatamente o momento certo, só falta virar notificação |
| Avaliar restaurante | Já ótimo | Não | Sim — XP simétrico ao avaliar rolê | Sim — motor `award_gamification_points()` já existe e é genérico |
| Ranking/Estatísticas/Memórias | Sim — 1 tela com abas em vez de menu + 2 telas | Sim — fundir 2 em 1 | Não necessariamente | Sim — mesmas colunas desnormalizadas já alimentam as 3 visões |
| Editar perfil/avatar | Sim — avatar tocável na mesma tela | Sim — eliminar `ChangeAvatarPage` | Não | — |
| Notificações/preferências | Já ótimo | Não | Não | Sim — categoria `'groups'` já existe no banco, só falta o toggle |
| Feed | A confirmar | A confirmar | — | — |

---

## 5. Matriz de funcionalidades

| Funcionalidade | Existe | Funciona | Completa | Reutilizável | Alimenta outras | Duplicação | Desperdício | Automatizável |
|---|---|---|---|---|---|---|---|---|
| Autenticação e-mail/senha | Sim | Sim | Sim | — | Sessão → toda a app | Não | Não | Parcial (auto-login pós-verificação) |
| Login social (Google/Apple/Facebook) | Sim (repo+controller) | Parcial (Google sem botão de UI) | Não | — | — | Não | Sim — método pronto sem UI | — |
| Grupos (criar/entrar/gerenciar) | Sim | Sim | Parcial (sem rodízio, sem temporadas) | Sim (RLS reaproveitada por Rolês) | Rolês, Ranking, Notificações | Não | Não | Parcial (rodízio) |
| Convite por código | Sim | Sim | Sim (mas manual) | — | — | Não | Não | Sim (deep link) |
| Rolês (criar/confirmar/cancelar/reagendar) | Sim | Sim | Sim | Sim (reaproveita cadastro de restaurante) | EventReviews, GroupRanking, Notificações | Não | Não | Parcial (sugestão de restaurante) |
| Avaliação de restaurante (`Review`) | Sim | Sim | Sim | Sim (motor de XP) | Gamificação, Ranking geral | **Sim — com EventReview** | Não | — |
| Avaliação coletiva (`EventReview`) | Sim | Sim | Sim | Não (motor de XP não conectado) | GroupRanking (parcial) | **Sim — com Review** | **Sim — não gera XP nem notificação** | **Sim — maior oportunidade do audit** |
| Ranking geral de restaurantes | Sim | Sim | Parcial (sem desempate) | — | — | Não | Não | Não |
| Ranking do Grupo | Sim | Sim | Sim | Sim (mesma fonte de dado que Estatísticas) | — | **Sim — com GroupStats** | Não | Não |
| Estatísticas do Grupo | Sim | Sim | Sim | Sim | — | **Sim — com GroupRanking** | Não | Não |
| Memórias | Sim | Sim | Parcial (só 2 de N métricas prometidas) | — | — | Não | Não | Não |
| Gamificação (XP/nível/badges) | Sim | Sim | Parcial (desconectada de Grupos/Rolês) | **Sim — motor genérico já testado em produção** | Poderia alimentar Ranking do Grupo, Perfil, Feed | Não | **Sim — infra pronta e subutilizada** | **Sim — 1 trigger fecha o loop** |
| Ranking de usuários (global/amigos) | Sim | Sim | Sim | — | — | Não | Não | Não |
| Favoritos | Sim | Sim | Sim | — | — | Não | Não | Não |
| Feed | Sim (código) | A confirmar (sem ponto de entrada visível) | A confirmar | — | — | Não | **Possível — feature inteira sem entrada** | — |
| Seguidores/Comentários | Sim | Sim | Sim | — | Feed | Não | Não | Não |
| Notificações in-app | Sim | Sim | Parcial (faltam 2 gatilhos: avaliação liberada, grupo criado) | Sim (`create_notification()` genérica) | — | Não | Não | **Sim — só faltam os triggers** |
| Preferências de notificação | Sim | Parcial (UI só cobre 1 de 2 categorias) | Não | — | — | Não | **Sim — categoria pronta no banco, sem UI** | Não |
| Administração/Moderação | Sim | Sim | Sim | — | — | Não | Não | Não |
| Exclusão de conta | Sim | Sim | Sim | — | — | Não | Não | Não (corretamente não-automatizado, é destrutivo) |

---

## 6. Oportunidades Estratégicas

### #1 — Conectar Grupos/Rolês ao motor de gamificação
- **Problema:** participar de grupo, criar/confirmar rolê e avaliar coletivamente concedem zero XP — o núcleo atual do produto (pós-pivô) está totalmente fora do sistema de progressão que já existe e funciona (§2.6, §2.8, Product Audit §2.8).
- **Solução:** criar triggers análogos aos 3 já existentes (`handle_gamification_new_review/comment/like`) para `event_attendances` (confirmar presença) e `event_reviews` (avaliar rolê), chamando `award_gamification_points()` — função já genérica, já testada em produção.
- **Impacto:** altíssimo — reconecta o motor de retenção mais forte do produto ao seu próprio núcleo.
- **Complexidade:** baixa — a função central já existe, é "só" escrever 1-2 triggers SQL seguindo o padrão dos 3 já existentes.
- **Valor para o usuário:** alto — sensação de progresso ao fazer a atividade principal do app.
- **Valor para o produto:** altíssimo — maior alavanca de engajamento disponível hoje.
- **Prioridade: P0.**

### #2 — Notificação "avaliação liberada"
- **Problema:** usuário não sabe quando pode avaliar um rolê; depende 100% de lembrar sozinho (§2.6) — gap confirmado por 3 fontes independentes desde antes desta auditoria.
- **Solução:** trigger em `event_attendances`/`events` que dispara `create_notification()` quando `can_review_event()` passa a ser verdadeiro para cada participante confirmado.
- **Impacto:** alto — fecha o loop comportamental "aconteceu → avalie agora".
- **Complexidade:** baixa — infraestrutura de notificação inteira já existe e é genérica.
- **Valor para o usuário:** alto.
- **Valor para o produto:** alto — mais avaliações coletadas = ranking/memórias mais ricos.
- **Prioridade: P0.**

### #3 — Unificar Ranking do Grupo + Estatísticas + Memórias em uma tela
- **Problema:** o "momento WOW" do produto está fragmentado em 3 lugares (2 atrás de um menu sem rótulo) — já identificado como estruturalmente tardio pelo Beta Playbook, agravado por baixa descoberta (§2.8).
- **Solução:** tela única "Meu Grupo" com abas (Ranking/Estatísticas/Memórias), acessível por botão primário visível em `GroupDetailPage`, não menu overflow.
- **Impacto:** alto — é literalmente o momento de maior emoção do produto, hoje escondido.
- **Complexidade:** média (é reorganização de UI sobre dados que já existem, não nova lógica de backend).
- **Valor para o usuário:** alto.
- **Valor para o produto:** alto — retenção e compartilhamento orgânico ("olha o ranking do nosso grupo").
- **Prioridade: P0.**

### #4 — Cadastro de restaurante via Google Places
- **Problema:** cadastro 100% manual, sem lat/long confiável, sem horário/telefone/foto — maior fricção de dados do app, e é etapa obrigatória do fluxo mais profundo (Criar rolê, §2.4).
- **Solução:** autocomplete Google Places no cadastro, preenchendo nome/categoria/endereço/lat-long/foto automaticamente.
- **Impacto:** alto — reduz drasticamente o pior gargalo de digitação do produto.
- **Complexidade:** média-alta (integração de API paga externa, chave de API, custo por request).
- **Valor para o usuário:** alto.
- **Valor para o produto:** alto — dado de restaurante mais confiável para ranking/busca.
- **Prioridade: P1.**

### #5 — Deep link de convite de grupo
- **Problema:** convite hoje é um código de texto que precisa ser copiado/colado manualmente — maior ponto de risco de desistência na ativação de novos usuários (§2.3, §3).
- **Solução:** deep link/link universal que abre o app direto na tela de confirmação de entrada no grupo.
- **Impacto:** alto — ativação é o funil mais frágil identificado nesta auditoria.
- **Complexidade:** média (infraestrutura de deep link nunca implementada, precisa configurar Android App Links/iOS Universal Links).
- **Valor para o usuário:** alto.
- **Valor para o produto:** alto — reduz atrito de crescimento viral (convites entre amigos são o principal canal de aquisição do produto).
- **Prioridade: P1.**

### #6 — Unificar recompensa entre Review e EventReview
- **Problema:** dois sistemas de avaliação paralelos com regras de recompensa diferentes e nenhuma comunicação disso ao usuário (§2.7).
- **Solução:** conceder XP simétrico em `event_reviews` (parte da Oportunidade #1) e, produto-a-produto, decidir se os dois fluxos deveriam ser mais visualmente unificados (mesma linguagem visual de "Avaliar").
- **Impacto:** médio-alto — remove uma inconsistência que confunde usuários engajados em gamificação.
- **Complexidade:** baixa (a parte de XP é a mesma da Oportunidade #1).
- **Valor para o usuário:** médio.
- **Valor para o produto:** médio.
- **Prioridade: P1.**

### #7 — Expor toggle de notificações de Grupos na UI de preferências
- **Problema:** backend já suporta categoria `'groups'` desde `20260801130000`, UI só expõe `'social'` (§2.10).
- **Solução:** adicionar 1 `SwitchListTile` na tela já existente.
- **Impacto:** médio — fecha uma lacuna pequena mas visível.
- **Complexidade:** muito baixa.
- **Valor para o usuário:** médio.
- **Valor para o produto:** baixo-médio.
- **Prioridade: P2 (quick win — vale fazer cedo apesar do impacto menor, pelo baixíssimo custo).**

### #8 — Verificar e resolver o ponto de entrada do Feed
- **Problema:** possível funcionalidade completa sem nenhum ponto de entrada visível na UI (§2.11) — não confirmado com certeza absoluta, mas alta suspeita.
- **Solução:** primeiro, verificação direta de código; depois, decisão de produto (adicionar entrada, ou formalizar a descontinuação consciente do Feed como superfície independente).
- **Impacto:** desconhecido até verificação — potencialmente alto se confirmado.
- **Complexidade:** baixa para verificar, baixa para corrigir se confirmado.
- **Valor para o usuário:** a definir.
- **Valor para o produto:** a definir.
- **Prioridade: P0 para a verificação em si (é rápida); prioridade da correção depende do resultado.**

### #9 — Fundir edição de perfil e troca de avatar em uma única tela
- **Problema:** `ChangeAvatarPage` como tela separada de `EditProfilePage` fragmenta uma única tarefa mental (§2.9, §3).
- **Solução:** avatar tocável dentro do próprio formulário de edição de perfil.
- **Impacto:** baixo-médio — melhora de polimento, não de funil crítico.
- **Complexidade:** baixa.
- **Valor para o usuário:** médio.
- **Valor para o produto:** baixo.
- **Prioridade: P2.**

### #10 — Rodízio automático de escolha em Grupos
- **Problema:** ET-05 previa sugestão automática de quem escolhe o próximo restaurante; nunca foi implementado; hoje depende só de boa vontade (§2.4, Product Audit §2.9).
- **Solução:** campo simples "última pessoa que escolheu" por grupo, com sugestão (não obrigação) de quem escolhe a seguir na tela de criar rolê.
- **Impacto:** médio — resolve uma fricção social sutil (quem sempre escolhe/nunca escolhe).
- **Complexidade:** média (precisa de decisão de produto sobre a regra exata + nova coluna/lógica).
- **Valor para o usuário:** médio.
- **Valor para o produto:** médio.
- **Prioridade: P2.**

---

### Priorização consolidada

| Prioridade | Oportunidades |
|---|---|
| **P0** | #1 Gamificação em Grupos/Rolês · #2 Notificação de avaliação liberada · #3 Unificar Ranking/Estatísticas/Memórias · #8 Verificar entrada do Feed |
| **P1** | #4 Google Places · #5 Deep link de convite · #6 Unificar recompensa Review/EventReview |
| **P2** | #7 Toggle de notificações de Grupos · #9 Fundir edição de perfil/avatar · #10 Rodízio automático |

Os 4 itens P0 têm uma característica em comum que reforça a tese central da RC-03: **em todos os quatro, a infraestrutura de backend já existe e está pronta** (`award_gamification_points()`, `create_notification()`, as colunas desnormalizadas de ranking, e a própria `FeedPage`/`FeedController`) — o trabalho que falta é de conexão e de superfície de UI, não de construção de motor novo do zero. Isso é exatamente o padrão de "reutilização" que a FASE 7 deve aprofundar.

---

## 7. Matriz de Impacto — as 10 Oportunidades Estratégicas, comparadas

| # | Oportunidade | Impacto usuário | Impacto negócio | Complexidade técnica | Tempo estimado | Dependências | Risco de regressão | Prioridade |
|---|---|---|---|---|---|---|---|---|
| 1 | Gamificação em Grupos/Rolês | Alto — sensação de progresso na atividade que o usuário mais faz hoje | Altíssimo — maior alavanca de engajamento disponível, reconecta o motor de retenção ao núcleo do produto pós-pivô | Baixa — replicar o padrão de 3 triggers já existentes (`handle_gamification_new_review/comment/like`), reaproveitando `award_gamification_points()`/`award_badge()` sem alterá-los | Curto (poucos dias de trabalho de trigger + teste) | Nenhuma bloqueante — infraestrutura 100% pronta | Baixo — funções centrais já testadas em produção (reviews/comments/likes); só é preciso não duplicar concessão de XP se o usuário também avaliar o restaurante do mesmo rolê separadamente (ver Oportunidade #6) | **P0** |
| 2 | Notificação "avaliação liberada" | Alto — fecha o loop "aconteceu → avalie agora", reduz dependência de o usuário lembrar sozinho | Alto — mais avaliações coletadas alimentam ranking/memórias/feed | Baixa — `create_notification()` já é genérica e usada por 6 gatilhos diferentes; só falta 1 trigger novo em `event_attendances`/`events` chamando `can_review_event()` | Curto | Nenhuma bloqueante | Baixo — é uma notificação nova, não altera comportamento existente | **P0** |
| 3 | Unificar Ranking/Estatísticas/Memórias | Alto — expõe o "momento WOW" do produto, hoje escondido atrás de menu sem rótulo | Alto — retenção e compartilhamento orgânico ("olha o ranking do nosso grupo") | Média — é reorganização de UI (abas) sobre dados que já existem (`GroupRankingController`, `EventsListController`), sem nova lógica de backend | Médio (dias, não semanas — é composição de telas já funcionais) | Nenhuma bloqueante | Baixo-médio — requer testar navegação/rotas que hoje apontam para as 2 telas separadas (`/groups/:id/ranking`, `/groups/:id/stats`) | **P0** |
| 8 | Verificar/resolver entrada do Feed | A definir até verificação — potencialmente alto (destrava uma funcionalidade inteira) | A definir | Baixíssima para verificar (grep); baixa para corrigir se confirmado (1 botão) | Muito curto para verificação; curto para correção | Nenhuma | Muito baixo | **P0** |
| 4 | Cadastro de restaurante via Google Places | Alto — elimina o maior gargalo de digitação do produto, presente no fluxo mais profundo (Criar rolê) | Alto — dado de restaurante mais confiável (lat/long real, categoria padronizada, foto) melhora busca/ranking/geolocalização futura | Média-alta — integração de API paga externa, gestão de chave/custo por request, ajuste de schema se novos campos (telefone/horário) forem adotados | Médio-longo (semanas — inclui setup de conta Google Cloud, billing, SDK) | Conta Google Cloud + billing configurado; decisão de produto sobre quais campos armazenar | Médio — schema de `restaurants` pode precisar evoluir; fluxo de cadastro manual precisa continuar existindo como fallback | **P1** |
| 5 | Deep link de convite de grupo | Alto — resolve o funil de ativação mais frágil identificado nesta auditoria | Alto — reduz atrito no principal canal de aquisição (convite entre amigos) | Média — nunca implementado no projeto; requer configurar Android App Links e iOS Universal Links, mais o roteamento no GoRouter | Médio (dias a poucas semanas, inclui validação em ambas plataformas) | Domínio verificado para Universal Links (iOS) e assetlinks.json (Android) | Baixo-médio — é aditivo (a entrada manual de código continua funcionando em paralelo) | **P1** |
| 6 | Unificar recompensa Review/EventReview | Médio-alto — remove inconsistência que confunde usuários engajados em gamificação | Médio | Baixa — a parte de XP é a mesma implementação da Oportunidade #1; a unificação visual é opcional e maior | Curto (parte de XP); médio (se incluir unificação visual) | Depende da Oportunidade #1 estar decidida (mesmo trigger) | Baixo | **P1** |
| 7 | Toggle de notificações de Grupos na UI | Médio — usuário ganha controle que já deveria existir | Baixo-médio | Muito baixa — adicionar 1 `SwitchListTile` em tela já existente, categoria `'groups'` já suportada pelo banco desde `20260801130000` | Muito curto (horas) | Nenhuma | Muito baixo | **P2 (quick win)** |
| 9 | Fundir edição de perfil e avatar | Médio — remove uma tela desnecessária de uma tarefa mental única | Baixo | Baixa — mover a lógica de `ChangeAvatarPage` para dentro de `EditProfilePage` como avatar tocável | Curto | Nenhuma | Baixo | **P2** |
| 10 | Rodízio automático de escolha | Médio — resolve fricção social sutil (quem sempre escolhe/nunca escolhe) | Médio | Média — requer decisão de produto sobre a regra exata antes de qualquer implementação (sugestão vs. obrigação, como tratar ausências, etc.) | Médio | Decisão de produto explícita do usuário sobre a regra | Baixo — é aditivo/sugestivo, não bloqueia criação de rolê | **P2** |

**Leitura da matriz:** os 4 itens P0 concentram o maior impacto pelo menor custo de implementação — não por coincidência, mas porque todos aproveitam infraestrutura já pronta. Os 3 itens P1 têm impacto comparável, mas dependem de trabalho novo (integração externa paga, infraestrutura de deep link nunca construída) — maior tempo e maior superfície de risco. Os 3 itens P2 são polimento de baixo risco, adequados para preencher capacidade entre entregas maiores.

---

## 8. Matriz de Automação — "uma ação, muitas consequências"

Esta é a peça central da RC-03: para cada ação relevante do usuário, o que **já acontece automaticamente hoje** (verificado nos triggers/RPCs do banco, `rc03_supabase_inventory.md`) versus o que **poderia acontecer** (oportunidade). Sempre que a coluna "Hoje" estiver vazia ou incompleta, é exatamente aí que está a alavanca de automação.

### Ação: Confirmar presença em um rolê (`event_attendances` UPDATE → `confirmed`)
- **Dados produzidos:** `event_attendances.status='confirmed'`.
- **Hoje (verificado):** `recalculate_member_events_count()` atualiza `group_members.events_count`; `notify_event_attendance_response()` notifica **só o organizador**.
- **Funcionalidades que poderiam consumir:** Estatísticas do grupo (taxa de confirmação por membro); Ranking do Grupo (frequência como critério).
- **Telas que poderiam atualizar automaticamente:** `GroupStatsPage` (já consome `group_members.events_count`, então já atualiza — ponto positivo confirmado).
- **Rankings recalculáveis:** ranking de "mais presente" do grupo (dado já existe via `events_count`, só falta expor como critério de ordenação, hoje o ranking usa participação bruta).
- **Notificações geráveis:** nenhuma nova necessária além da já existente ao organizador — oportunidade menor aqui é notificar o **próprio usuário** com uma confirmação/lembrete automático próximo à data (não existe lembrete de "seu rolê é amanhã").
- **Badges liberáveis (oportunidade):** "presença perfeita" (nunca recusou em N rolês seguidos) — dado (`declined_count`) já existe na coluna, falta só a regra de badge.
- **Memórias atualizáveis:** "quem mais participou" — gap já confirmado como não implementado (Product Audit §2.12, UX Audit §2.8).
- **Estatísticas recalculáveis:** já cobertas (`events_count`/`declined_count`).
- **Feed:** nenhum vínculo hoje — confirmar presença não gera nenhuma atividade em `feed`/`comments`/`reviews` (o Feed hoje só é alimentado por `reviews` de restaurante via seguidores, não por atividade de grupo).

### Ação: Avaliar um rolê coletivamente (`event_reviews` INSERT)
- **Dados produzidos:** 5 notas + comentário.
- **Hoje (verificado):** `recalculate_event_rating()` → `events.average_rating`/`total_reviews`; `recalculate_member_review_stats()` → `group_members.reviews_count`/`average_score`. **Nenhuma notificação, nenhuma XP, nenhum badge** (confirmado, inventário Supabase §3a/§3b).
- **Funcionalidades que poderiam consumir:** motor de gamificação (Oportunidade #1); sistema de notificação (parcialmente já ocorre — falta notificar o **grupo** que uma nova avaliação foi feita, não só recalcular números silenciosamente).
- **Telas que poderiam atualizar automaticamente:** `GroupRankingPage`/`GroupStatsPage` já atualizam (via trigger); `GamificationProfilePage` **não** atualiza (sem XP, nada a mostrar).
- **Rankings recalculáveis:** ranking de usuários por XP (hoje não recalcula, porque não há XP concedido nesta ação).
- **Notificações geráveis:** "novo membro avaliou o rolê X" para o resto do grupo (reforça senso de atividade coletiva, incentivo social).
- **Badges liberáveis:** os mesmos badges de `reviews` (`critico`, `gourmet`) poderiam ter uma variante ou contar em conjunto — hoje contam **só** avaliações de restaurante individuais, não avaliações coletivas.
- **Memórias atualizáveis:** "melhor avaliação da temporada"/"resenha mais engajada" — nenhuma métrica desse tipo existe hoje.
- **Estatísticas recalculáveis:** já cobertas (`reviews_count`/`average_score`).
- **Feed:** **oportunidade grande e não explorada** — uma avaliação coletiva de rolê poderia virar automaticamente uma "publicação" no Feed do grupo/social, hoje o Feed só é alimentado por `reviews` (avaliação individual de restaurante via seguidores), não por `event_reviews`.

### Ação: Avaliar um restaurante individualmente (`reviews` INSERT)
- **Dados produzidos:** nota única + comentário + até 5 fotos.
- **Hoje (verificado):** `recalculate_restaurant_rating()`; `handle_gamification_new_review()` → 40XP/40pts + checagem de badges `first_review`/`critico`/`explorador`.
- **Funcionalidades que já consomem:** `RestaurantDetailPage` (nota média), `RankingsPage` (ranking geral), `GamificationProfilePage` (XP/nível/badges), `FeedPage` (se o autor é seguido por alguém).
- **Telas que já atualizam automaticamente:** confirmado — este é o fluxo com a cadeia de automação **mais completa** do produto hoje.
- **Rankings recalculáveis:** ranking geral de restaurantes (já ocorre).
- **Notificações geráveis:** já cobertas indiretamente (curtidas/comentários na review geram notificação; a review em si não notifica ninguém diretamente, o que é razoável).
- **Badges liberáveis:** já cobertos (`first_review`, `critico`, `explorador`).
- **Memórias atualizáveis:** nenhum vínculo com Memórias de grupo — se a avaliação foi de um restaurante visitado **em um rolê**, não há nenhuma ligação de dado entre a `review` individual e o `event` do grupo (são tabelas sem FK entre si) — oportunidade de correlação perdida.
- **Estatísticas recalculáveis:** já cobertas (nota do restaurante).
- **Feed:** já alimenta (via seguidores).

### Ação: Criar um rolê (`create_event()` RPC)
- **Dados produzidos:** linha em `events` + fan-out de `event_attendances` (organizador confirmado, resto pendente).
- **Hoje (verificado):** `notify_new_event()` notifica todo o grupo exceto o organizador. **`groups.last_activity_at` não é atualizada por nenhum trigger** (confirmado como débito técnico documentado na própria migration, inventário Supabase §1) — ou seja, mesmo essa coluna já existindo para o propósito de "grupo ativo recentemente", ela está desconectada da ação que deveria alimentá-la.
- **Funcionalidades que poderiam consumir:** ordenação de `GroupsListPage` por atividade recente (hoje presumivelmente por outro critério, já que `last_activity_at` não é mantida).
- **Telas que poderiam atualizar automaticamente:** `GroupsListPage` (ordenar por grupo mais ativo).
- **Rankings recalculáveis:** nenhum diretamente.
- **Notificações geráveis:** já cobertas (fan-out ao grupo).
- **Badges liberáveis (oportunidade):** "organizador" por volume de rolês criados — dado existiria via `events.organizer_id`, mas hoje não é contado em lugar nenhum como métrica de gamificação.
- **Memórias atualizáveis:** nenhuma diretamente.
- **Estatísticas recalculáveis:** nenhuma nova.
- **Feed:** nenhum vínculo.
- **Achado à parte (não é uma oportunidade de automação, é uma inconsistência):** `groups.last_activity_at` é um exemplo concreto de coluna criada com uma intenção de automação (rastrear atividade) que nunca foi conectada a nenhum evento que a atualizasse — vale corrigir mesmo que não vire uma feature nova.

### Ação: Criar um grupo (`create_group()` RPC)
- **Dados produzidos:** `groups` + `group_members` (owner).
- **Hoje (verificado):** nenhum trigger de notificação ou gamificação associado.
- **Oportunidade:** badge opcional "fundador"; nenhuma notificação necessária (não há mais ninguém no grupo ainda).
- **Feed:** nenhum vínculo, e provavelmente não deveria ter (criar um grupo vazio não é um "momento" social ainda).

### Ação: Entrar em um grupo (`join_group_by_invite_code()` RPC)
- **Dados produzidos:** nova linha em `group_members`.
- **Hoje (verificado):** `notify_group_member_joined()` notifica **só o dono do grupo**, não os demais membros (confirmado, inventário Supabase §3).
- **Oportunidade:** notificar todos os membros (não só o dono) de que alguém novo entrou — reforça sensação de grupo vivo; badge opcional para quem convidou (hoje não há nenhum rastreamento de "quem convidou quem" no schema — `group_members` não tem coluna `invited_by`, então essa atribuição não é possível sem alteração de schema, o que está fora de escopo desta fase analítica).
- **Feed:** oportunidade de "novo membro entrou no grupo X" como atividade leve, sempre com opção de ocultar (nunca obrigatório).

### Ação: Curtir uma avaliação (`review_likes` INSERT)
- **Dados produzidos:** linha em `review_likes`.
- **Hoje (verificado):** `recalculate_review_likes_count()`; `notify_new_like()`; `handle_gamification_new_like()` → 5XP ao autor da review + checagem de badge `influenciador`. **Esta é, junto com "avaliar restaurante", a cadeia de automação mais completa do produto** — bom padrão de referência para replicar em Grupos/Rolês (Oportunidade #1).
- **Oportunidade residual:** nenhuma lacuna relevante encontrada.

### Ação: Comentar em uma avaliação (`comments` INSERT)
- **Dados produzidos:** linha em `comments`.
- **Hoje (verificado):** `notify_new_comment()`; `handle_gamification_new_comment()` → 10XP ao autor da review.
- **Oportunidade residual:** nenhuma lacuna relevante encontrada.

### Ação: Favoritar um restaurante (`favorites` INSERT)
- **Dados produzidos:** linha em `favorites`.
- **Hoje (verificado):** **nenhum trigger** associado a esta tabela (confirmado, inventário Supabase §1) — é a ação mais "isolada" do produto.
- **Oportunidade:** ao criar um rolê, sugerir automaticamente restaurantes favoritados por membros do grupo (reuso de dado já existente, cruzando `favorites` com `group_members` — nenhuma tabela nova necessária); estatísticas do grupo poderiam mostrar "restaurantes favoritos do grupo" agregando os favoritos individuais dos membros.

### Ação: Adicionar foto a uma avaliação (`reviews.photos_count` via upload)
- **Dados produzidos:** arquivo no bucket `review-photos` + contagem em `reviews.photos_count`.
- **Hoje:** não foi possível confirmar, no inventário verificado, se `photos_count` é mantida por trigger de banco ou por lógica client-side — nenhum trigger correspondente aparece na lista exaustiva de 33 triggers do inventário Supabase (§3), o que sugere que o incremento acontece na aplicação (Flutter), não no banco. **Marcado como ponto a verificar diretamente antes de qualquer decisão de arquitetura**, não afirmado como fato.
- **Oportunidade:** se confirmado que é client-side, é candidato a virar um trigger (mais consistente, resistente a falha parcial do cliente) — mas isso é uma alteração de banco, fora do escopo analítico desta fase.

### Padrão consolidado da Matriz de Automação

O padrão mais forte que emerge, repetido em quase toda ação do cluster Grupos/Rolês/EventReviews: **os triggers de recálculo de estatística (rating, contagens) sempre existem, mas os triggers "sociais" (gamificação, notificação ampla, feed) sistematicamente não existem** para esse cluster — enquanto para o cluster antigo (Reviews/Comments/Likes) ambos os tipos de trigger existem lado a lado. Isso não é acidente distribuído aleatoriamente pelo schema — é o reflexo direto do pivô de produto (Product Audit §1): o cluster Grupos/Rolês foi construído depois, herdou os triggers "de dado" (porque eram necessários para o Ranking do Grupo funcionar) mas não herdou os triggers "sociais" que o cluster antigo já tinha desde o início.

---

## 9. Matriz de Eliminação

**Quais telas poderiam deixar de existir?**
- `ChangeAvatarPage` (`change_avatar_page.dart:21`) — poderia virar um avatar tocável dentro de `EditProfilePage`. Justificativa: é a mesma tarefa mental ("editar meu perfil"), hoje fragmentada em navegação sem motivo técnico (não há restrição de arquitetura que exija uma tela separada — é decisão de implementação, não de UX, confirmado em §3).
- `GroupStatsPage` como tela independente — poderia virar uma aba dentro de uma tela unificada "Meu Grupo" junto com `GroupRankingPage`. Justificativa: mesma fonte de dado (`group_members` desnormalizado + `events`), mesma pergunta do usuário ("como estamos indo"), hoje exigindo navegação e descoberta duplicadas (Oportunidade #3).

**Quais formulários poderiam desaparecer?**
- Os campos manuais de endereço/lat-long/categoria em `CreateRestaurantPage` (`:141-154`) — substituíveis por autocomplete do Google Places (Oportunidade #4). Justificativa: são exatamente os campos mais sujeitos a erro de digitação e mais fáceis de obter automaticamente de uma fonte confiável.
- O formulário de login pós-verificação de e-mail (§2.1) — se a sessão já foi criada no cadastro e só precisa ser confirmada, reautenticar do zero com e-mail/senha é redundante. Justificativa: o Supabase Auth já mantém sessão client-side; o formulário existe hoje só porque o retorno do fluxo de verificação não é automatizado (ver deep link de retorno, mesma classe de solução da Oportunidade #5).

**Quais uploads poderiam ser unificados?**
- **Achado novo desta seção:** existem hoje **3 implementações separadas** do mesmo padrão "selecionar imagem → validar tamanho/formato → enviar para bucket → atualizar registro": `ChangeAvatarPage._pickImage()/_upload()` (`:33`/`:61`, bucket `avatars`), `RestaurantDetailPage._changeCoverImage()` (`:63`, bucket `restaurants`), `ReviewDetailPage._addPhoto()` (`:57`, bucket `review-photos`). Justificativa: as 3 usam a mesma dependência (`image_picker`), os mesmos limites de tamanho conceituais (5-10MB, `storage inventory §5`), e a mesma forma de erro (formato/tamanho inválido) — é candidato natural a um único widget/controller de upload parametrizado por bucket, reduzindo 3 implementações a 1. (Nota: isso é uma observação de **reuso de padrão**, não uma sugestão de refatoração de arquitetura — a arquitetura Feature-First/Clean Architecture continua congelada; o reuso seria de um widget de UI comum, não de mudança de camadas.)

**Quais consultas poderiam ser reaproveitadas?**
- `EventRestaurantSearchController` (busca de restaurante dentro do fluxo de criar rolê) duplica a lógica de busca de `RestaurantsController` (busca da aba Restaurantes) — são dois controllers distintos fazendo essencialmente a mesma pergunta ("buscar restaurante por nome/cidade") com resultados potencialmente inconsistentes entre si (filtros diferentes, paginação diferente — `RestaurantsController` não tem `loadNextPage()`, `EventRestaurantSearchController` também não pagina). Justificativa: unificar reduziria a chance de comportamento divergente entre os dois pontos de busca de restaurante do app.
- A lógica de "restaurante mais visitado"/"campeão" em `EventsListController` (usada nos cards de Memórias) é o mesmo tipo de agregação que `GroupStatsPage` precisaria para "quem mais participou"/"quem mais escolheu" (gap confirmado, Product Audit §2.12) — a extensão dessas métricas deveria reaproveitar o mesmo padrão de query, não criar um novo.

**Quais cadastros poderiam ser automáticos?**
- Cadastro de restaurante (Google Places, já coberto).
- Entrada em grupo via convite (deep link, já coberto) — hoje é um "cadastro manual" de um código de 8 caracteres que poderia ser zero-toque.

**Quais passos poderiam ser eliminados?**
- Reautenticação manual pós-verificação de e-mail (§2.1).
- Navegação até `EventsListPage` antes de poder criar um rolê (§2.4) — um atalho direto de `GroupDetailPage` eliminaria uma tela intermediária de listagem para quem já sabe que quer criar.
- Abrir o menu overflow para achar Ranking/Estatísticas (§2.8) — vira parte da Oportunidade #3.

---

## 10. Matriz de Reutilização — por módulo

| Módulo | Produz (dados) | Consome (dados) | Reutilizável (dados) | Controllers/Providers existentes | Widgets/Componentes reaproveitáveis |
|---|---|---|---|---|---|
| `administration` | `audit_logs`, mudanças de `user_roles`/status de `restaurants`/moderação de `comments`/`reviews` | `user_roles`, `restaurants`, `reviews`, `comments` | Helpers RLS `is_admin()`/`can_moderate()` já reutilizáveis por qualquer feature futura que precise de checagem de papel | `AdminDashboardController`, `AdminRestaurantsController`, `AdminRolesController`, `AdminUsersController`, `AuditLogController`, `ModerationController`, `currentUserRoleProvider` | `AdminGuard` (`admin_guard.dart:11`) — padrão de guarda de rota pronto para qualquer tela administrativa futura |
| `authentication` | sessão, `auth.uid()`, eventos de auth | — | `currentUserIdProvider` é a base consumida por praticamente todos os outros 12 módulos — já é o exemplo máximo de reuso do app | `AuthController`, `authControllerProvider`, `currentUserIdProvider` | `listenForAuthErrors` (`auth_error_listener.dart:9`) — padrão de listener de erro reaproveitável |
| `event_reviews` | `event_reviews` (5 notas + comentário) | `events`, `event_attendances` (via `can_review_event()`) | O formulário de 5 critérios poderia virar um widget genérico `MultiCriteriaRatingForm`, hoje bespoke a `SubmitEventReviewPage` — reutilizável se qualquer avaliação com múltiplos critérios for adicionada no futuro | `EventReviewsController`, `SubmitEventReviewController` | Nenhum widget de critério múltiplo existe hoje no design system (`design_system/components/`) — oportunidade de extração |
| `events` | `events`, `event_attendances` | `groups` (membership), `restaurants` (busca) | Histórico de rolês do grupo (`events`) é a base de dado para sugestão automática de restaurante/data (Oportunidade #4/#10) | `CreateEventController`, `EventDetailController`, `EventRestaurantSearchController`, `EventsListController` | Nenhum widget específico — mas `EventRestaurantSearchController` duplica lógica de `RestaurantsController` (ver Matriz de Eliminação) |
| `favorites` | `favorites` | `restaurants` | Favoritos por membro poderiam alimentar sugestão de restaurante ao criar rolê (Matriz de Automação) | `FavoriteToggleController` (padrão otimista+rollback reutilizável para qualquer "curtir/salvar" futuro), `FavoritesController` | Padrão de toggle otimista é o melhor exemplo de "componente de interação" reaproveitável do app |
| `gamification` | `user_progress` (xp/points/level), `user_badges` | hoje só `reviews`/`comments`/`review_likes` — não `events`/`groups`/`event_reviews` | **O ativo mais reutilizável de todo o backend**: `award_gamification_points()`/`award_badge()` são genéricas, já testadas em produção, prontas para qualquer novo trigger (Oportunidade #1) | `GamificationProfileController`, `RankingUsersController` | Nenhum widget de UI a mais que os do design system (`AppBadge`, `ScoreBubble`) |
| `group_ranking` | nada (view derivada) | colunas desnormalizadas de `group_members`, `events` | O padrão de query "agregação por usuário dentro de um grupo" é reaproveitável para qualquer ranking novo dentro de grupo (ex.: ranking de XP por grupo, se a Oportunidade #1 for adiante) | `GroupRankingController` (`GroupStatsPage` não tem controller próprio — reaproveita `EventsListController` + `GroupRankingController`, já um bom exemplo de reuso) | `RankingCard` (design system) já reutilizado aqui e em `RankingUsersPage`/`RankingsPage` — 3 telas diferentes, mesmo componente |
| `groups` | `groups`, `group_members`, `invite_code` | — | Helpers RLS `is_group_member()`/`is_group_admin()`/`is_group_owner()` já reutilizados por `events`/`event_attendances`/`event_reviews` — padrão de reuso já comprovado, deveria se estender a qualquer feature nova escopada a grupo | `CreateGroupController`, `EditGroupController`, `GroupDetailController`, `GroupsListController`, `JoinGroupController` | `buildInviteShareMessage()` (`group_detail_controller.dart:33`) já pronta, subutilizada (Oportunidade §2.2) |
| `notifications` | `notifications` | recebe de **todos** os outros módulos (é o sink universal) | `create_notification()` é, junto com o motor de gamificação, o outro "motor genérico" do backend — já chamado por 6 gatilhos diferentes, pronto para mais (Oportunidade #2) | `NotificationPreferencesController`, `NotificationsController` | Nenhum widget de UI extra necessário — a lacuna é 100% de triggers de banco, não de front-end |
| `rankings` | nada (view derivada) | `restaurants.average_rating` | Delega inteiramente a `RestaurantRepository.listRanked()` — já é o melhor exemplo existente de "não duplicar lógica" no app inteiro | `RankingsController` | `RankingCard`, `RestaurantCard` (design system, reaproveitados) |
| `restaurants` | `restaurants`, capa (`restaurants` bucket) | — (consumiria Google Places se implementado) | `CreateRestaurantPage` já reaproveitada via `returnToCaller` em 2 fluxos (aba própria + inline em Criar Rolê) — **o melhor exemplo de reuso já existente no app**, referência de padrão a seguir | `RestaurantDetailController`, `RestaurantsController` | `RestaurantCard`, `ScoreBubble` (design system) |
| `reviews` | `reviews`, `review_likes`, fotos (`review-photos` bucket) | `restaurants` | Padrão de upload de foto (`addPhoto`, `maxReviewPhotos=5`) é candidato a consolidação com os outros 2 uploads do app (Matriz de Eliminação) | `ReviewDetailController`, `ReviewsController` | `ReviewSummaryTile` (`review_summary_tile.dart:9`) já reaproveitado entre `ReviewsListPage`/`PublicProfilePage` |
| `social` | `comments`, `comment_reports`, `followers` | `reviews` (comentários/feed), `profiles` | O formato "lista paginada com `loadForUser`+`loadNextPage`+`refresh`" se repete quase idêntico em `FeedController`, `FavoritesController`, `RankingsController`, `NotificationsController`, `CommentsController`, `FollowListController` — um padrão arquitetural já consistente (observação, não recomendação de refatoração — arquitetura congelada) | `CommentsController`, `FeedController`, `FollowController`, `FollowListController`, `UserReviewsController` | `EmptyState`/`ErrorState`/`LoadingIndicator` (design system) já usados de forma consistente nesse padrão de lista paginada |
| `users` | `profiles`, avatar (`avatars` bucket) | — | `UserProfileController.avatarDisplayUrl()` resolve path→URL assinada — verificar se essa resolução é centralizada ou reimplementada em cada tela que mostra avatar (comentários, membros de grupo, seguidores); **não confirmado no inventário, marcado como ponto a verificar antes de decidir se há duplicação real** | `UserProfileController`, `AccountDeletionController` | `UserAvatar`, `ProfileAvatar` (design system + `profile_avatar.dart:14`) |

**Objetivo cumprido:** esta matriz mostra que o app já tem 2 "motores genéricos" maduros e subutilizados (`award_gamification_points()`, `create_notification()`) e pelo menos 3 padrões de UI claramente reaproveitáveis (upload de imagem, lista paginada, toggle otimista) — a RC-03 deve **conectar e estender esses ativos**, não recriar equivalentes.

---

## 11. Matriz de Engajamento — por fluxo, sempre por incentivo, nunca por obrigatoriedade

| Fluxo | Retenção | Recorrência | Avaliações | Fotos | Criação de rolês | Participação | Descoberta de restaurantes |
|---|---|---|---|---|---|---|---|
| Primeiro acesso (§2.1) | Prévia opcional do "momento WOW" (ranking/memórias) durante onboarding, para ancorar expectativa | — | — | — | — | — | — |
| Criar grupo (§2.2) | Badge opcional "fundador" | Lembrete gentil e não-bloqueante para convidar, só se o grupo ficar vazio por dias | — | — | — | — | — |
| Entrar em grupo (§2.3) | Notificação de boas-vindas com dica (não obrigação) de criar o 1º rolê | — | — | — | — | — | — |
| Criar rolê (§2.4) | — | Sugestão gentil baseada em cadência do grupo ("faz um tempo que o grupo não se reúne") — nunca cobrança | — | — | XP (Oportunidade #1) + badge "organizador" por volume — sempre como conquista, nunca meta imposta | — | Sugestão de restaurantes favoritados pelo grupo ou ainda não visitados (Matriz de Automação) |
| Confirmar presença (§2.5) | — | — | — | — | — | Conquista opcional "presença consistente" (nunca streak punitivo/culpabilizante) | — |
| Avaliar rolê (§2.6) | Notificação de avaliação liberada (Oportunidade #2) traz o usuário de volta no momento certo | — | XP simétrico (Oportunidade #1/#6) + badge de avaliador consistente | Campo de foto na avaliação coletiva não existe hoje — oportunidade de adicionar como opcional, com pequeno incentivo de XP | — | — | — |
| Avaliar restaurante (§2.7) | — | — | Já incentivado (40XP + badges) | Badge opcional "fotógrafo" por volume de fotos anexadas — hoje não existe nenhum incentivo específico para a funcionalidade de foto já construída (`maxReviewPhotos=5`) | — | — | — |
| Ranking/Estatísticas/Memórias (§2.8) | Notificação opcional tipo "sua memória de X tempo atrás" para trazer o usuário de volta | Ciclo de retorno natural quando novas memórias se acumulam | — | — | — | — | Destacar "restaurantes ainda não visitados pelo grupo" dentro da própria tela de estatísticas (reuso de dado, Matriz de Automação) |
| Notificações/preferências (§2.10) | Cobertura completa de categorias (Oportunidade #7) evita que o usuário desligue notificações **todas de uma vez** por excesso de ruído em uma categoria só | — | — | — | — | — | — |
| Feed (§2.11) | Uma vez resolvido o ponto de entrada (Oportunidade #8), o Feed é o canal natural de retorno social ("o que meus amigos avaliaram") | Reforça hábito de abrir o app para ver atividade social | — | — | — | — | Canal orgânico de descoberta (ver o que outros avaliaram bem) |

**Princípio seguido em toda a matriz:** todo incentivo é **opcional e baseado em conquista** (badge, XP, notificação informativa) — nenhuma sugestão envolve bloquear uma ação, impor obrigatoriedade, ou usar mecânica de culpa/pressão (ex.: streaks punitivos). Isso é consistente com a personalidade de marca já documentada ("social, espontânea, divertida sem ser infantil", `identidade visual-borah/.../CLAUDE.md`, inventário de Design §2.2).

---

## 12. Roadmap de Evolução — três horizontes

### Curto prazo (Beta)
- **Objetivo:** fechar os loops de automação que já têm toda a infraestrutura pronta, e resolver a única incerteza estrutural (Feed) antes de investir em qualquer coisa nova.
- **Itens:** Oportunidade #1 (gamificação em Grupos/Rolês), #2 (notificação de avaliação liberada), #3 (unificar Ranking/Estatísticas/Memórias), #7 (toggle de notificações de grupo), #8 (verificar/resolver entrada do Feed), e a correção do achado à parte de `groups.last_activity_at` não mantida (Matriz de Automação §8).
- **Valor entregue:** o produto pós-pivô (Grupos/Rolês) passa a ter o mesmo nível de "vivo"/recompensador que o produto pré-pivô (Reviews individuais) já tem hoje — fecha a maior lacuna de percepção de qualidade do Beta.
- **Dependências:** nenhuma externa — tudo usa infraestrutura já existente.
- **Complexidade:** baixa a média em todos os itens.

### Médio prazo
- **Objetivo:** reduzir fricção estrutural nos dois funis mais frágeis identificados (ativação por convite e cadastro de restaurante), e consolidar padrões de UI duplicados.
- **Itens:** Oportunidade #4 (Google Places), #5 (deep link de convite), #6 (unificação de recompensa Review/EventReview), #9 (fundir edição de perfil/avatar), consolidação do padrão de upload (Matriz de Eliminação), consolidação de `EventRestaurantSearchController`/`RestaurantsController`.
- **Valor entregue:** funil de ativação de novos usuários mais curto (deep link); qualidade de dado de restaurante mais alta (Places); base de código mais consistente para a equipe evoluir depois.
- **Dependências:** conta Google Cloud + billing (Places); configuração de App Links/Universal Links (deep link) — ambas exigem trabalho de infraestrutura fora do código Flutter/Supabase puro.
- **Complexidade:** média a média-alta.

### Longo prazo
- **Objetivo:** completar as funcionalidades de "núcleo" do ET-05/ET-13 que nunca foram implementadas e que dependem de decisão de produto explícita, mais a evolução do Feed/notificações para um canal de descoberta mais rico.
- **Itens:** Oportunidade #10 (rodízio automático de escolha), Temporadas de grupo (`group_seasons`, nunca implementado), desafios diário/semanal/sazonal (ET-13), badges com raridade além dos 5 fixos atuais, push notifications reais via FCM (hoje só in-app, decisão de escopo já registrada como "fora do Beta fechado"), Feed alimentado também por `event_reviews` (não só `reviews` individuais, ver Matriz de Automação).
- **Valor entregue:** fecha o gap entre a "visão de núcleo" original (ET-05/ET-13) e o produto pós-pivô, com decisões de produto conscientes (não mais lacunas silenciosas) para cada item.
- **Dependências:** decisões explícitas do usuário sobre regras de negócio específicas (ex.: como funciona o rodízio, o que conta como temporada) — nenhum desses itens deve ser implementado a partir de suposição, conforme a regra desta auditoria.
- **Complexidade:** média a alta, variando por item — cada um deve ser desmembrado em sua própria decisão de escopo antes de virar tarefa de implementação.

---

**Aguardando revisão do usuário antes de prosseguir para `RC03_UI_AUDIT.md` (FASE 3).**
