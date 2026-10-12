-- ============================================================================
-- CognicQuest — Vérification manuelle des politiques RLS
-- ============================================================================
-- À coller dans le SQL Editor Supabase APRÈS avoir rejoué schema.sql.
-- Tout se passe dans une transaction annulée à la fin : aucune donnée réelle
-- n'est modifiée, les deux comptes de test disparaissent avec le rollback.
--
-- Chaque vérification lève une exception si la protection ne tient pas : un
-- script qui va jusqu'au bout et affiche « RLS : toutes les vérifications
-- passent » est un succès.
-- ============================================================================

begin;

-- Deux comptes fictifs : A (attaquant) et V (victime).
insert into auth.users (id, email, raw_user_meta_data)
values
  ('00000000-0000-4000-8000-00000000000a', 'a@rls.test', '{}'),
  ('00000000-0000-4000-8000-00000000000b', 'v@rls.test', '{}');

-- Données de la victime, écrites en tant que postgres (RLS non appliquée).
insert into public.notes (id, user_id, title)
values ('00000000-0000-4000-8000-0000000000f1',
        '00000000-0000-4000-8000-00000000000b', 'Fiche de V');
insert into public.tasks (id, user_id, title)
values ('00000000-0000-4000-8000-0000000000f2',
        '00000000-0000-4000-8000-00000000000b', 'Tâche de V');
insert into public.habits (id, user_id, name)
values ('00000000-0000-4000-8000-0000000000f3',
        '00000000-0000-4000-8000-00000000000b', 'Habitude de V');

-- À partir d'ici, on agit comme l'utilisateur A via PostgREST.
set local role authenticated;
set local request.jwt.claims =
  '{"sub": "00000000-0000-4000-8000-00000000000a", "role": "authenticated"}';

do $$
declare
  me constant uuid := '00000000-0000-4000-8000-00000000000a';
  victim_note constant uuid := '00000000-0000-4000-8000-0000000000f1';
  victim_task constant uuid := '00000000-0000-4000-8000-0000000000f2';
  victim_habit constant uuid := '00000000-0000-4000-8000-0000000000f3';
  missing constant uuid := '00000000-0000-4000-8000-0000000000ff';
  own_note uuid := gen_random_uuid();
  touched integer;
begin
  -- 1. profiles.plan : impossible de s'auto-promouvoir.
  begin
    update public.profiles set plan = 'premium' where id = me;
    raise exception 'ÉCHEC : plan modifiable par le client';
  exception when insufficient_privilege then null;
  end;

  -- 2. Un nom reste modifiable.
  update public.profiles set full_name = 'A' where id = me;

  -- 3. Une fiche à soi : autorisée, et référençable.
  insert into public.notes (id, user_id, title) values (own_note, me, 'Fiche de A');
  insert into public.flashcards (id, user_id, note_id, front, back)
  values (gen_random_uuid(), me, own_note, 'Q', 'R');

  -- 4. Référencer la fiche de V : refusé par la RLS (pas par la FK).
  begin
    insert into public.flashcards (id, user_id, note_id, front, back)
    values (gen_random_uuid(), me, victim_note, 'Q', 'R');
    raise exception 'ÉCHEC : carte rattachée à la fiche d''un autre compte';
  exception when insufficient_privilege then null;
  end;

  -- 5. Même erreur pour un identifiant inexistant : pas d'oracle d'existence.
  begin
    insert into public.flashcards (id, user_id, note_id, front, back)
    values (gen_random_uuid(), me, missing, 'Q', 'R');
    raise exception 'ÉCHEC : identifiant inexistant non refusé par la RLS';
  exception when insufficient_privilege then null;
  end;

  -- 6. Lien vers la fiche de V : refusé.
  begin
    insert into public.note_links (id, user_id, source_id, target_id)
    values (gen_random_uuid(), me, own_note, victim_note);
    raise exception 'ÉCHEC : lien vers la fiche d''un autre compte';
  exception when insufficient_privilege then null;
  end;

  -- 7. Session Pomodoro rattachée à la tâche de V : refusée.
  begin
    insert into public.pomodoro_sessions (user_id, task_id, duration_seconds)
    values (me, victim_task, 1500);
    raise exception 'ÉCHEC : session rattachée à la tâche d''un autre compte';
  exception when insufficient_privilege then null;
  end;

  -- 8. Position (ordre manuel) d'une fiche de V : la RLS la rend invisible,
  --    la mise à jour ne touche aucune ligne.
  update public.notes set position = 'V' where id = victim_note;
  get diagnostics touched = row_count;
  if touched <> 0 then
    raise exception 'ÉCHEC : position modifiable sur la fiche d''un autre compte';
  end if;

  -- 9. Sa propre fiche reste réordonnable.
  update public.notes set position = 'V' where id = own_note;
  get diagnostics touched = row_count;
  if touched <> 1 then
    raise exception 'ÉCHEC : position non modifiable sur sa propre fiche';
  end if;

  -- 10. Position d'une habitude de V : aucune ligne touchée.
  update public.habits set position = 'V' where id = victim_habit;
  get diagnostics touched = row_count;
  if touched <> 0 then
    raise exception 'ÉCHEC : position modifiable sur l''habitude d''un autre compte';
  end if;

  raise notice 'RLS : toutes les vérifications passent';
end;
$$;

rollback;
