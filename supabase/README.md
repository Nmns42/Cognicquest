# Base Supabase

- `migrations/` : historique versionné, à appliquer **dans l'ordre** des noms
  (`AAAAMMJJhhmmss_sujet.sql`, format de la CLI Supabase).
  - `20261023000000_baseline.sql` : schéma complet au 2026-10-23 (lots 1 à
    13, idempotent).
  - Chaque migration suivante est idempotente et ne touche qu'un sujet.
- `schema.sql` : instantané = concaténation exacte des migrations, pour
  monter une base neuve en un seul passage dans le SQL Editor.
  `test/core/database/supabase_migrations_test.dart` vérifie qu'il reste
  synchronisé.
- `tests/rls_checks.sql` : contrôles RLS à exécuter après chaque migration.

## Ajouter une migration

1. Créer `migrations/<horodatage>_<sujet>.sql` (idempotent : `if not exists`,
   `drop … if exists` avant `create`).
2. L'ajouter à la fin de `schema.sql`, précédée d'une ligne vide.
3. Appliquer : `supabase db push` (CLI liée au projet) ou coller le fichier
   dans le SQL Editor.

## Réglages du tableau de bord (non versionnés)

Authentication > URL Configuration > Redirect URLs :
- `https://nmns42.github.io/Cognicquest/`
- `io.cognicquest.app://login-callback/` (Android, iOS)
- `http://127.0.0.1:43823/auth/callback` (Windows, Linux)
