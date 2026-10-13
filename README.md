# CognicQuest

Application d'apprentissage fondée sur la métacognition : fiches, révision
espacée, Pomodoro, Kanban et matrice d'Eisenhower, habitudes, journal
métacognitif et planification.

Version web : https://nmns42.github.io/Cognicquest/

## Pile technique

| Couche | Outil |
|---|---|
| Interface | Flutter (web, Android, iOS, desktop) |
| État | Riverpod 2 |
| Navigation | go_router |
| Base locale | Drift / SQLite (`sqlite3.wasm` sur le web) |
| Serveur | Supabase : authentification, Postgres avec RLS |

L'app est **local-first** : chaque écriture part d'abord dans SQLite, puis
une file (`lib/core/database/sync_queue.dart`) l'envoie à Supabase dès que le
réseau le permet. Tout fonctionne hors ligne.

## Démarrer

1. Copier `env.example.json` en `env.json` et y mettre l'URL et la clé
   publique (anon) du projet Supabase. `env.json` n'est jamais versionné.
2. Créer le schéma : exécuter `supabase/schema.sql` dans le SQL Editor
   Supabase, puis vérifier la RLS avec `supabase/tests/rls_checks.sql`.
3. Lancer :

```sh
flutter pub get
flutter run -d chrome --web-port 3000 --dart-define-from-file=env.json
```

Mode démo sans compte (données fictives, rien n'est envoyé au serveur) :
ajouter `--dart-define=DEV_BYPASS_AUTH=true` (debug uniquement).

## Vérifier

```sh
flutter analyze
flutter test
```

Après une modification des tables Drift :
`dart run build_runner build --delete-conflicting-outputs`.

## Déploiement

Chaque push sur `master` construit la version web et la publie sur GitHub
Pages (`.github/workflows/deploy.yml`). Les secrets `SUPABASE_URL` et
`SUPABASE_ANON_KEY` sont lus dans les secrets du dépôt.

## Structure

```
lib/
  core/       base locale, synchronisation, thème, navigation, configuration
  features/   un dossier par module (auth, notes, review, kanban, habits…)
              avec data/ (repositories), providers/, views/, widgets/
  router/     routes et garde d'authentification
  shared/     modèles communs
supabase/     schéma SQL et vérification RLS
```
