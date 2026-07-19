-- DV-08 - Administration Module (excecao documentada ao AR-13)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- AR-13 (guideline permanente) recomenda que operacoes administrativas
-- ocorram exclusivamente via Edge Functions/backend privilegiado. Nao
-- existe infraestrutura de Edge Functions no projeto (AR-09 adiado por
-- falta de consumidor real). Decisao explicita do usuario (DV-08): para
-- OPERACOES SOBRE DADOS DE APLICACAO (restaurants/reviews/comments/
-- comment_reports), autorizar via RLS baseada em papel (can_moderate/
-- is_admin) e aceitavel - SEM Service Role Key, sem Edge Function. Isso
-- NAO se aplica a operacoes sobre o Supabase Auth (ex.: bloquear login de
-- um usuario), que continuam exigindo infraestrutura privilegiada futura
-- e permanecem fora de escopo (ver decisao "Bloquear usuario" do DV-08).
--
-- Cada policy abaixo e adicionada as ja existentes (RLS permissiva: a
-- linha passa se QUALQUER policy do mesmo comando for satisfeita) - nao
-- substitui a policy de dono ja criada em DV-03/04/07.

-- restaurants: admin/moderador podem editar/arquivar/reativar qualquer
-- restaurante (Gestao de Restaurantes - DV-08 SS6, exceto "Aprovar
-- cadastro", fora de escopo).
create policy "restaurants_update_admin"
  on public.restaurants for update
  to authenticated
  using (public.can_moderate(auth.uid()))
  with check (public.can_moderate(auth.uid()));

-- reviews: admin/moderador podem ocultar (soft delete) qualquer avaliacao
-- (Moderacao de Avaliacoes - DV-08 SS6).
create policy "reviews_update_admin"
  on public.reviews for update
  to authenticated
  using (public.can_moderate(auth.uid()))
  with check (public.can_moderate(auth.uid()));

-- comments: admin/moderador podem ocultar (soft delete) qualquer
-- comentario (Moderacao de Comentarios - DV-08 SS6). O trigger de janela
-- de edicao (DV-07) so bloqueia mudanca de `content`, entao a exclusao
-- logica do admin (`deleted_at`) nao e afetada pelo prazo de 15 minutos.
create policy "comments_update_admin"
  on public.comments for update
  to authenticated
  using (public.can_moderate(auth.uid()))
  with check (public.can_moderate(auth.uid()));

-- comment_reports: qualquer administrador (inclusive support, que so
-- consulta) pode ver todas as denuncias, nao apenas as que registrou
-- (Moderacao de Denuncias - DV-08 SS6).
create policy "comment_reports_select_admin"
  on public.comment_reports for select
  to authenticated
  using (public.is_admin(auth.uid()));
