-- ============================================================================
-- Quiz génératifs : historique des réponses (quiz_attempts)
-- ============================================================================
-- Une réponse par ligne, jamais modifiée (journal en ajout seul). Synchronisé
-- pour que les titres flous et les priorités du jour suivent l'utilisateur
-- d'un appareil à l'autre. Pas de clé étrangère vers la fiche ou la carte :
-- une réponse garde sa valeur statistique après la suppression de sa source.

create table if not exists public.quiz_attempts (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  question_id text not null check (char_length(question_id) <= 200),
  kind        text not null
                check (kind in ('card', 'reverse', 'section', 'cloze', 'definition')),
  correct     boolean not null,
  answered_at timestamptz not null,
  note_id     uuid,
  card_id     uuid,
  heading     text check (heading is null or char_length(heading) <= 300),
  updated_at  timestamptz not null default now()
);

create index if not exists quiz_attempts_user_updated_idx
  on public.quiz_attempts (user_id, updated_at);
create index if not exists quiz_attempts_user_answered_idx
  on public.quiz_attempts (user_id, answered_at);

alter table public.quiz_attempts enable row level security;

drop policy if exists "quiz_attempts_all_own" on public.quiz_attempts;
create policy "quiz_attempts_all_own" on public.quiz_attempts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop trigger if exists quiz_attempts_set_updated_at on public.quiz_attempts;
create trigger quiz_attempts_set_updated_at
  before insert or update on public.quiz_attempts
  for each row execute function public.set_updated_at();
