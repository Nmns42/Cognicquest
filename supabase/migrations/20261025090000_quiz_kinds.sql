-- ============================================================================
-- Quiz : nouveaux types de questions (lots 1 à 3 des extracteurs)
-- ============================================================================
-- La contrainte d'origine n'acceptait que les cinq premiers types : les
-- réponses aux questions « valeur chiffrée », « intrus », « tableau »,
-- « cause → effet » et « encadré » étaient refusées à l'envoi (mises de côté
-- par la file, renvoyées au lancement suivant une fois la migration passée).
-- Doit rester alignée sur `QuizKind` (lib/features/quiz/domain/quiz_generator.dart).

alter table public.quiz_attempts
  drop constraint if exists quiz_attempts_kind_check;
alter table public.quiz_attempts
  add constraint quiz_attempts_kind_check check (kind in (
    'card', 'reverse', 'section', 'cloze', 'definition',
    'numeric', 'intruder', 'table', 'causal', 'callout'
  ));
