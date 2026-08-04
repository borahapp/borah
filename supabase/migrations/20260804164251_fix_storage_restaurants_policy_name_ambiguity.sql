-- RC-02D - Correção retroativa das policies de storage.objects do bucket
-- `restaurants` (RC-04B, 20260725120000)
--
-- Achado real (RC-02D, smoke test da integração do bundle): upload de
-- foto de capa de restaurante falhava silenciosamente para QUALQUER
-- usuário, inclusive o dono legítimo do restaurante - `storage.objects`
-- nunca recebia a linha (bucket confirmado vazio) e `cover_image`
-- continuava `null` em `public.restaurants`, sem nenhuma exceção
-- capturável do lado do cliente.
--
-- Causa raiz: as 3 policies de `restaurants` (insert/update/delete)
-- referenciam `(storage.foldername(name))[1]` SEM qualificar `name` com
-- `objects.`, dentro de uma subquery correlacionada que também expõe
-- `public.restaurants` como `r`. Como `restaurants.name` existe (é o
-- nome do restaurante), a resolução de escopo do Postgres para uma
-- coluna não qualificada dentro do escopo mais interno (a subquery)
-- vence - `name` resolve para `r.name` (nome do restaurante, ex.:
-- "Restaurante QA Smoke"), não para `storage.objects.name` (o path do
-- arquivo sendo inserido, ex.: "<restaurantId>/cover.png"), fazendo a
-- comparação com `r.id::text` nunca bater. Mesmo padrão nas 3 policies,
-- só não afetou `storage_review_photos_insert_own` (20260725120000) por
-- coincidência - `public.reviews` não tem nenhuma coluna chamada
-- `name`, então lá a referência não qualificada já resolvia
-- corretamente para `storage.objects.name`.
--
-- Correção: qualificar explicitamente `objects.name` nas 3 policies -
-- nenhuma mudança de comportamento pretendido, só a referência de coluna
-- corrigida. `drop policy` + `create policy` (não é possível `alter
-- policy ... using/with check` para trocar a expressão em um único
-- comando) - exceção documentada à disciplina de nunca editar uma
-- migration já mesclada (mesmo precedente já registrado em
-- 20260725120000 para o `enable row level security` que nunca havia
-- funcionado em nenhum ambiente real).

drop policy "storage_restaurants_insert_own_or_admin" on storage.objects;
drop policy "storage_restaurants_update_own_or_admin" on storage.objects;
drop policy "storage_restaurants_delete_own_or_admin" on storage.objects;

create policy "storage_restaurants_insert_own_or_admin"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'restaurants'
    and (
      exists (
        select 1 from public.restaurants r
        where r.id::text = (storage.foldername(objects.name))[1]
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
        where r.id::text = (storage.foldername(objects.name))[1]
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
        where r.id::text = (storage.foldername(objects.name))[1]
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
        where r.id::text = (storage.foldername(objects.name))[1]
          and r.created_by = auth.uid()
      )
      or public.can_moderate(auth.uid())
    )
  );
