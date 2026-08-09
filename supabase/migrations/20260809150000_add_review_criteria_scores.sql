-- RC-03 F16 - Avaliação por categorias em `reviews` (paridade com
-- `event_reviews`, ver 20260801100000_create_event_reviews.sql - mesmos 5
-- critérios: ambiente/atendimento/comida/custo-benefício/geral).
--
-- `rating` NAO e removido nem renomeado - continua existindo, mantido como
-- a nota geral/compatibilidade (decisao ja registrada em
-- RC03_FEATURE_GAP.md §3: "a coluna rating unica nao e removida, pode virar
-- media calculada dos 5 criterios"). Os 4 criterios abaixo sao novos,
-- NULLABLE - calculados no cliente (review_repository_impl.dart) como a
-- media que alimenta `rating` a cada criacao/edicao feita pela UI nova.
-- Avaliacoes ja existentes continuam validas com os 4 campos nulos, sem
-- nenhuma migracao de dado retroativa.
--
-- Nenhuma alteracao em `recalculate_restaurant_rating()`
-- (20260718230545_create_reviews_average_rating_trigger.sql) - continua
-- agregando `rating` como ja fazia, independente de como cada linha chegou
-- a esse valor (nota unica manual, legado; ou media dos 5 criterios, novo).

alter table public.reviews add column ambience_score numeric(2, 1) check (ambience_score between 1 and 5);
alter table public.reviews add column service_score numeric(2, 1) check (service_score between 1 and 5);
alter table public.reviews add column food_score numeric(2, 1) check (food_score between 1 and 5);
alter table public.reviews add column cost_benefit_score numeric(2, 1) check (cost_benefit_score between 1 and 5);
