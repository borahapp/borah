-- RC-03 FASE A2 (BORAH_VISION_v2.0.md) - foto opcional na avaliação
-- coletiva.
--
-- `photo_path` (não `photos_count`): decisão explícita do usuário -
-- a regra oficial do domínio (BORAH_VISION_v2.0.md, Capítulo 12,
-- decisão 3: "Foto é sempre opcional... em qualquer contexto de
-- avaliação") é de exatamente 1 foto por avaliação coletiva, diferente
-- de `reviews.photos_count` (até 5, DV-04). Guardar o caminho
-- diretamente evita a necessidade de listar a pasta do bucket para
-- descobrir a foto - a linha já sabe onde ela está, ou sabe que não
-- existe (`null`).
alter table public.event_reviews add column photo_path text;

-- Bucket PRIVADO (`public = false`), diferente de `review-photos`
-- (público) - decisão deliberada, não uma cópia do padrão existente.
-- `event_reviews` é dado de um Grupo fechado (BORAH_VISION_v2.0.md,
-- Princípio 15: "privacidade do grupo é absoluta") - uma foto anexada
-- aqui nunca pode ficar acessível a qualquer autenticado do app, só a
-- quem já é membro do grupo dono do rolê. Limites de tamanho/MIME
-- espelham exatamente `review-photos` (10 MB, jpg/jpeg/png/webp).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('event-review-photos', 'event-review-photos', false, 10485760, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Convenção de nome `<eventReviewId>/<nome-gerado>.<ext>` (mesmo padrão
-- de pasta-por-id já usado por `review-photos`/`avatars`/`restaurants`) -
-- só que aqui a pasta é o `id` de `event_reviews`, não de `reviews`.
--
-- SELECT: restrito a membros do grupo dono do rolê da avaliação
-- (`event_reviews` -> `events` -> `is_event_group_member`, função já
-- existente desde `20260731092000_create_events_and_attendances.sql`)
-- - a única divergência real frente aos 3 buckets já existentes, que
-- liberam SELECT para "qualquer autenticado". Aqui isso vazaria dado
-- de um grupo para fora dele, o que a Vision proíbe explicitamente.
create policy "storage_event_review_photos_select_group_members"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'event-review-photos'
    and exists (
      select 1 from public.event_reviews er
      where er.id::text = (storage.foldername(name))[1]
        and public.is_event_group_member(auth.uid(), er.event_id)
    )
  );

-- INSERT: só o autor da própria avaliação - mesmo critério de
-- `storage_review_photos_insert_own`, adaptado a `event_reviews`.
create policy "storage_event_review_photos_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'event-review-photos'
    and exists (
      select 1 from public.event_reviews er
      where er.id::text = (storage.foldername(name))[1]
        and er.user_id = auth.uid()
    )
  );

-- DELETE: autor da própria avaliação, OU admin/dono do grupo (permite
-- remover uma foto imprópria sem apagar a avaliação inteira, mesmo
-- espírito de `storage_review_photos_delete_own_or_admin` - aqui o
-- critério de "admin" é do GRUPO dono do rolê, não um moderador global,
-- porque a foto só é visível dentro daquele grupo), OU `can_moderate()`
-- (moderação global da plataforma continua se aplicando, como em todo
-- o resto do app).
create policy "storage_event_review_photos_delete_own_or_group_admin"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'event-review-photos'
    and exists (
      select 1 from public.event_reviews er
      join public.events e on e.id = er.event_id
      where er.id::text = (storage.foldername(name))[1]
        and (
          er.user_id = auth.uid()
          or public.is_group_admin(auth.uid(), e.group_id)
          or public.can_moderate(auth.uid())
        )
    )
  );

-- Sem policy de UPDATE - mesmo motivo de `review-photos`: cada foto é
-- um arquivo novo (nome sempre gerado, nunca reaproveitado); trocar a
-- foto de uma avaliação é upload do novo + delete do antigo
-- (`AppStorage.replace()`, camada de aplicação), nunca uma sobrescrita
-- in-place no Storage.
