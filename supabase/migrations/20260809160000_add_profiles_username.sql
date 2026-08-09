-- FASE SOCIAL 2 - profiles.username
--
-- Nullable (contas antigas continuam funcionando sem username) e unico
-- por comparacao case-insensitive: o indice unico e sobre lower(username),
-- nao sobre a coluna crua, entao "Victor" e "victor" colidem, que e o
-- comportamento pedido. "WHERE username IS NOT NULL" deixa explicito que
-- multiplas contas sem username nunca colidem entre si (e evita indexar
-- a maioria das contas hoje, que nao tem username).
--
-- Protecao de escrita: reaproveita a policy "profiles_update_own" ja
-- existente (20260718180242_create_profiles.sql, "using (auth.uid() = id)
-- with check (auth.uid() = id)") - username e só mais uma coluna de
-- profiles, a mesma policy ja impede qualquer usuario de alterar a linha
-- de outro. Nenhuma policy nova necessaria.

alter table public.profiles
  add column username text;

alter table public.profiles
  add constraint profiles_username_format check (
    username is null
    or (
      length(username) between 3 and 30
      and username ~ '^[a-zA-Z0-9_.]+$'
    )
  );

create unique index profiles_username_unique_idx
  on public.profiles (lower(username))
  where username is not null;
