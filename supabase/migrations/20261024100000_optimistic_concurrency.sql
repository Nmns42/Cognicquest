-- ============================================================================
-- Contrôle de version optimiste (écritures obsolètes refusées)
-- ============================================================================
-- Le client envoie dans `updated_at` la version serveur sur laquelle repose
-- sa modification (dernière valeur lue au pull ou reçue au push). Si la ligne
-- a changé depuis sur le serveur (autre appareil), l'écriture est refusée
-- avec le code 40001 au lieu d'écraser silencieusement la version récente :
-- le client la rapatrie alors.
--
-- Sans `updated_at` dans la requête (création, déplacement partiel, anciens
-- clients), new.updated_at reste égal à old.updated_at : rien n'est refusé.
--
-- Nom en `*_a_reject_stale` : les triggers d'une même table s'exécutent par
-- ordre alphabétique, celui-ci doit passer avant `*_set_updated_at`, qui
-- remplace updated_at par now().

create or replace function public.reject_stale_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.updated_at < old.updated_at then
    raise exception 'Écriture obsolète sur %.% (%)', tg_table_schema,
      tg_table_name, old.id
      using errcode = '40001';
  end if;
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['notes', 'flashcards', 'tasks'] loop
    execute format('drop trigger if exists %I on public.%I',
      t || '_a_reject_stale', t);
    execute format(
      'create trigger %I before update on public.%I '
      'for each row execute function public.reject_stale_write()',
      t || '_a_reject_stale', t);
  end loop;
end $$;
