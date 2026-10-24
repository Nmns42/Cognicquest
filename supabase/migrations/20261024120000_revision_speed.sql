-- ============================================================================
-- Ordre de révision & vitesse de travail fusionnés
-- ============================================================================
-- Chapitres : longueur en pages (convertie en temps par la vitesse de lecture
-- mesurée) ; coefficient libre, sans borne haute (exam_weight >= 0 suffit).
-- Mesures de vitesse : unité choisie (pages, paragraphes, phrases, mots,
-- cartes, fiches, quiz, questions, exercices).

alter table public.exam_targets
  add column if not exists length_pages double precision
    check (length_pages is null or length_pages > 0);

alter table public.speed_samples
  add column if not exists unit text
    check (unit is null or unit in ('pages', 'paragraphes', 'phrases', 'mots',
      'cartes', 'fiches', 'quiz', 'questions', 'exercices'));
