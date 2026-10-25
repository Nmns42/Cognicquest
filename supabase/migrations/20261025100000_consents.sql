-- ============================================================================
-- RGPD : preuve du consentement (consents)
-- ============================================================================
-- Une ligne par décision (bandeau de première ouverture, activation ou
-- retrait dans Réglages > Confidentialité), jamais modifiée ni effacée par
-- le client : c'est la preuve exigée par l'art. 7.1 du RGPD. Supprimée avec
-- le compte (cascade). `version` = `LegalInfo.consentVersion`.

create table if not exists public.consents (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  version     integer not null check (version > 0),
  wellbeing   boolean not null,
  decided_at  timestamptz not null,
  created_at  timestamptz not null default now()
);

create index if not exists consents_user_decided_idx
  on public.consents (user_id, decided_at desc);

alter table public.consents enable row level security;

-- Ajout et lecture seuls : ni update ni delete pour le client.
drop policy if exists "consents_select_own" on public.consents;
create policy "consents_select_own" on public.consents
  for select using (auth.uid() = user_id);

drop policy if exists "consents_insert_own" on public.consents;
create policy "consents_insert_own" on public.consents
  for insert with check (auth.uid() = user_id);
