# BORAH — Beta Playbook (Auditoria de Produto)

**Data:** 2026-08-01
**Papel:** Product/UX Lead.
**Método:** *cognitive walkthrough* — cada fluxo abaixo foi traçado direto no
código (`app_router.dart`, páginas de `presentation/`, controllers) para
contar telas/toques reais, não impressão. Isto é uma auditoria preditiva,
não dado de uso real — a seção 9 define exatamente como substituí-la por
dado real assim que o Beta tiver os primeiros usuários.

Este documento responde às perguntas de produto que faltavam no
`BORAH_RELEASE_CANDIDATE_REPORT.md`: aquele documento diz que o código
está certo; este diz se uma pessoa real, sem explicação, entende o que
fazer com ele.

---

## 1. O usuário entende o app sem explicação?

**Parcialmente — depende de qual dos dois casos ele é.**

- **Quem recebe um código de convite de um amigo** entende bem: abre o
  app, vê "Grupos" (aba inicial), toca "Entrar com código" (que já
  aparece *antes* de "Criar grupo" no estado vazio e na topbar — decisão
  de produto já tomada e correta, ver `groups_list_page.dart:67-73`),
  digita o código, entra. 2 toques, sem ambiguidade.
- **Quem baixa o app sem nenhum convite** não entende o que fazer. A tela
  inicial vazia oferece "Entrar com código" (que ele não tem) ou "Criar
  grupo" (um grupo sem ninguém dentro). Não existe nenhum conteúdo de
  exemplo, nenhuma restaurante sugerido, nenhum texto explicando *por que*
  criar um grupo importa antes de ele já ter feito isso. Esse segundo
  usuário só "entende" o app depois que já convidou alguém e um rolê
  aconteceu — ou seja, depois do próprio onboarding, não durante.

**Implicação para o Beta:** os 20 usuários devem ser organizados em
grupos de amigos reais *antes* do primeiro uso (ou instruídos a convidar
alguém no primeiro dia) — o app sozinho não cria esse contexto.

---

## 2. Onde o usuário pode desistir

Por ordem de risco, do mais grave ao mais leve:

### 2.1 [Alto] Restaurante não cadastrado = beco sem saída dentro do fluxo de criar rolê

`create_event_page.dart`, Etapa 1: se a busca não encontra o restaurante,
a tela mostra só `Text('Nenhum restaurante encontrado.')` —
`EventRestaurantSearchEmpty()`, sem nenhuma ação. Cadastrar um restaurante
é uma tela própria (`RestaurantsSearchPage`, aba "Restaurantes"), sem
nenhum link entre as duas. Um usuário que queira marcar um rolê num lugar
que ainda não está no catálogo precisa: sair da criação do rolê (perdendo
o grupo/contexto já selecionado), ir para a aba Restaurantes, cadastrar o
restaurante, voltar para Grupos, entrar no grupo de novo, abrir "Rolês",
"Criar rolê" de novo, buscar de novo. É o ponto de maior risco de
desistência do app hoje — e provavelmente o mais comum na prática: no
Beta, com poucos restaurantes cadastrados, a maioria dos primeiros rolês
vai bater nesse buraco.

### 2.2 [Alto] Depois de criar um grupo, o convite não é o próximo passo natural

`groups_list_page.dart._createGroup`: ao voltar de `CreateGroupPage`, a
tela só recarrega a *lista* — não abre o grupo recém-criado.
`GroupDetailPage` (onde está o código de convite e o botão
"Compartilhar") só existe se o usuário tocar de novo no grupo que ele
mesmo acabou de criar. É um passo extra, não óbvio, exatamente no momento
em que a ação certa (convidar alguém) é a mais importante do produto — um
grupo sem convite nunca gera um rolê, uma avaliação ou um dado de retenção.

### 2.3 [Médio] Verificação de e-mail tira o usuário do app no meio do cadastro

Cadastro → e-mail de verificação → o usuário precisa abrir o app de
e-mail, achar a mensagem, voltar. Esse é o ponto clássico de abandono em
qualquer app (sair do contexto quase sempre reduz conclusão) — não é um
bug do BORAH, é inerente ao mecanismo, mas é onde qualquer funil de
ativação normalmente perde a maior fração de gente. Vale medir
separadamente no Beta (ver §9).

### 2.4 [Médio] Avaliar um rolê depende do usuário lembrar sozinho

Não existe nenhum empurrão de volta ao app depois que um rolê acontece —
a notificação "avaliação liberada" está listada como não implementada
(`docs/.../BORAH_RELEASE_CANDIDATE_REPORT.md` §3, item 11). Hoje, avaliar
exige que o usuário, por conta própria, lembre de reabrir um rolê
passado. Isso é o dado mais importante para o produto (alimenta ranking,
estatísticas e Memórias) e o menos garantido de ser coletado.

---

## 3. Contagem real de toques por fluxo (a partir da Home)

| Fluxo | Toques | Telas | Observação |
|---|---|---|---|
| Entrar em grupo por código | **2** | 1 (Entrar com código) | Mínimo possível — bem feito. |
| Criar grupo | **2** | 1 (Criar grupo) | Mínimo possível — bem feito. |
| Compartilhar convite de um grupo já existente | **2** | 1 (Detalhe do grupo) | +1 toque extra se acabou de criar o grupo (§2.2). |
| **Criar um rolê** | **~7** (+ 2 interações de picker nativo) | 4 (Detalhe do Grupo → Rolês → Criar, Etapa 1 → Etapa 2) | **O fluxo mais profundo do app.** Único fluxo com wizard de 2 etapas. |
| Confirmar presença — via notificação | **1** | 1 (Detalhe do Rolê, deep link) | Melhor caminho possível — a notificação já resolve toda a navegação. |
| Confirmar presença — navegando manualmente | **4** | 3 (Grupo → Rolês → Detalhe do Rolê) | Sem notificação, é o 2º fluxo mais profundo. |
| Avaliar um rolê | **4** (+ preencher 5 campos de nota) | 3 (mesmo caminho da confirmação manual) | Nenhum caminho via notificação hoje (§2.4). |

**Leitura:** os dois fluxos mais baratos (entrar/criar grupo) são
exatamente os de onboarding — ótimo. O fluxo mais caro é "criar rolê", que
é também o de maior valor para o produto (é o que gera dado real).
Notificações já comprimem "confirmar presença" de 4 para 1 toque quando
funcionam — o mesmo tratamento falta em "avaliar".

---

## 4. Carga cognitiva — telas específicas

- **`SubmitEventReviewPage` (Avaliar rolê):** 5 campos de nota numérica
  em texto livre (Comida, Atendimento, Ambiente, Custo-benefício, Nota
  geral) + comentário — nenhuma tela do projeto usa um seletor de
  estrelas (decisão documentada em `submit_event_review_page.dart:16-18`).
  Digitar "4.5" em 5 caixas de texto separadas, no celular, é
  significativamente mais trabalho manual/cognitivo do que tocar em
  estrelas — e é a única tela do app que pede 5 números de uma vez. Maior
  risco de review abandonada ou preenchida com valores aleatórios só para
  passar.
- **`CreateEventPage`:** mitigado pelo próprio desenho — mostra só o
  campo de busca OU o card do restaurante já selecionado (nunca os dois),
  e separa data/hora numa segunda etapa. A carga é real (é o fluxo mais
  longo, §3), mas está bem distribuída, não empilhada numa tela só.
- **`GroupDetailPage`:** mistura nome/descrição/código/compartilhar/lista
  de membros com menu de administração por membro. Densa para
  admin/owner; para membro comum, a maior parte dessas ações nem aparece
  (`canManage`/`canChangeRole`/`canRemove` condicionais) — risco baixo na
  prática porque se autolimita ao papel de quem está vendo.

---

## 5. Qual tela deve aparecer primeiro

Já decidido e implementado corretamente nesta rodada de QA: a aba
"Grupos" é a Home (`home_shell_page.dart:14-21`, substituiu "Feed"). Isso
é a escolha certa — a identidade do BORAH é "o ranking dos seus rolês com
seu grupo de amigos", não um feed de reviews individuais. Nada a mudar
aqui.

---

## 6. Onde existe excesso de informação

Nenhuma tela do app hoje tem "excesso de informação" no sentido clássico
(paredes de texto, formulários com dezenas de campos). O risco real do
BORAH é o oposto do que normalmente se audita: é **profundidade de
navegação** (criar rolê, §3) e **ausência de orientação no vazio**
(usuário sem convite, §1) — não sobrecarga visual numa tela só.

---

## 7. Qual é o "momento WOW"

O maior payoff do produto — Ranking do Grupo, Estatísticas, "Campeão"/
"Mais visitado" em Memórias — só existe depois que o grupo já acumulou
rolês *realizados* e avaliações. Um grupo novo, no primeiro dia, vê essas
telas essencialmente vazias. Ou seja: **o momento WOW do BORAH é
estruturalmente tardio** — não acontece no onboarding, acontece depois de
uma janela de uso real (algumas semanas, na prática).

**Implicação direta para o Beta:** com só 20 usuários e um teste curto,
existe risco real de nenhum grupo acumular rolê suficiente para o time
sentir o "momento WOW" verdadeiro antes do Beta terminar. Duas saídas,
não mutuamente exclusivas:
1. Recrutar grupos que já têm o hábito de sair juntos com frequência
   (encontros toda semana, não mensal) para comprimir o tempo até o
   primeiro Ranking/Memórias com dado de verdade.
2. Considerar, só para o Beta, popular 1-2 grupos de demonstração com
   histórico fabricado (dados de teste, claramente marcados como tal) só
   para mostrar aos 20 usuários como a tela *fica* depois de uso real —
   sem isso, boa parte deles pode nunca ver a melhor parte do produto.

---

## 8. Onde o onboarding falha (resumo)

Por ordem de impacto: (1) restaurante ausente do catálogo trava a criação
do primeiro rolê sem nenhum caminho alternativo (§2.1); (2) convite não é
o próximo passo natural depois de criar um grupo (§2.2); (3) verificação
de e-mail tira o usuário do contexto do app (§2.3); (4) usuário sem
convite nem contexto social não tem nenhum gancho de "o que fazer agora"
(§1); (5) o produto entrega seu melhor momento tarde demais para um teste
curto (§7).

---

## 9. Como medir sucesso do Beta

A lista de métricas do Sprint 4 (grupos criados, convites enviados/
aceitos, rolês criados/realizados, avaliações, usuários que voltaram,
D1/D7/D30) já é a correta — o que falta é organizá-la como **funil**, na
mesma ordem das telas reais (§3), para que uma queda em qualquer etapa
apareça já apontando para a tela específica responsável:

```
Cadastro
  → E-mail verificado                         (§2.3 — maior perda esperada)
    → Primeiro grupo (criado OU via código)
      → Primeiro convite compartilhado         (§2.2 — medir separado de "grupo criado")
        → Primeiro rolê criado                 (§2.1/§3 — fluxo mais longo do app)
          → Rolê com ≥2 presenças confirmadas
            → Primeiro rolê já realizado (data passada)
              → Primeira avaliação enviada     (§2.4 — sem notificação hoje, maior risco de nunca acontecer)
                → Retorno em D1 / D7 / D30
```

Cada seta é um evento de analytics que já deveria ser instrumentado antes
do primeiro usuário real entrar (`AppAnalytics`/PostHog, já disponível no
código, `core/analytics/`) — sem isso, o Sprint 4 não tem como distinguir
"ninguém usou" de "alguém tentou e travou em tal tela".

**Critério de sucesso mínimo do Beta**, considerando §7: pelo menos 1
grupo chegando até "primeira avaliação enviada" antes do fim do teste — se
nenhum grupo chegar lá, o problema não é o produto, é a duração do Beta
frente ao tempo real que um grupo de amigos leva para se encontrar de
novo.

---

## 10. Veredito

O BORAH está tecnicamente pronto (ver `BORAH_RELEASE_CANDIDATE_REPORT.md`)
e o produto, na maior parte, está bem desenhado — os dois fluxos de
onboarding (entrar/criar grupo) são exemplarmente curtos, e a decisão de
Home já está certa. O que falta não é código: é fechar os dois becos sem
saída concretos (§2.1, §2.2) antes do Beta, e entrar no teste sabendo, de
antemão, que o "momento WOW" real (§7) pode não caber na janela de tempo
disponível — o que muda o que "sucesso do Beta" deveria significar, não
o que precisa ser construído.
