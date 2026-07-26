-- RC-04B - Storage & Upload Security
--
-- Cria os 3 buckets efetivamente usados pelo app: `avatars`,
-- `restaurants`, `review-photos`. O AR-08_STORAGE_ARCHITECTURE.md
-- original (Fase 4) descrevia uma lista aspiracional de 9 buckets
-- (avatars/restaurants/groups/events/feed/badges/covers/temp/backups) -
-- só os 3 abaixo têm código de feature correspondente hoje
-- (UserRemoteDatasource, RestaurantRemoteDatasource,
-- ReviewRemoteDatasource); os demais ficam para quando houver um
-- consumidor real, "permitir expansão futura" (RC-04B).
--
-- Nome do bucket de avaliações padronizado nesta rodada como
-- `review-photos` (não `reviews`, nome genérico sugerido inicialmente) -
-- decisão explícita do usuário, para casar com o nome já usado pelo
-- código existente (ReviewRemoteDatasource) em vez de introduzir um
-- segundo nome para o mesmo domínio.
--
-- Limites de tamanho/MIME aplicados em duas camadas redundantes,
-- de propósito: aqui, no próprio bucket (`file_size_limit`/
-- `allowed_mime_types`, aplicado pelo Supabase Storage antes mesmo de
-- qualquer policy rodar) e também no cliente (StorageService, RC-04B) -
-- a camada do bucket nunca depende do cliente se comportar
-- corretamente ("nenhuma autorização poderá depender exclusivamente do
-- cliente").
--
-- ATENCAO: como toda migration deste projeto, escrita e revisada
-- estaticamente, sem validação contra uma instância real do
-- Supabase/Postgres (ver AR-06/EX-01B) - a suíte de testes de RLS de
-- Storage (supabase/tests/database/40_rls_storage.test.sql) está
-- pronta mas não foi executada pelo mesmo motivo (ver RC-04A §2/§3.2
-- para a mesma decisão já registrada sobre a suíte de RLS de tabelas).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('restaurants', 'restaurants', true, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('review-photos', 'review-photos', true, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- RLS já vem habilitada por padrão em `storage.objects` em qualquer
-- projeto Supabase - reforçado aqui só por consistência com o padrão
-- do restante do projeto (idempotente, não falha se já estiver ativa).
alter table storage.objects enable row level security;

-- Nenhum GRANT é necessário aqui (diferente das tabelas de `public`,
-- ver a lição da migration 20260720130000): `storage.objects`/
-- `storage.buckets` são provisionadas pela própria plataforma Supabase
-- no bootstrap do projeto, já com GRANT correto para
-- `anon`/`authenticated`/`service_role` - esse bug específico só
-- afetou tabelas criadas por migrations nossas em `public`.

-- ---------------------------------------------------------------------
-- avatars: bucket "privado" (sem URL pública, `public = false` acima),
-- mas legível por QUALQUER autenticado via URL assinada - mesmo modelo
-- de visibilidade de `public.profiles` (profiles_select_authenticated),
-- já que `public_profile_page.dart`/`follow_list_page.dart` resolvem o
-- avatar de qualquer usuário, não só o do próprio dono (ver
-- `ProfileAvatar`, que chama `createSignedAvatarUrl` para qualquer
-- `avatarPath`). Escrita restrita ao dono: convenção de nome
-- `<userId>/avatar.<ext>` (UserRemoteDatasource.uploadAvatar) - dono
-- identificado pelo primeiro segmento do caminho via
-- `storage.foldername()`, função utilitária oficial do Supabase Storage.
-- ---------------------------------------------------------------------

create policy "storage_avatars_select_authenticated"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'avatars');

create policy "storage_avatars_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_avatars_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "storage_avatars_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------
-- restaurants: bucket público (`public = true` acima) - a capa é lida
-- via URL pública direta (RestaurantRemoteDatasource.
-- getPublicCoverImageUrl), que não depende de RLS. A policy de SELECT
-- abaixo cobre o acesso autenticado direto à tabela `storage.objects`
-- (Dashboard, tooling), por consistência. Escrita restrita a quem
-- criou o restaurante (mesmo critério de `restaurants_update_own`,
-- DV-03) OU administrador/moderador (mesmo critério de
-- `restaurants_update_admin`, DV-08/RC-04A) - convenção de nome
-- `<restaurantId>/cover.<ext>` (RestaurantRemoteDatasource.
-- uploadCoverImage). A subconsulta a `public.restaurants` roda com o
-- privilégio do próprio usuário chamador (não SECURITY DEFINER) - sem
-- risco de recursão, já que `restaurants_select_authenticated` já
-- permite a qualquer autenticado ler qualquer linha da tabela.
-- ---------------------------------------------------------------------

create policy "storage_restaurants_select_authenticated"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'restaurants');

create policy "storage_restaurants_insert_own_or_admin"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'restaurants'
    and (
      exists (
        select 1 from public.restaurants r
        where r.id::text = (storage.foldername(name))[1]
          and r.created_by = auth.uid()
      )
      or public.can_moderate(auth.uid())
    )
  );

create policy "storage_restaurants_update_own_or_admin"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'restaurants'
    and (
      exists (
        select 1 from public.restaurants r
        where r.id::text = (storage.foldername(name))[1]
          and r.created_by = auth.uid()
      )
      or public.can_moderate(auth.uid())
    )
  )
  with check (
    bucket_id = 'restaurants'
    and (
      exists (
        select 1 from public.restaurants r
        where r.id::text = (storage.foldername(name))[1]
          and r.created_by = auth.uid()
      )
      or public.can_moderate(auth.uid())
    )
  );

create policy "storage_restaurants_delete_own_or_admin"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'restaurants'
    and (
      exists (
        select 1 from public.restaurants r
        where r.id::text = (storage.foldername(name))[1]
          and r.created_by = auth.uid()
      )
      or public.can_moderate(auth.uid())
    )
  );

-- ---------------------------------------------------------------------
-- review-photos: bucket público (mesmo raciocínio de `restaurants`) -
-- convenção de nome `<reviewId>/<nome-gerado>.<ext>`
-- (ReviewRemoteDatasource.uploadPhoto), múltiplos arquivos por
-- avaliação, nunca sobrescritos (nome sempre novo). Upload restrito ao
-- autor da avaliação; remoção também permitida a administrador/
-- moderador (mesmo critério de `reviews_update_admin`) - permite
-- remover uma foto imprópria sem precisar ocultar a avaliação inteira.
-- Sem policy de UPDATE: cada foto é um arquivo novo, nunca substituído.
-- ---------------------------------------------------------------------

create policy "storage_review_photos_select_authenticated"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'review-photos');

create policy "storage_review_photos_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'review-photos'
    and exists (
      select 1 from public.reviews rv
      where rv.id::text = (storage.foldername(name))[1]
        and rv.user_id = auth.uid()
    )
  );

create policy "storage_review_photos_delete_own_or_admin"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'review-photos'
    and (
      exists (
        select 1 from public.reviews rv
        where rv.id::text = (storage.foldername(name))[1]
          and rv.user_id = auth.uid()
      )
      or public.can_moderate(auth.uid())
    )
  );
