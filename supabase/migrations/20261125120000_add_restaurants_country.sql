-- Rodada "modernização visual + ranking multi-escopo" - filtro de País no
-- Ranking de restaurantes (Item F). Nullable, mesmo padrão de city/state
-- (20260718212629) - nenhum backfill: restaurantes já cadastrados (e os
-- futuros vindos do fluxo Google Places, que hoje não extrai componentes
-- estruturados de endereço) ficam sem país até o cadastro manual
-- preencher o novo campo. Mesma limitação que city/state já têm hoje -
-- decisão registrada, não uma regressão desta rodada.

alter table public.restaurants add column country text;
