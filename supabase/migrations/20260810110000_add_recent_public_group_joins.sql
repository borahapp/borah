-- FASE SOCIAL 4 - RPC de entrada em grupo público, para o card "[Pessoa]
-- entrou no grupo" do Feed ("Para Você"/descoberta).
--
-- `group_members` continua fechada a não-membros mesmo em grupo public
-- (decisão da FASE SOCIAL 3, não revisitada aqui) - o cliente nunca pode
-- consultar essa tabela diretamente para montar esta atividade.
-- `security definer` é o único jeito de expor um recorte seguro dela: a
-- função só enxerga `group_members` de grupos com `visibility = 'public'`
-- (filtro aplicado dentro da própria função, nunca confiado ao cliente),
-- nunca retorna a lista completa de membros de um grupo (só linhas
-- individuais de entrada, paginadas, mesmo tipo de exposição que
-- `groups.member_count` já concede hoje) e nunca alcança grupo `private`
-- em nenhuma circunstância - mesmo padrão de `is_event_group_member`/
-- `can_review_event` (funções `security definer` de leitura, `language
-- sql stable`, sem necessidade de `auth.uid()` porque o dado retornado já
-- é público por definição de `visibility = 'public'`, ao contrário de
-- `group_activity_feed()` (RC-03 F25), que é sobre atividade INTERNA de
-- um grupo específico e por isso precisa checar membership).
--
-- Perfis: sem coluna de privacidade em `profiles` (lacuna já registrada
-- em `20260719150000_create_followers.sql`) - não há nada para filtrar
-- além de `visibility = 'public'` do próprio grupo; todo perfil já é
-- lido por qualquer autenticado em qualquer outra tela do app.
--
-- Join com `profiles` direto na função (não uma consulta separada no
-- cliente) - evita uma segunda viagem ao banco por página do Feed.
create function public.recent_public_group_joins(
  p_limit integer,
  p_offset integer
)
returns table (
  member_id uuid,
  group_id uuid,
  group_name text,
  group_photo_url text,
  member_count integer,
  user_id uuid,
  full_name text,
  username text,
  avatar_url text,
  joined_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    gm.id,
    gm.group_id,
    g.name,
    g.photo_url,
    g.member_count,
    gm.user_id,
    p.full_name,
    p.username,
    p.avatar_url,
    gm.created_at
  from public.group_members gm
  join public.groups g on g.id = gm.group_id
  join public.profiles p on p.id = gm.user_id
  where g.visibility = 'public'
  order by gm.created_at desc
  limit p_limit offset p_offset;
$$;

revoke execute on function public.recent_public_group_joins(integer, integer) from public;
grant execute on function public.recent_public_group_joins(integer, integer) to authenticated;
