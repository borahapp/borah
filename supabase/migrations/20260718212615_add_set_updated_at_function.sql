-- Infraestrutura compartilhada do banco de dados.
--
-- Funcao generica de trigger para manter `updated_at` sempre correto em
-- qualquer tabela que possua essa coluna. Deve ser reutilizada por todas
-- as tabelas futuras com `updated_at` - nao recriar essa logica por tabela.
--
-- Corrige retroativamente a tabela `profiles` (DV-02), cuja migracao
-- original (20260718180242_create_profiles.sql) nao e alterada - esta
-- correcao ocorre em uma nova migracao, preservando o historico.
--
-- ATENCAO: assim como as demais migracoes do projeto, esta foi escrita e
-- revisada estaticamente, sem validacao contra uma instancia real do
-- Supabase/Postgres (nao ha ambiente executavel disponivel ainda).

create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();
