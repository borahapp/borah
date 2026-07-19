-- DV-10 - Gamification Module (extensao do DV-09)
--
-- ATENCAO: esta migracao foi escrita e revisada estaticamente, mas NAO foi
-- validada contra uma instancia real do Supabase/Postgres (nenhum ambiente
-- executavel existe ainda - ver AR-06/EX-01B).
--
-- Primeira migracao de ALTERACAO (nao apenas criacao) do projeto - amplia
-- o CHECK de `notifications.type` (20260720100000) para incluir os dois
-- tipos do DV-10. A categoria 'gamification' ja existia na estrutura de
-- `notification_preferences` desde o DV-09 (sem UI) - reutilizada aqui
-- sem nenhuma infraestrutura nova (decisao 6 do DV-10).

alter table public.notifications drop constraint notifications_type_check;

alter table public.notifications add constraint notifications_type_check
  check (type in (
    'new_follower', 'new_comment', 'new_like', 'level_up', 'badge_earned'
  ));
