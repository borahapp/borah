-- F12 - Google Places API (New)
--
-- Nullable (restaurantes já cadastrados manualmente não têm Place ID) -
-- mesma decisão de `profiles.username` (FASE SOCIAL 2): coluna opcional,
-- índice único parcial (só sobre linhas não-nulas), para não colidir
-- entre si múltiplos restaurantes sem Place ID.
--
-- Índice único é defesa em profundidade: a checagem primária de
-- duplicidade acontece na aplicação (`RestaurantRepository.
-- findByGooglePlaceId` antes de criar) - este índice garante que a
-- regra "nunca duplicar por google_place_id" vale mesmo sob corrida
-- entre 2 clientes tentando cadastrar o mesmo lugar ao mesmo tempo.
alter table public.restaurants add column google_place_id text;

create unique index restaurants_google_place_id_unique_idx
  on public.restaurants (google_place_id)
  where google_place_id is not null;

-- Sem alteração de RLS: `restaurants_select_authenticated`/
-- `restaurants_insert_authenticated`/`restaurants_update_own` (DV-03) já
-- cobrem a nova coluna como qualquer outra - nenhuma policy nova é
-- necessária para um campo adicional na mesma tabela.
