-- ============================================================================
-- Historique des révisions synchronisé (review_logs)
-- ============================================================================
-- Un jugement par ligne, jamais modifié après coup (journal en ajout seul).
-- Synchronisé pour que le taux de rétention sur 30 jours suive l'utilisateur
-- d'un appareil à l'autre et survive à une déconnexion.

-- Propriété d'une carte référencée (anti-IDOR), comme owns_note.
create or replace function public.owns_flashcard(target uuid)
returns boolean
language plpgsql
stable
set search_path = public
as $$
begin
  return target is null or exists (
    select 1 from public.flashcards c
    where c.id = target and c.user_id = auth.uid()
  );
end;
$$;

create table if not exists public.review_logs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid()
                  references auth.users (id) on delete cascade,
  -- La suppression d'une carte emporte son historique, comme en local.
  card_id       uuid not null references public.flashcards (id) on delete cascade,
  grade         text not null check (grade in ('again', 'hard', 'good', 'easy')),
  interval_days integer not null check (interval_days >= 0),
  reviewed_at   timestamptz not null,
  updated_at    timestamptz not null default now()
);

create index if not exists review_logs_user_updated_idx
  on public.review_logs (user_id, updated_at);
create index if not exists review_logs_user_reviewed_idx
  on public.review_logs (user_id, reviewed_at);
create index if not exists review_logs_card_id_idx
  on public.review_logs (card_id);

alter table public.review_logs enable row level security;

drop policy if exists "review_logs_all_own" on public.review_logs;
create policy "review_logs_all_own" on public.review_logs
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id and public.owns_flashcard(card_id));

-- updated_at posé par le serveur : curseur du pull incrémental.
drop trigger if exists review_logs_set_updated_at on public.review_logs;
create trigger review_logs_set_updated_at
  before insert or update on public.review_logs
  for each row execute function public.set_updated_at();
