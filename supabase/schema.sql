-- ============================================================================
-- CognicQuest — Schéma Supabase (Lot 1 : socle & authentification)
-- ============================================================================
-- À exécuter dans le SQL Editor du projet Supabase. Le script est idempotent :
-- il peut être rejoué sans casser les données existantes.
--
-- Périmètre Lot 1 : les tables déjà référencées par le code existant
--   - profiles   : profil applicatif adossé à auth.users
--   - tasks      : Kanban / to-do (lib/shared/models/task_model.dart)
--   - habits     : suivi d'habitudes (lib/shared/models/habit_model.dart)
--   - habit_logs : une ligne par jour coché
--
-- Hors périmètre, arrive au Lot 2 : pomodoro_sessions, ainsi que les colonnes
-- supplémentaires du Kanban (échéance, tags, ordre des colonnes).
-- ============================================================================

-- ─── Extensions ─────────────────────────────────────────────────────────────

create extension if not exists "pgcrypto";

-- ─── Utilitaire : mise à jour automatique de updated_at ─────────────────────

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ─── Utilitaires : propriété des lignes référencées (anti-IDOR) ─────────────
-- Une politique `with check (auth.uid() = user_id)` ne vérifie que la ligne
-- écrite, pas celles qu'elle référence : on pouvait rattacher une carte, un
-- lien ou une session à la fiche / tâche d'un autre compte, et l'erreur de
-- clé étrangère servait d'oracle d'existence. Ces fonctions sont appelées
-- depuis les `with check` : évaluées avant la contrainte FK, elles refusent
-- (42501) toute référence étrangère, qu'elle existe ou non.
--
-- plpgsql plutôt que sql : le corps n'est pas validé à la création, les
-- tables visées pouvant être créées plus bas dans ce script.
-- NULL est accepté : les références facultatives restent facultatives.

create or replace function public.owns_note(target uuid)
returns boolean
language plpgsql
stable
set search_path = public
as $$
begin
  return target is null or exists (
    select 1 from public.notes n
    where n.id = target and n.user_id = auth.uid()
  );
end;
$$;

create or replace function public.owns_task(target uuid)
returns boolean
language plpgsql
stable
set search_path = public
as $$
begin
  return target is null or exists (
    select 1 from public.tasks t
    where t.id = target and t.user_id = auth.uid()
  );
end;
$$;

create or replace function public.owns_study_goal(target uuid)
returns boolean
language plpgsql
stable
set search_path = public
as $$
begin
  return target is null or exists (
    select 1 from public.study_goals g
    where g.id = target and g.user_id = auth.uid()
  );
end;
$$;

create or replace function public.owns_plan_item(target uuid)
returns boolean
language plpgsql
stable
set search_path = public
as $$
begin
  return target is null or exists (
    select 1 from public.plan_items i
    where i.id = target and i.user_id = auth.uid()
  );
end;
$$;

-- ============================================================================
-- profiles
-- ============================================================================

create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text,
  avatar_url  text,
  -- Modèle économique du CdC : freemium B2C, abonnement pro B2B.
  plan        text not null default 'free'
                check (plan in ('free', 'premium', 'pro')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- Pas d'insertion côté client : le profil est créé par `handle_new_user`
-- (security definer). L'ancienne politique permettait d'insérer une ligne
-- avec `plan = 'premium'`.
drop policy if exists "profiles_insert_own" on public.profiles;

-- `plan` porte le modèle économique : seul le serveur (service_role, webhooks
-- de paiement) peut l'écrire. Avec une politique `for update` seule,
-- l'utilisateur pouvait s'auto-promouvoir via la clé anon. Les droits par
-- colonne limitent ce que PostgREST accepte de mettre à jour.
revoke insert, update on public.profiles from anon, authenticated;
grant update (full_name, avatar_url) on public.profiles to authenticated;

-- Seconde barrière, au cas où un `grant all` (ex. réinitialisation des
-- privilèges par défaut) rouvrirait la colonne : toute requête portée par un
-- JWT utilisateur qui touche à `plan` est refusée. Le SQL Editor (postgres)
-- et service_role ne sont pas concernés.
create or replace function public.protect_profile_plan()
returns trigger
language plpgsql
as $$
begin
  if coalesce(auth.role(), '') in ('anon', 'authenticated') then
    if tg_op = 'INSERT' and new.plan <> 'free' then
      raise exception 'profiles.plan ne peut pas être choisi par le client'
        using errcode = '42501';
    end if;
    if tg_op = 'UPDATE' and new.plan is distinct from old.plan then
      raise exception 'profiles.plan ne peut pas être modifié par le client'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_plan on public.profiles;
create trigger profiles_protect_plan
  before insert or update on public.profiles
  for each row execute function public.protect_profile_plan();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Création automatique du profil à l'inscription.
-- `full_name` provient du champ `data` passé à auth.signUp() côté Flutter,
-- ou du profil Google pour une connexion OAuth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(new.email, '@', 1)
    ),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- tasks  (Kanban / to-do)
-- ============================================================================

create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  title       text not null check (char_length(title) between 1 and 200),
  description text not null default '',
  status      text not null default 'todo'
                check (status in ('todo', 'doing', 'done')),
  priority    text not null default 'medium'
                check (priority in ('low', 'medium', 'high')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists tasks_user_status_idx
  on public.tasks (user_id, status, created_at desc);

alter table public.tasks enable row level security;

drop policy if exists "tasks_all_own" on public.tasks;
create policy "tasks_all_own" on public.tasks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop trigger if exists tasks_set_updated_at on public.tasks;
create trigger tasks_set_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

-- ============================================================================
-- habits + habit_logs
-- ============================================================================

create table if not exists public.habits (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  name       text not null check (char_length(name) between 1 and 120),
  frequency  text not null default 'daily'
               check (frequency in ('daily', 'weekly', 'monthly')),
  created_at timestamptz not null default now()
);

create index if not exists habits_user_idx
  on public.habits (user_id, created_at);

alter table public.habits enable row level security;

drop policy if exists "habits_all_own" on public.habits;
create policy "habits_all_own" on public.habits
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.habit_logs (
  id       uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits (id) on delete cascade,
  -- Le client envoie une date locale au format 'yyyy-MM-dd'
  -- (cf. Habit.toDateKey). Le type `date` évite tout décalage de fuseau.
  date     date not null,
  -- Empêche le double comptage d'un même jour, que le modèle Dart ne
  -- garantissait pas côté client.
  unique (habit_id, date)
);

create index if not exists habit_logs_habit_date_idx
  on public.habit_logs (habit_id, date desc);

alter table public.habit_logs enable row level security;

-- Le propriétaire d'un log est celui de l'habitude parente.
drop policy if exists "habit_logs_all_own" on public.habit_logs;
create policy "habit_logs_all_own" on public.habit_logs
  for all
  using (
    exists (
      select 1 from public.habits h
      where h.id = habit_logs.habit_id and h.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.habits h
      where h.id = habit_logs.habit_id and h.user_id = auth.uid()
    )
  );

-- ============================================================================
-- Rattrapage : créer les profils des comptes existants créés avant le trigger
-- ============================================================================

insert into public.profiles (id, full_name)
select
  u.id,
  coalesce(u.raw_user_meta_data ->> 'full_name', split_part(u.email, '@', 1))
from auth.users u
on conflict (id) do nothing;

-- ============================================================================
-- Lot 2 — Productivité de base (Pomodoro / Kanban / Habitudes)
-- ============================================================================
-- Rejouable : n'ajoute que ce qui manque au schéma du Lot 1.

-- ─── tasks : Eisenhower, échéance et ordre des cartes ───────────────────────

alter table public.tasks
  add column if not exists due_date     date,
  add column if not exists is_urgent    boolean not null default false,
  add column if not exists is_important boolean not null default false,
  add column if not exists position     integer not null default 0;

-- Tri d'une colonne après glisser-déposer.
create index if not exists tasks_user_status_position_idx
  on public.tasks (user_id, status, position);

-- Filtrage de la matrice d'Eisenhower.
create index if not exists tasks_user_eisenhower_idx
  on public.tasks (user_id, is_urgent, is_important)
  where status <> 'done';

-- Migration des anciens statuts : la page filtrait sur 'in_progress' alors que
-- la contrainte n'autorise que 'doing'. Sans ce recodage, ces lignes seraient
-- rejetées à la prochaine écriture.
update public.tasks set status = 'doing' where status = 'in_progress';

-- ─── pomodoro_sessions ─────────────────────────────────────────────────────
-- « Intégrer un système de suivi des progrès (sessions terminées, temps total
-- d'étude) » — sans cette table, les compteurs repartent de zéro à chaque
-- lancement de l'application.

create table if not exists public.pomodoro_sessions (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  started_at       timestamptz not null default now(),
  duration_seconds integer not null check (duration_seconds > 0),
  -- Lien facultatif « session d'étude ↔ tâche ». on delete set null : la
  -- suppression d'une tâche ne doit pas effacer le temps d'étude déjà réalisé.
  task_id          uuid references public.tasks (id) on delete set null,
  created_at       timestamptz not null default now()
);

create index if not exists pomodoro_sessions_user_started_idx
  on public.pomodoro_sessions (user_id, started_at desc);

alter table public.pomodoro_sessions enable row level security;

drop policy if exists "pomodoro_sessions_all_own" on public.pomodoro_sessions;
create policy "pomodoro_sessions_all_own" on public.pomodoro_sessions
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_task(task_id)
  );

-- ============================================================================
-- Lot 3 — Dashboard « centre de contrôle »
-- ============================================================================

-- Préférences utilisateur, synchronisées entre appareils.
-- Table volontairement générique : le Lot 9 (thème, taille de texte, sons
-- d'ambiance) y ajoutera ses colonnes sans nouvelle migration structurelle.
create table if not exists public.user_preferences (
  user_id          uuid primary key references auth.users (id) on delete cascade,
  -- {"order": ["stats","weekly_focus",...], "hidden": ["habits"]}
  dashboard_layout jsonb not null default '{}'::jsonb,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

alter table public.user_preferences enable row level security;

drop policy if exists "user_preferences_all_own" on public.user_preferences;
create policy "user_preferences_all_own" on public.user_preferences
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop trigger if exists user_preferences_set_updated_at on public.user_preferences;
create trigger user_preferences_set_updated_at
  before update on public.user_preferences
  for each row execute function public.set_updated_at();

-- ============================================================================
-- Lot 4 — Base de connaissances (fiches)
-- ============================================================================
-- Miroir distant de la base locale SQLite/Drift. La source de vérité est
-- locale : ces tables servent la sauvegarde et la synchronisation multi-appareils.
--
-- Les identifiants sont générés par le client (UUID v4) et non par Postgres :
-- une fiche créée hors ligne porte déjà son identité définitive.

create table if not exists public.notes (
  id           uuid primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  title        text not null default '',
  content      text not null default '',
  subject      text,
  tags         jsonb not null default '[]'::jsonb,
  importance   smallint not null default 1 check (importance between 0 and 2),
  is_favorite  boolean not null default false,
  is_archived  boolean not null default false,
  created_at   timestamptz not null default now(),
  -- Horodatage fourni par le client : c'est lui qui arbitre les conflits
  -- (« la version la plus récemment modifiée gagne »). Un `now()` serveur
  -- ferait toujours gagner la dernière synchro, pas la dernière édition.
  updated_at   timestamptz not null default now()
);

create index if not exists notes_user_updated_idx
  on public.notes (user_id, updated_at desc);

create index if not exists notes_user_subject_idx
  on public.notes (user_id, subject) where is_archived = false;

-- Recherche par tag côté serveur (le client, lui, cherche en local).
create index if not exists notes_tags_idx on public.notes using gin (tags);

alter table public.notes enable row level security;

drop policy if exists "notes_all_own" on public.notes;
create policy "notes_all_own" on public.notes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.note_blocks (
  id         uuid primary key,
  note_id    uuid not null references public.notes (id) on delete cascade,
  type       text not null default 'paragraph'
               check (type in ('paragraph','heading','bulleted','todo',
                               'quote','code','image','link','divider')),
  content    text not null default '',
  is_checked boolean not null default false,
  position   integer not null default 0
);

create index if not exists note_blocks_note_position_idx
  on public.note_blocks (note_id, position);

alter table public.note_blocks enable row level security;

-- Le propriétaire d'un bloc est celui de la fiche parente.
drop policy if exists "note_blocks_all_own" on public.note_blocks;
create policy "note_blocks_all_own" on public.note_blocks
  for all
  using (
    exists (
      select 1 from public.notes n
      where n.id = note_blocks.note_id and n.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.notes n
      where n.id = note_blocks.note_id and n.user_id = auth.uid()
    )
  );

-- ============================================================================
-- Lot 5 — Graphe de connaissances
-- ============================================================================
-- Miroir distant des liens entre fiches. Comme pour les fiches, la source de
-- vérité est locale (SQLite/Drift) et l'identifiant est généré par le client.

create table if not exists public.note_links (
  id         uuid primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  source_id  uuid not null references public.notes (id) on delete cascade,
  target_id  uuid not null references public.notes (id) on delete cascade,
  type       text not null default 'related'
               check (type in ('related', 'seen', 'to_review', 'prerequisite')),
  label      text,
  created_at timestamptz not null default now(),

  -- Une fiche ne se relie pas à elle-même : l'arête n'apprendrait rien et
  -- fausserait le calcul des degrés du graphe.
  constraint note_links_no_self_loop check (source_id <> target_id),
  -- Empêche de créer deux fois la même arête, ce que l'interface seule ne peut
  -- pas garantir en mode hors ligne multi-appareils.
  constraint note_links_unique_edge unique (source_id, target_id, type)
);

-- Parcours du graphe dans les deux sens : une arête se lit depuis chacune de
-- ses extrémités, donc deux index et non un seul.
create index if not exists note_links_source_idx
  on public.note_links (user_id, source_id);
create index if not exists note_links_target_idx
  on public.note_links (user_id, target_id);

alter table public.note_links enable row level security;

drop policy if exists "note_links_all_own" on public.note_links;
create policy "note_links_all_own" on public.note_links
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_note(source_id)
    and public.owns_note(target_id)
  );

-- ============================================================================
-- Lot 6 — Révision active
-- ============================================================================
-- Miroir distant des cartes, auto-explications et sessions SQ3R.
-- L'historique détaillé des jugements (local_review_logs) reste **local** :
-- il alimente les statistiques et ne justifie pas un aller-retour réseau à
-- chaque carte jugée.

create table if not exists public.flashcards (
  id          uuid primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  -- on delete set null : supprimer une fiche ne doit pas détruire une carte
  -- déjà mémorisée, ni son historique de répétition espacée.
  note_id     uuid references public.notes (id) on delete set null,
  front       text not null,
  back        text not null,
  deck        text,
  -- État de répétition espacée (méthode des J + facteur de facilité).
  step        integer not null default 0,
  ease_factor real not null default 2.5 check (ease_factor between 1.3 and 2.8),
  due_at      timestamptz not null default now(),
  repetitions integer not null default 0,
  lapses      integer not null default 0,
  created_at  timestamptz not null default now()
);

-- Requête principale : « quelles cartes sont échues pour cet utilisateur ».
create index if not exists flashcards_user_due_idx
  on public.flashcards (user_id, due_at);
create index if not exists flashcards_note_idx
  on public.flashcards (note_id);

alter table public.flashcards enable row level security;

drop policy if exists "flashcards_all_own" on public.flashcards;
create policy "flashcards_all_own" on public.flashcards
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_note(note_id)
  );

-- ─── Auto-explications (mode « Explique-moi ») ──────────────────────────────

create table if not exists public.explanations (
  id         uuid primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  note_id    uuid not null references public.notes (id) on delete cascade,
  content    text not null,
  confidence smallint not null default 3 check (confidence between 1 and 5),
  created_at timestamptz not null default now()
);

create index if not exists explanations_note_created_idx
  on public.explanations (note_id, created_at desc);

alter table public.explanations enable row level security;

drop policy if exists "explanations_all_own" on public.explanations;
create policy "explanations_all_own" on public.explanations
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_note(note_id)
  );

-- ─── Sessions de lecture guidée SQ3R ────────────────────────────────────────

create table if not exists public.sq3r_sessions (
  id           uuid primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  note_id      uuid not null references public.notes (id) on delete cascade,
  current_step smallint not null default 0 check (current_step between 0 and 4),
  survey_notes text not null default '',
  questions    jsonb not null default '[]'::jsonb,
  recite_notes text not null default '',
  review_notes text not null default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  completed_at timestamptz,

  -- Une seule session par fiche : on reprend la lecture en cours plutôt que
  -- d'en empiler des copies.
  constraint sq3r_sessions_one_per_note unique (note_id)
);

alter table public.sq3r_sessions enable row level security;

drop policy if exists "sq3r_sessions_all_own" on public.sq3r_sessions;
create policy "sq3r_sessions_all_own" on public.sq3r_sessions
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_note(note_id)
  );

-- ============================================================================
-- Lot 7 — Métacognition
-- ============================================================================
-- Journal (humeur / énergie / RPE + bilan guidé), recadrage cognitif,
-- 5 Pourquoi, analyse des erreurs et profil d'apprentissage.

create table if not exists public.journal_entries (
  id           uuid primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  -- set null : supprimer une fiche ne doit pas effacer le ressenti d'une
  -- session déjà vécue.
  note_id      uuid references public.notes (id) on delete set null,
  mood         smallint not null default 3 check (mood between 1 and 5),
  energy       smallint not null default 3 check (energy between 1 and 5),
  rpe          smallint not null default 5 check (rpe between 1 and 10),
  what_learned text not null default '',
  what_worked  text not null default '',
  what_blocked text not null default '',
  next_step    text not null default '',
  created_at   timestamptz not null default now()
);

create index if not exists journal_entries_user_created_idx
  on public.journal_entries (user_id, created_at desc);

alter table public.journal_entries enable row level security;

drop policy if exists "journal_entries_all_own" on public.journal_entries;
create policy "journal_entries_all_own" on public.journal_entries
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_note(note_id)
  );

-- ─── Recadrage cognitif ─────────────────────────────────────────────────────

create table if not exists public.reframes (
  id               uuid primary key,
  user_id          uuid not null references auth.users (id) on delete cascade,
  limiting_thought text not null,
  distortion       text,
  evidence_against text not null default '',
  reframed_thought text not null default '',
  growth_goal      text not null default '',
  created_at       timestamptz not null default now()
);

create index if not exists reframes_user_created_idx
  on public.reframes (user_id, created_at desc);

alter table public.reframes enable row level security;

drop policy if exists "reframes_all_own" on public.reframes;
create policy "reframes_all_own" on public.reframes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── Les 5 Pourquoi ─────────────────────────────────────────────────────────

create table if not exists public.why_chains (
  id           uuid primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  problem      text not null,
  answers      jsonb not null default '[]'::jsonb,
  root_cause   text not null default '',
  -- Nature du frein : cognitif, émotionnel, sensoriel ou environnemental.
  blocker_type text check (blocker_type in
                 ('cognitive', 'emotional', 'sensory', 'environmental')),
  action_plan  text not null default '',
  created_at   timestamptz not null default now()
);

create index if not exists why_chains_user_created_idx
  on public.why_chains (user_id, created_at desc);

alter table public.why_chains enable row level security;

drop policy if exists "why_chains_all_own" on public.why_chains;
create policy "why_chains_all_own" on public.why_chains
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── Analyse des erreurs ────────────────────────────────────────────────────

create table if not exists public.error_logs (
  id          uuid primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  note_id     uuid references public.notes (id) on delete set null,
  subject     text,
  description text not null,
  error_type  text not null check (error_type in
                ('inattention', 'comprehension', 'method',
                 'memorisation', 'instructions')),
  correction  text not null default '',
  created_at  timestamptz not null default now()
);

-- Requête principale : regrouper les erreurs par type, éventuellement par
-- matière (« Error Patterns » du CdC).
create index if not exists error_logs_user_type_idx
  on public.error_logs (user_id, error_type, created_at desc);
create index if not exists error_logs_user_subject_idx
  on public.error_logs (user_id, subject);

alter table public.error_logs enable row level security;

drop policy if exists "error_logs_all_own" on public.error_logs;
create policy "error_logs_all_own" on public.error_logs
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_note(note_id)
  );

-- ─── Profil d'apprentissage ─────────────────────────────────────────────────

create table if not exists public.learning_profiles (
  -- Clé primaire = utilisateur : c'est son mode d'emploi, pas un historique.
  user_id           uuid primary key references auth.users (id) on delete cascade,
  answers           jsonb not null default '{}'::jsonb,
  processing_style  text check (processing_style in ('global', 'sequential')),
  preferred_channel text check (preferred_channel in
                      ('visual', 'auditory', 'kinesthetic', 'reading')),
  completed_at      timestamptz,
  updated_at        timestamptz not null default now()
);

alter table public.learning_profiles enable row level security;

drop policy if exists "learning_profiles_all_own" on public.learning_profiles;
create policy "learning_profiles_all_own" on public.learning_profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- Lot 8 — Planification avancée
-- ============================================================================
-- Objectifs SMART, diagramme de Gantt, mesures de vitesse et cibles d'examen.

create table if not exists public.study_goals (
  id              uuid primary key,
  user_id         uuid not null references auth.users (id) on delete cascade,
  -- S
  title           text not null,
  subject         text,
  -- M
  metric_label    text not null default '',
  target_value    double precision not null default 0,
  current_value   double precision not null default 0,
  -- A
  achievable_plan text not null default '',
  -- R
  relevance       text not null default '',
  -- T
  deadline        timestamptz,
  created_at      timestamptz not null default now(),
  completed_at    timestamptz
);

create index if not exists study_goals_user_deadline_idx
  on public.study_goals (user_id, deadline);

alter table public.study_goals enable row level security;

drop policy if exists "study_goals_all_own" on public.study_goals;
create policy "study_goals_all_own" on public.study_goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── Éléments du Gantt ──────────────────────────────────────────────────────

create table if not exists public.plan_items (
  id            uuid primary key,
  user_id       uuid not null references auth.users (id) on delete cascade,
  goal_id       uuid references public.study_goals (id) on delete set null,
  -- Lien avec le Kanban. Pas de contrainte de clé étrangère : une tâche peut
  -- être supprimée sans que l'étape du planning perde son sens.
  task_id       uuid,
  title         text not null,
  subject       text,
  start_date    timestamptz not null,
  end_date      timestamptz not null,
  progress      double precision not null default 0
                  check (progress between 0 and 1),
  is_milestone  boolean not null default false,
  -- Dépendance : `set null` pour ne jamais laisser pointer dans le vide.
  depends_on_id uuid references public.plan_items (id) on delete set null,
  created_at    timestamptz not null default now(),

  -- Une barre ne peut pas finir avant de commencer.
  constraint plan_items_date_order check (end_date >= start_date),
  -- Une étape ne dépend pas d'elle-même. Les cycles plus longs sont détectés
  -- côté client (GanttTimeline.wouldCreateCycle) : SQL ne sait pas le faire
  -- sans récursion coûteuse à chaque écriture.
  constraint plan_items_no_self_dependency check (depends_on_id <> id)
);

create index if not exists plan_items_user_start_idx
  on public.plan_items (user_id, start_date);

alter table public.plan_items enable row level security;

drop policy if exists "plan_items_all_own" on public.plan_items;
create policy "plan_items_all_own" on public.plan_items
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_study_goal(goal_id)
    and public.owns_plan_item(depends_on_id)
  );

-- ─── Mesures de vitesse ─────────────────────────────────────────────────────

create table if not exists public.speed_samples (
  id               uuid primary key,
  user_id          uuid not null references auth.users (id) on delete cascade,
  activity         text not null check (activity in
                     ('reading', 'writing', 'memorising', 'exercises')),
  subject          text,
  units            double precision not null check (units > 0),
  duration_seconds integer not null check (duration_seconds > 0),
  created_at       timestamptz not null default now()
);

create index if not exists speed_samples_user_activity_idx
  on public.speed_samples (user_id, activity, created_at desc);

alter table public.speed_samples enable row level security;

drop policy if exists "speed_samples_all_own" on public.speed_samples;
create policy "speed_samples_all_own" on public.speed_samples
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ─── Cibles d'examen (rentabilité de révision) ──────────────────────────────

create table if not exists public.exam_targets (
  id              uuid primary key,
  user_id         uuid not null references auth.users (id) on delete cascade,
  note_id         uuid references public.notes (id) on delete set null,
  title           text not null,
  subject         text,
  exam_weight     double precision not null default 0 check (exam_weight >= 0),
  current_grade   double precision not null default 0
                    check (current_grade between 0 and 20),
  reachable_grade double precision not null default 20
                    check (reachable_grade between 0 and 20),
  length_hours    double precision not null default 1 check (length_hours > 0),
  difficulty      smallint not null default 3 check (difficulty between 1 and 5),
  exam_date       timestamptz,
  created_at      timestamptz not null default now(),

  -- On ne peut pas viser moins bien que là où on est déjà.
  constraint exam_targets_reachable_above_current
    check (reachable_grade >= current_grade)
);

create index if not exists exam_targets_user_exam_idx
  on public.exam_targets (user_id, exam_date);

alter table public.exam_targets enable row level security;

drop policy if exists "exam_targets_all_own" on public.exam_targets;
create policy "exam_targets_all_own" on public.exam_targets
  for all using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and public.owns_note(note_id)
  );

-- ============================================================================
-- Lot 9 — Ambiance, bien-être & accessibilité
-- ============================================================================
-- Une colonne de plus sur la table créée au Lot 3, comme annoncé : thème,
-- taille de texte, ambiance sonore, raccourcis et routines matin/soir.
--
-- Stocké en jsonb plutôt qu'en colonnes typées : ces préférences évoluent à
-- chaque lot, et `UserSettings.fromJson` retombe sur les valeurs par défaut
-- pour toute clé inconnue ou absente.

alter table public.user_preferences
  add column if not exists settings jsonb not null default '{}'::jsonb;

-- ============================================================================
-- Horodatage serveur de updated_at
-- ============================================================================
-- Seules profiles, tasks et user_preferences avaient le trigger
-- set_updated_at : ailleurs, updated_at venait de l'horloge du client, et la
-- résolution de conflits des fiches comparait des horloges d'appareils
-- différents (un téléphone en avance d'une heure gagnait tous les conflits).
--
-- `before insert or update` : un upsert qui crée la ligne ne doit pas non
-- plus garder l'heure du client. Le client relit la valeur serveur après
-- chaque envoi (cf. LocalFirstNoteRepository).

drop trigger if exists notes_set_updated_at on public.notes;
create trigger notes_set_updated_at
  before insert or update on public.notes
  for each row execute function public.set_updated_at();

drop trigger if exists sq3r_sessions_set_updated_at on public.sq3r_sessions;
create trigger sq3r_sessions_set_updated_at
  before insert or update on public.sq3r_sessions
  for each row execute function public.set_updated_at();

drop trigger if exists learning_profiles_set_updated_at on public.learning_profiles;
create trigger learning_profiles_set_updated_at
  before insert or update on public.learning_profiles
  for each row execute function public.set_updated_at();
