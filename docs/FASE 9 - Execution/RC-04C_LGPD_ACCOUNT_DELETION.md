# RC-04C — LGPD & Account Deletion

**Data:** 2026-07-25
**Branch:** `feature/rc-04c-lgpd-account-deletion`
**Status:** Implementado — infraestrutura completa e testada; conectada à tela de Configurações (único ponto de UI desta rodada)
**Escopo:** exclusivamente o ciclo completo de exclusão da própria conta (RN-003/ET-04; PB-04 §7/§10). Política de Privacidade, Termos de Uso, Publicação e Beta são itens separados do backlog (RC-04D/E) e não foram tocados nesta rodada.

---

## 1. Objetivo

Dar ao usuário do BORAH um meio real de exercer o direito de exclusão de conta (LGPD), com um fluxo seguro (confirmação explícita + reautenticação), sem deixar dados órfãos, sem quebrar a integridade referencial do banco, e sem apagar conteúdo de *outros* usuários no processo.

---

## 2. Bloqueador técnico + decisões de modelagem (resolvidos antes de implementar)

Esta rodada foi interrompida duas vezes antes de qualquer código ser escrito, conforme instruído ("caso exista qualquer dúvida de modelagem, interromper e apresentar análise").

### 2.1 Não existe exclusão de `auth.users` pelo cliente

`GoTrueClient` (SDK usado pelo app, `gotrue-2.26.0`) não expõe nenhum método de autoexclusão — `deleteUser()` só existe em `GoTrueAdminApi` (`auth.admin`), que exige a `SERVICE_ROLE_KEY`, nunca presente no app mobile (RC-04A). Sem Edge Functions (infraestrutura que este projeto não tem — DV-08), a única forma de um usuário apagar a própria linha de `auth.users` é uma função Postgres `SECURITY DEFINER`, travada em `auth.uid()`, exposta via RPC — padrão documentado pela própria comunidade Supabase para este exato cenário.

### 2.2 Conflito de integridade referencial

Auditoria de todas as referências a `auth.users` nas 16 migrations anteriores encontrou 5 relações que **bloqueiam** a exclusão de qualquer usuário que já usou o app de verdade:

| Tabela | Comportamento |
|---|---|
| `reviews.user_id` | `on delete restrict` |
| `comments.user_id` | `on delete restrict` |
| `comment_reports.reported_by` | `on delete restrict` |
| `audit_logs.actor_id` | `on delete restrict` (tabela também imutável — nem super_admin altera/apaga, RC-04A) |
| `restaurants.created_by` | sem cascata (equivale a bloquear) |

As demais 10 relações (`profiles`, `favorites`, `followers`, `review_likes`, `notifications`, `notification_preferences`, `user_progress`, `user_badges`, `user_roles`, `feedback`) são `on delete cascade` — removidas automaticamente, sem conflito.

### 2.3 Decisões aprovadas explicitamente pelo usuário

1. **Mecanismo**: função `SECURITY DEFINER` `public.delete_own_account()`, via RPC, travada em `auth.uid()` — nunca aceita um id como parâmetro.
2. **Conteúdo do usuário** (avaliações, comentários, denúncias, restaurantes criados): **reatribuído** a uma conta de sistema fixa "Usuário removido" em vez de apagado — preserva o conteúdo que outros usuários já viram/curtiram/comentaram; só a autoria é anonimizada.
3. **Fotos de avaliação** (`review-photos`): mantidas, associadas à avaliação anonimizada — não são, por si só, dado pessoal identificável uma vez que a autoria já foi removida.

### 2.4 Achado técnico adicional durante o desenho (não uma nova decisão de negócio, consequência necessária da 2.3)

Reatribuir em massa para uma única conta violaria, eventualmente, duas constraints `UNIQUE` já existentes:
- `reviews_user_restaurant_unique (user_id, restaurant_id)` — um segundo usuário excluído que avaliou o mesmo restaurante que um usuário anteriormente excluído colidiria.
- `comment_reports_unique (comment_id, reported_by)` — mesmo problema para denúncias do mesmo comentário.

Resolvido substituindo as duas constraints por **índices únicos parciais** (`where user_id/reported_by <> '<id da conta placeholder>'`) — a regra "um usuário só avalia/denuncia uma vez o mesmo alvo" nunca fez sentido para uma conta que não representa uma pessoa real. Registrado com destaque no relatório final para revisão, mas não é uma decisão de negócio independente — é uma implicação mecânica direta da decisão 2.3 já aprovada.

---

## 3. Arquitetura

Camadas exatamente como especificado nesta rodada (Presentation → Application → Repository → Supabase — mais simples que o par Service+Repository de `core/`, seguindo o padrão já usado por `AuthController`/`UserProfileController`, que também não têm uma camada de Service própria):

```
lib/features/users/
├── domain/account_deletion_repository.dart       # interface + AccountDeletionRepositoryException
├── data/account_deletion_remote_datasource.dart  # única classe que chama a RPC
├── data/account_deletion_repository_impl.dart    # traduz PostgrestException
├── application/account_deletion_controller.dart  # orquestra reautenticação + Storage + RPC + logout
├── presentation/states/account_deletion_status.dart
└── presentation/widgets/account_deletion_dialog.dart
```

```
SettingsPage ("Excluir conta")
    ↓
AccountDeletionDialog                 ← confirmação explícita → campo de senha
    ↓ chama
AccountDeletionController.deleteAccount(email, password, avatarPath)
    ↓ 1. reautentica (AuthRepository.signIn, direto - sem side effects de login real)
    ↓ 2. apaga o avatar (AppStorage.delete, best-effort)
    ↓ 3. chama a RPC (AccountDeletionRepository.deleteOwnAccount)
    ↓ 4. encerra a sessão local (AuthController.signOut, best-effort)
AccountDeletionRepository (interface)
    ↓ implementado por
AccountDeletionRepositoryImpl → AccountDeletionRemoteDatasource
    ↓ chama
supabase.rpc('delete_own_account')
    ↓ executa no Postgres (SECURITY DEFINER)
public.delete_own_account()
```

Nenhuma tela chama o Supabase diretamente — `AccountDeletionController` é a única classe que conhece `AuthRepository`/`AppStorage`/`AccountDeletionRepository` simultaneamente.

---

## 4. Fluxo completo

1. **Solicitação**: usuário toca em "Excluir conta" (Configurações). `SettingsPage` busca o `avatarUrl` atual via `UserProfileRepository.getProfile` (consulta avulsa, falha não bloqueia o fluxo) e abre `AccountDeletionDialog`.
2. **Confirmação explícita**: aviso ("Esta ação é permanente. Todos os seus dados serão removidos. Esta ação não poderá ser desfeita.") com "Cancelar"/"Continuar".
3. **Reautenticação**: campo de senha. Chama `AuthRepository.signIn(email, password)` diretamente (não `AuthController.signIn`, para não disparar os efeitos colaterais de um login real — `AppAnalytics.identify`/`trackLoginSuccess`). Falha → erro inline, permite nova tentativa sem reiniciar o fluxo.
4. **Execução**: `AppStorage.delete` (avatar, best-effort) → `AccountDeletionRepository.deleteOwnAccount()` (RPC — se falhar, erro inline, permite nova tentativa, nada foi apagado).
5. **Logout**: `AuthController.signOut()` (best-effort — a conta já foi excluída no servidor; uma falha ao encerrar a sessão local não deve impedir a confirmação de sucesso).
6. **Retorno ao Login**: o diálogo fecha, mostra um snackbar de confirmação; o `redirect` do GoRouter já leva ao `/login` assim que `AuthStatus` vira `Unauthenticated` (mesmo mecanismo reativo já usado pelo logout comum, RC-02).

---

## 5. Dados — o que é removido, anonimizado ou preservado

| Tabela | Tratamento |
|---|---|
| `profiles`, `favorites`, `followers`, `review_likes`, `notifications`, `notification_preferences`, `user_progress`, `user_badges`, `user_roles`, `feedback` | **Removidos** (cascata automática ao apagar `auth.users`) |
| `reviews`, `comments`, `comment_reports` (como autor/denunciante) | **Anonimizados** — `user_id`/`reported_by` reatribuído à conta "Usuário removido"; nota, texto e restaurante permanecem visíveis |
| `restaurants` (criados pelo usuário) | **Anonimizado** — `created_by` reatribuído; o restaurante continua existindo para quem já o avaliou; só passa a ser editável apenas por administração/moderação (`can_moderate()`), não mais pelo criador original |
| `audit_logs` (como ator de uma ação administrativa) | **Anonimizado** — `actor_id` reatribuído; o registro em si nunca é apagado (imutabilidade, RC-04A) |
| Avatar (`avatars`) | **Removido** do Storage |
| Fotos de avaliação (`review-photos`) | **Preservadas** — decisão explícita (§2.3) |
| `email`/senha (`auth.users`) | **Removidos** (a linha inteira é apagada) |

Nenhum dado de **outro** usuário é tocado — curtidas, comentários e avaliações de terceiros permanecem exatamente como estavam.

---

## 6. Auditoria de impactos

- **Dados órfãos**: nenhum esperado nas relações com FK (todas resolvidas por cascata ou reatribuição). Exceção conhecida, não corrigida (ver §8): `payload` jsonb de notificações de *outros* usuários (ex.: "Alguém começou a seguir você") pode conter o id do usuário excluído — não é uma FK, é um campo solto; se o destinatário tentar abrir o perfil a partir dessa notificação, encontra um perfil inexistente e falha graciosamente (mesmo comportamento de um perfil nunca existente).
- **Referências cruzadas**: `restaurants` → `reviews` → `comments` → `comment_reports` formam uma cadeia de `restrict`. A decisão de reatribuir (não apagar) em cada nível evita qualquer necessidade de cascatear a cadeia inteira.
- **Violação de integridade**: nenhuma esperada — as duas constraints `UNIQUE` em risco (reviews, comment_reports) foram corrigidas para índices parciais (§2.4) antes da função de exclusão ser criada.
- **Gamificação**: `user_progress`/`user_badges` do usuário excluído somem (cascata) — correto, a conquista era pessoal. Badges "influenciador"/"crítico" de **outros** usuários, calculados a partir de curtidas/avaliações, não são recalculados retroativamente (mesmo comportamento já documentado para exclusões/soft-deletes no DV-10 — "sem reversão de XP/badges em exclusões").
- **Rankings**: o usuário excluído desaparece do "Ranking de Usuários" (a query já filtra por `user_progress` existente). Nenhuma ação adicional necessária.
- **Notificações**: notificações do usuário excluído somem (cascata). Notificações de *outros* usuários que mencionam o usuário excluído (ex.: "Novo seguidor") permanecem, com o `payload` apontando para um id que não resolve mais (ver limitação acima).

Nenhum problema arquitetural foi encontrado durante a auditoria que exigisse nova interrupção além das duas já registradas em §2.

---

## 7. Segurança

- `auth.uid()` é resolvido pelo Postgres a partir do JWT da sessão — nunca um parâmetro da função, então nenhum usuário pode manipular a chamada para excluir a conta de outra pessoa.
- Nenhuma operação administrativa é afetada: `is_admin`/`has_admin_role`/`can_moderate` continuam consultando `user_roles` normalmente.
- `EXECUTE` na função é revogado de `PUBLIC` e concedido explicitamente só a `authenticated` (Postgres concede `EXECUTE` a `PUBLIC` por padrão em toda função nova — revogação explícita, mesma disciplina de GRANT já aplicada a toda tabela do projeto).
- RLS continua protegendo todos os recursos durante e depois da exclusão — a função só bypassa RLS para a própria reatribuição/exclusão (`SECURITY DEFINER`), nunca para nenhuma outra operação.

---

## 8. Limitações e riscos

- **`payload` jsonb de notificações de terceiros** pode referenciar um usuário já excluído (ver §6) — resolve-se graciosamente no cliente (perfil não encontrado), não foi tratado com uma migração de limpeza retroativa (reescreveria dados de *outros* usuários, um risco pior que o problema em si).
- **Conta placeholder "Usuário removido"**: nenhuma tela de administração foi ajustada para tratá-la de forma especial (ex.: escondê-la de listagens de usuários/rankings) — fora do escopo desta rodada, que é exclusivamente o ciclo de exclusão, não a experiência administrativa resultante.
- **Migrations de `auth.users`/constraints não executadas contra uma instância real** — mesma limitação de toda migration deste projeto (AR-06/EX-01B). A criação da conta placeholder e a função `delete_own_account()` foram escritas e revisadas estaticamente.
- **Reautenticação implementada como confirmação de senha** (chamando `signIn` novamente), não o mecanismo `reauthenticate()` nativo do GoTrue (que existe para o fluxo de `updateUser`, não para RPCs arbitrárias) — decisão de reaproveitar a capacidade já existente (`AuthRepository.signIn`) em vez de introduzir um segundo mecanismo de confirmação.
- **Suíte pgTAP** para `delete_own_account()`/reatribuição não foi criada nesta rodada (não solicitada explicitamente no escopo desta RC, diferente da RC-04A/B) — fica registrada como melhoria futura caso o Docker esteja disponível numa rodada posterior.

---

## 9. Testes

| Arquivo | Cobertura |
|---|---|
| `test/unit/users/account_deletion_repository_test.dart` | Delegação ao datasource; tradução de `PostgrestException` |
| `test/unit/users/account_deletion_controller_test.dart` | Reautenticação (sucesso/falha tipada/falha genérica); exclusão com/sem avatar; falha no Storage não impede a exclusão (best-effort); falha na exclusão (tipada/genérica) nunca chama signOut; falha no signOut não impede o sucesso (best-effort); `reset()` |
| `test/widget/users/account_deletion_dialog_test.dart` | Aviso inicial; cancelar em cada estágio; avançar para o campo de senha; senha vazia não dispara nada; senha incorreta mostra erro e permite nova tentativa; exclusão bem-sucedida (carregando → fecha o diálogo → snackbar); falha na exclusão mostra erro e permite nova tentativa |
| `test/widget/users/settings_page_test.dart` (grupo novo) | Tocar em "Excluir conta" abre o diálogo — inclui correção de uma corrida de inicialização real encontrada no processo (ver nota abaixo) |

**Nota de teste**: a primeira versão do teste de integração em `settings_page_test.dart` falhava porque `authControllerProvider` é lido pela primeira vez dentro do próprio `onTap` — no mesmo instante síncrono em que seu valor ainda seria `AuthInitial` (o stream de autenticação só entrega seu valor num microtask seguinte à inscrição do listener). Corrigido aquecendo o provider explicitamente (`container.read(authControllerProvider)`) antes de qualquer interação do teste.

Suíte completa do projeto (`flutter test`): **479/479**, zero regressão (baseline anterior: 459/459 + 20 novos testes desta rodada).

---

## 10. Decisões arquiteturais registradas nesta rodada

1. **Reatribuição em vez de exclusão em cascata** para conteúdo restrito por FK (§2.3) — aprovado pelo usuário após análise das 5 relações bloqueantes.
2. **Índices únicos parciais** substituindo as constraints `reviews_user_restaurant_unique`/`comment_reports_unique` (§2.4) — consequência mecânica necessária da decisão 1, não uma decisão de negócio nova.
3. **Fotos de avaliação preservadas**, avatar removido (§2.3) — tratamento diferenciado por tipo de mídia, aprovado explicitamente.
4. **Reautenticação via `AuthRepository.signIn` direto**, não `AuthController.signIn` — evita efeitos colaterais de analytics de um "login" que não é um login de verdade.
5. **`payload` de notificações de terceiros não é limpo retroativamente** — o custo de reescrever dados de outros usuários supera o benefício de um campo que já falha graciosamente.
