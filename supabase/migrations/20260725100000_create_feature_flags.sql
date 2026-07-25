-- RC-03D - Feature Flags Module
--
-- Tabela de configuracao para Feature Flags controladas remotamente.
-- Estrutura pensada para expansao futura (nao limitada as flags desta
-- rodada/a Beta): hoje cobre um booleano simples por chave; rollout
-- percentual, segmentacao por usuario ou payload JSON ficam para quando
-- houver um consumidor real (ver RC-03D_FEATURE_FLAGS.md).
--
-- RLS: leitura liberada para qualquer usuario autenticado - o app
-- inteiro (todos os usuarios, nao so administradores) precisa poder
-- consultar o estado das flags para decidir comportamento no cliente.
-- Escrita restrita a super_admin, mesmo criterio de "menor privilegio"
-- ja usado em public.user_roles - uma flag como `maintenance_mode` tem
-- alto raio de impacto (afeta o app inteiro), entao fica no nivel mais
-- restrito de administracao, nao em can_moderate()/is_admin() (que
-- incluem admin/moderator/support).
--
-- ATENCAO: assim como as demais migracoes do projeto, esta foi escrita
-- e revisada estaticamente, sem validacao contra uma instancia real do
-- Supabase/Postgres (ver AR-06/EX-01B).

create table public.feature_flags (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  enabled boolean not null default false,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.feature_flags enable row level security;

-- SELECT: qualquer usuario autenticado.
create policy "feature_flags_select_authenticated"
  on public.feature_flags for select
  to authenticated
  using (true);

-- INSERT/UPDATE/DELETE: somente super_admin.
create policy "feature_flags_insert_super_admin"
  on public.feature_flags for insert
  to authenticated
  with check (public.has_admin_role(auth.uid(), 'super_admin'));

create policy "feature_flags_update_super_admin"
  on public.feature_flags for update
  to authenticated
  using (public.has_admin_role(auth.uid(), 'super_admin'))
  with check (public.has_admin_role(auth.uid(), 'super_admin'));

create policy "feature_flags_delete_super_admin"
  on public.feature_flags for delete
  to authenticated
  using (public.has_admin_role(auth.uid(), 'super_admin'));

create trigger set_feature_flags_updated_at
  before update on public.feature_flags
  for each row execute procedure public.set_updated_at();

-- GRANT concedido já nesta migração (não numa correção posterior) -
-- lição da migração 20260720130000_grant_authenticated_privileges.sql:
-- sem GRANT de tabela, toda policy de RLS é inalcançável.
grant select, insert, update, delete on public.feature_flags to authenticated;

-- Flags iniciais (RC-03D) - infraestrutura apenas: nenhuma tela consome
-- nenhuma destas flags nesta rodada, então o valor de `enabled` não
-- altera nenhum comportamento existente. `enable_notifications`/
-- `enable_social`/`enable_reviews`/`enable_admin` cobrem módulos já
-- construídos e ativos hoje - default `true` (a flag, quando conectada
-- no futuro, representa "desligar", não "precisar ligar primeiro").
-- `new_feed`/`new_ranking`/`new_profile` representam redesenhos ainda
-- não construídos - default `false`. `maintenance_mode` sempre começa
-- `false`.
insert into public.feature_flags (key, enabled, description) values
  ('maintenance_mode', false, 'Bloqueia o uso do app em manutenção (infraestrutura apenas - ainda não conectado a nenhuma tela).'),
  ('new_feed', false, 'Nova versão do Feed (infraestrutura apenas).'),
  ('new_ranking', false, 'Nova versão do Ranking (infraestrutura apenas).'),
  ('new_profile', false, 'Nova versão do Perfil (infraestrutura apenas).'),
  ('enable_notifications', true, 'Disponibilidade do módulo de Notificações (infraestrutura apenas - o módulo já existe e continua ativo independente desta flag nesta rodada).'),
  ('enable_social', true, 'Disponibilidade do módulo Social/Feed (infraestrutura apenas - o módulo já existe e continua ativo independente desta flag nesta rodada).'),
  ('enable_reviews', true, 'Disponibilidade do módulo de Avaliações (infraestrutura apenas - o módulo já existe e continua ativo independente desta flag nesta rodada).'),
  ('enable_admin', true, 'Disponibilidade do painel administrativo (infraestrutura apenas - o módulo já existe e continua ativo independente desta flag nesta rodada).')
on conflict (key) do nothing;
