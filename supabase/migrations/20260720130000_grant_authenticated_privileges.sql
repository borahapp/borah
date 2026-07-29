-- Correção operacional - Bug 1 da Validação Funcional do Backend (2026-07-20)
--
-- Nenhuma das 21 migrations anteriores concede privilégios de tabela a
-- `authenticated`/`anon`. `supabase db push` cria objetos como o papel
-- `postgres`, cujo privilégio padrão do projeto (`pg_default_acl`) só
-- inclui TRUNCATE/REFERENCES/TRIGGER/MAINTAIN para `anon`/`authenticated`/
-- `service_role` - não SELECT/INSERT/UPDATE/DELETE. Só objetos criados
-- pelo papel `supabase_admin` (ex.: Dashboard) herdam acesso completo
-- automaticamente. Sem este GRANT, toda policy de RLS é inalcançável -
-- o erro ocorre antes mesmo de a RLS ser avaliada.
--
-- Cada GRANT abaixo espelha exatamente os comandos para os quais aquela
-- tabela já tem policy (nenhum privilégio extra além do que a RLS já
-- delimita por linha). `anon` não recebe nada - nenhuma policy do
-- projeto concede acesso a `anon`.

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.restaurants to authenticated;
grant select, insert, update on public.reviews to authenticated;
grant select, insert, delete on public.review_likes to authenticated;
grant select, insert, delete on public.favorites to authenticated;
grant select, insert, delete on public.followers to authenticated;
grant select, insert, update on public.comments to authenticated;
grant select, insert on public.comment_reports to authenticated;
grant select, insert, update on public.notification_preferences to authenticated;
grant select, update on public.notifications to authenticated;
grant select on public.user_progress to authenticated;
grant select on public.badges to authenticated;
grant select on public.user_badges to authenticated;
grant select, insert, update, delete on public.user_roles to authenticated;
grant select, insert on public.audit_logs to authenticated;
