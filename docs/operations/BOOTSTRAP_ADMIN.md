# Bootstrap do Primeiro Super Admin

**Ambiente:** Development (`borah-development`) — repetir o mesmo processo, isoladamente, quando Staging e Production existirem.

---

## Por que esse processo é manual

A política de INSERT de `public.user_roles` (migration `20260719160000_create_user_roles.sql`) exige que quem concede um papel administrativo **já seja `super_admin`**:

```sql
create policy "user_roles_insert_super_admin"
  on public.user_roles for insert
  to authenticated
  with check (public.has_admin_role(auth.uid(), 'super_admin'));
```

Isso é intencional — impede que qualquer usuário autenticado se autopromova a administrador. A consequência é que **não existe caminho pela aplicação** para criar o primeiro `super_admin`: a própria política bloquearia a tentativa. Ele precisa ser inserido manualmente, uma única vez, por alguém com acesso privilegiado ao banco (fora do RLS).

---

## Correção histórica — recursão em `is_admin()`/`has_admin_role()`/`can_moderate()`

A Validação Funcional do Backend (2026-07-20) encontrou, com evidência empírica (`stack depth limit exceeded`), que essas três funções entravam em recursão infinita assim que o usuário consultado passava a ter uma linha em `user_roles` — o próprio super_admin criado por este processo não conseguia usar seus privilégios através de nenhuma política dependente delas (`user_roles`, `restaurants`, `reviews`, `comments`, `comment_reports`, `audit_logs`).

**Causa:** as três funções não eram `SECURITY DEFINER`, então a consulta interna delas a `user_roles` ficava sujeita à própria RLS da tabela — que exige `is_admin()` para ser lida, inclusive a própria linha do usuário.

**Corrigido** na branch `feature/backend-fixes-phase1`, migration `20260720130030_fix_rbac_functions_security_definer.sql`: as três funções agora são

```sql
security definer
set search_path = public, pg_temp
```

— mesmo padrão usado em `handle_new_user()` e nas demais funções `SECURITY DEFINER` do projeto. Confirmado por reteste completo (mesmo cenário: super_admin real verificando a própria permissão) sem regressão em nenhuma policy existente.

**Estado atual:** o bootstrap manual descrito abaixo continua sendo o único passo necessário para *inicializar* o sistema (a política de INSERT de `user_roles` sempre vai exigir um `super_admin` prévio para conceder o primeiro papel — isso é uma decisão de segurança permanente, não o bug). Uma vez que essa única linha exista, as funções RBAC já operam corretamente de imediato, sem passo adicional.

---

## Pré-requisitos

- As migrations do projeto já aplicadas no ambiente de destino (`supabase db push`).
- Acesso ao **SQL Editor** do Dashboard do Supabase (roda como `postgres`, que ignora RLS por padrão) — **ou** a Supabase CLI autenticada e vinculada ao projeto (`supabase db query`), como usado nesta validação.
- O UUID do usuário que se tornará o primeiro `super_admin` — precisa já existir em `auth.users` (ou seja, já ter feito cadastro/login pelo menos uma vez pelo app, ou ter sido criado via Dashboard).

## Como obter o UUID do usuário

Pelo Dashboard: **Authentication → Users** → localizar pelo e-mail → copiar o UUID exibido.

Ou via SQL (rodando como `postgres`, que ignora RLS):

```sql
select id, email from auth.users where email = 'seu-email@dominio.com';
```

## Processo

1. Abrir o **SQL Editor** do Dashboard do projeto de destino (ou `supabase db query --linked` pela CLI).
2. Executar, substituindo `<UUID_DO_USUARIO>`:

   ```sql
   insert into public.user_roles (user_id, role)
   values ('<UUID_DO_USUARIO>', 'super_admin');
   ```

3. Confirmar a criação:

   ```sql
   select user_id, role, created_at from public.user_roles where user_id = '<UUID_DO_USUARIO>';
   ```

Isso é suficiente e definitivo — não há passo adicional de "ativação". A partir daqui, `is_admin(auth.uid())` (e `has_admin_role`/`can_moderate`) já retornam `true` para esse usuário imediatamente, sem nenhuma correção pendente.

## Registrando o bootstrap

Diferente de toda ação administrativa feita pela própria aplicação (que grava em `audit_logs` automaticamente), este INSERT manual **não passa pelo app** e portanto não fica registrado ali. Recomenda-se anotar fora do banco (ex.: neste próprio documento, ou em um canal de operações da equipe): data, ambiente, quem executou e qual UUID foi promovido.

| Data | Ambiente | UUID promovido | Executado por |
|---|---|---|---|
| _(preencher a cada bootstrap real)_ | | | |

## Revogando ou trocando o super_admin

Depois que ao menos um `super_admin` existir, revogações e novas concessões já são possíveis **pela própria aplicação** (tela de Papéis do DV-08), já que a política de UPDATE/DELETE de `user_roles` também exige `super_admin` — não é mais necessário SQL manual a partir daí, exceto para recuperar acesso caso o único `super_admin` existente seja perdido (mesmo processo deste documento, de novo).
