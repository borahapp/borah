-- RC-04B1 - Storage Hardening (achado da auditoria técnica da RC-04B)
--
-- Correção operacional, não uma criação nova - a migration original
-- (20260725120000_create_storage_buckets.sql) já commitada/mesclada em
-- `develop` NÃO é editada aqui, seguindo a mesma disciplina já aplicada
-- em todo o histórico do projeto (ver 20260718212615, 20260720130000,
-- 20260720130015, 20260720130030 - toda correção retroativa vira uma
-- migration nova, preservando o histórico).
--
-- Problema encontrado pela auditoria: a migration original usa
-- `on conflict (id) do nothing` ao criar os 3 buckets - se um bucket já
-- existir com `file_size_limit`/`allowed_mime_types` diferentes do
-- declarado (ex.: criado manualmente no Dashboard antes desta migration
-- rodar naquele ambiente), a divergência nunca é corrigida
-- automaticamente. Esta migration reconcilia esses dois campos, agora,
-- para os 3 buckets - convergindo qualquer ambiente onde já exista
-- divergência.
--
-- DECISÃO EXPLÍCITA (aprovada pelo usuário): esta reconciliação NUNCA
-- toca a coluna `public`. Diferente de `file_size_limit`/
-- `allowed_mime_types` (que só afetam uploads futuros, sem risco),
-- `public` tem efeito imediato de controle de acesso - o Supabase
-- Storage decide se serve um objeto via URL pública consultando essa
-- flag em tempo de requisição, não em tempo de upload. Uma mudança
-- futura de público/privado deve SEMPRE passar por uma migration nova
-- e explícita (revisável em code review), nunca por um UPDATE genérico
-- que rode de novo por engano.
--
-- ATENCAO: como toda migration deste projeto, escrita e revisada
-- estaticamente, sem validação contra uma instância real do
-- Supabase/Postgres (ver AR-06/EX-01B).

update storage.buckets
set
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'avatars';

update storage.buckets
set
  file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'restaurants';

update storage.buckets
set
  file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'review-photos';
