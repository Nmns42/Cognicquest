# Contexte projet — CogniQuest

Source unique de contexte pour les assistants IA (Claude Code, Gemini) et pour
le développeur. **À mettre à jour à la fin de chaque chantier** (sections
« État des chantiers » et « Prochaines étapes »).

Dernière mise à jour : 2026-10-23

---

## 1. Le produit

Application d'apprentissage fondée sur la métacognition (cahier des charges :
`Cognicquest_.pdf`, 22 pages, racine du dépôt). Interface en français.

Modules : fiches (éditeur par blocs, menu « / », liens `[[Titre]]`,
explorateur de dossiers), révision (flashcards SM-2 / échelle J, SQ3R,
« Explique-moi »), graphe de connaissances, Pomodoro, Kanban + matrice
d'Eisenhower, habitudes (quotidiennes / hebdomadaires / mensuelles), journal
métacognitif, cahier d'erreurs, profilage, objectifs SMART, Gantt, ordre de
révision par coefficients, tableau de bord.

## 2. Stack

| Couche | Technologie |
|---|---|
| UI | Flutter (Dart `>=3.6`), Material |
| État | Riverpod 2 |
| Navigation | go_router 14 (garde d'auth réactive) |
| Base locale | Drift / SQLite (web : `sqlite3.wasm` + `drift_worker.js` dans `web/`) |
| Distant | Supabase (auth e-mail + Google, tables avec RLS, `supabase/schema.sql`) |
| CI / déploiement | GitHub Actions → GitHub Pages (`.github/workflows/deploy.yml`) |

## 3. Architecture

```
lib/
  core/       config, database (Drift + SyncQueue), errors, motion,
              navigation, ordering, theme (tokens), ui (composants)
  features/   un dossier par module : views/ widgets/ providers/ data/ domain/
  router/     app_router.dart
  shared/     models/
test/         miroir de lib/ + e2e/ + garde-fous
```

- **Local-first** : Drift est la source de vérité ; les écritures passent par
  une file (`lib/core/database/sync_queue.dart`). `SyncCoordinator`
  (`lib/features/sync/`) resynchronise au lancement, à la reprise, en backoff
  et toutes les 5 min. Règle de pull : ne jamais écraser un id qui a une
  écriture en attente.
- **Repositories** : seul `auth_provider.dart` appelle Supabase directement.
- **Schéma Drift** : version 13, migrations incrémentales dans
  `lib/core/database/app_database.dart`.

## 4. Conventions obligatoires

- **Design tokens** : aucune couleur `Color(0x…)`, `Colors.white/black` ni
  `fontSize` en dur hors de `lib/core/theme/`. Utiliser `context.cq`,
  `Space.*`, `Radii.*`, `TypeScale.*`. Vérifié par
  `test/core/theme/design_tokens_guard_test.dart` (plafonds qui ne font que
  baisser).
- **Animations** : toute animation implicite passe par
  `Motion.duration(context, …)` (`test/features/motion/motion_inventory_test.dart`).
- **Thèmes** : clair + sombre uniquement, contrastes ≥ 4,5:1. Direction
  « SaaS pro / EdTech éditorial » (Notion, Craft, Linear) : fond parchemin
  #FAF8F5, cartes blanches (filet #E6E2D8, ombre 8/2/3 %, `Radii.card` 12),
  tuiles pierre `sauge` #EFECE4. Vert forêt #083B32 réservé aux boutons
  d'action et à la barre active (4 px) de la navigation ; sauge `vertSauge`
  #3D6A53 pour badges pilules et cases cochées (carrées, `Radii.xs` 4) ;
  écorce `terre` #7C4D25 pour la date, les puces et le tronc.
- **Typographie** : titres et logo en serif **Fraunces** (embarquée, pas de google_fonts : hors ligne) (w500, crénage
  −0,5, `appSerifFamily`), corps en Plus Jakarta Sans ; compteurs en
  chiffres tabulaires (`TypeScale.tabular`). Les tests qui mesurent du texte
  chargent les deux polices depuis `assets/fonts/`.
- **Motifs végétaux** : `lib/core/ui/botanical_decorations.dart`
  (filigranes du fond — quasi invisibles, opacité 2 % —, feuillage,
  laurier, arbre compagnon), teintes dans `lib/core/theme/botanical_palette.dart`. Décors
  exclus de l'accessibilité, aucune couleur en dur hors thème.
- **Boutons** : `CqButton.primary` / `.secondary` sont des boutons en relief
  (`CqPressableButton`, lèvre de `Press.depth`, action au relâcher).
- **Police** : Plus Jakarta Sans embarquée (`assets/fonts/`).
- Commentaires en français ; ne jamais lancer `dart format` sur tout le dépôt.

## 5. Zones verrouillées (ne pas modifier)

- `lib/features/metacognition/views/error_logs_page.dart`
- `lib/features/metacognition/views/profiling_page.dart`
- `lib/features/metacognition/domain/learning_profile.dart`

## 6. Commandes

| But | Commande |
|---|---|
| Analyse statique | `flutter analyze` |
| Tests (sans goldens) | `flutter test --exclude-tags golden` |
| Goldens (Windows uniquement) | `flutter test --tags golden` |
| Recette de bout en bout | `flutter test --dart-define=DEV_BYPASS_AUTH=true test/e2e` |
| Lancer en mode démo | `flutter run --dart-define=DEV_BYPASS_AUTH=true` |
| Régénérer Drift | `dart run build_runner build` |

La CI (Linux) exécute `flutter analyze`, `flutter test --exclude-tags golden`
puis la recette e2e avant chaque build web ; un échec bloque le déploiement.

Pièges multi-plateformes : les tests qui mesurent du texte doivent charger
la police de l'app depuis `assets/fonts/` (sinon police « Ahem », faux
débordements) ; la disposition du graphe dépend de cos/sin, qui diffèrent
entre Windows et Linux (comparer des déplacements relatifs, pas des
positions absolues).

## 7. État des chantiers

| Date | Chantier | État |
|---|---|---|
| 2026-10-06 | Lot 10 — hors ligne (tâches, habitudes, Pomodoro local-first) | Fait |
| 2026-10-13 | Refonte UI « zen » — tokens, garde-fous, nav à 4 espaces | Fait (phase 4 écran par écran en continu) |
| 2026-10-15 | Agents 1-6 : design system, Pomodoro auto-switch, habitudes par fréquence, explorateur + éditeur Notion, SQ3R/graphe, coefficients + recadrage | Commité |
| 2026-10-15 | Bloc vidéo dans `note_blocks` (schéma) | Commité |
| 2026-10-23 | Audit + filet CI (analyze + tests + e2e avant déploiement) | Fait, CI verte sous Linux |
| 2026-10-23 | Éditeur : enregistrement à la fermeture (`deactivate`, plus de `ref` dans `dispose`) | Fait |
| 2026-10-23 | Refonte « Duolingo & végétal » — étape 1 : tokens (palette, `Press`, `Radii.button/card`, `CqMotion.press`), `CqPressableButton`, délégation de `CqButton` | Fait ; écrans à reprendre un par un |
| 2026-10-23 | Cartes Habitudes / Pomodoro / Tableau de bord (`Radii.card`, sauge, pastille de série ambre, terre) puis accent vert forêt #083B32 | Fait |
| 2026-10-23 | Palette adoucie d'après la maquette Habitudes (vert sauge forêt, olive, sable), badges pastille / cercle, case ronde | Fait |
| 2026-10-23 | Direction « Botanique » : palette forêt / sauge / écorce / parchemin, motifs vectoriels, Habitudes (bannière bi-ton, grille ≥ 900 px, panneau « Arbre de détente »), fond du Shell | Fait |
| 2026-10-23 | Tableau de bord botanique : bannière d'accueil bi-ton, pastilles rondes sauge / écorce, panneau « Arbre de détente » ≥ 900 px ; composants communs `lib/core/ui/botanical_hero.dart` | Remplacé |
| 2026-10-23 | Pivot « SaaS pro / éditorial » : serif + chiffres tabulaires, palette minéral & papier, navigation à barre active, Tableau de bord « bento » (`dashboard_bento.dart`) | Fait |
| 2026-10-23 | Fraunces, fond #FAF8F5, vert forêt réservé aux actions et à la barre active (sélections en aplat pierre, jauges / coches en sauge, échéances en écorce), carte Révisions blanche | Fait |
| 2026-10-23 | Écrans de la maquette SVG : Pomodoro (minuteur Fraunces fin, anneau fin, tuiles compactes), Fiches (liste dense façon Notion, recherche blanche, badges sauge / écorce), Révisions (carte « Réviser » compacte, charge sur tuile pierre, lignes denses), Graphe (fond parchemin `cq.parchemin`, tracés filaires sauge / écorce, nœuds à taille minimale d'écran, titres des carrefours à taille d'écran), Kanban (colonnes pierre à filet, cartes blanches ombrées, puces écorce / sauge, « Urgent » plein écorce), Planification (bandeau d'échéance parchemin plat, lignes d'outils blanches à filet, icônes et chevrons sauge), Journal (rétrospective crème + bouton sauge, état du moment en carte blanche à puce, outils en lignes blanches, arbre de croissance), Réglages (cartes radio, sélecteur de taille sur piste pierre, Pomodoro en carte à filets, touches KBD parchemin, zone sensible écorce) | Fait : les 10 écrans de la maquette sont repris |
| 2026-10-23 | Taux de rétention (Révisions) : révisions retrouvées (« Difficile », « Correct », « Facile ») / total, sur 30 jours glissants, significatif dès 10 révisions (`RetentionStats`, `retentionProvider`) ; barre latérale : indicateur actuel conservé (pas de réécriture du `NavigationRail`) | Fait |
| 2026-10-24 | P1-Sync : table `review_logs` (RLS `owns_flashcard`, trigger `updated_at`, migration `supabase/migrations/20261024090000_review_logs.sql`) ; chaque jugement est mis en file et poussé après sa carte, puis rapatrié au pull (curseur incrémental, insertion idempotente) : la rétention suit l'utilisateur d'un appareil à l'autre | Fait |
| 2026-10-24 | P1-Conflits : contrôle de version optimiste sur `notes`, `flashcards`, `tasks`. Drift v14 `SyncRowVersions` garde la version serveur de base de chaque ligne (`SyncVersions`), envoyée en `updated_at` ; trigger `reject_stale_write` (code 40001, migration `20261024100000_optimistic_concurrency.sql`). Refus : la version serveur gagne (curseur relu) ; pour une fiche, la version de l'appareil est conservée en copie « (version de cet appareil) ». Sync des révisions sérialisée (`SerialSync`) | Fait |
| 2026-10-24 | P1-Storage : images des fiches et des cartes déposées dans le bucket privé `user_media` (RLS par dossier `auth.uid()`, 5 Mo, PNG / JPEG / GIF / WebP ; migration `20261024110000_user_media.sql`). Le texte ne garde que `media://<uid>/<fichier>` ; `MediaStore` (`lib/core/media/`) : cache local Drift v15 `LocalMediaCache`, envoi en file `user_media` (premier module du `SyncCoordinator`), téléchargement à la demande. `MediaImage` (`lib/core/ui/media_image.dart`) lit les trois formats ; les anciennes images base64 restent affichées | Fait |
| 2026-10-24 | P1-Migrations & Auth : `supabase/migrations/` (baseline + incrémentales, format CLI), `schema.sql` = leur concaténation (test `supabase_migrations_test.dart`), `supabase/README.md`. Test de montée Drift v1 → courante comparé à une installation neuve (`migration_full_test.dart`) : a révélé l'index `local_folders_user_parent` absent depuis v13, recréé au palier v15. Google sur Windows / Linux : retour PKCE par serveur local `http://127.0.0.1:43823/auth/callback` (`LoopbackOAuthReceiver`, à autoriser dans Supabase) | Fait |
| 2026-10-24 | P0/P1 Web, CSP, SEO & RGPD : `web/index.html` (CSP stricte en `<meta>`, `apple-mobile-web-app-capable`, title / description / Open Graph / Twitter / JSON-LD `SoftwareApplication`, canonical), `web/robots.txt`, `web/sitemap.xml`. Feature `legal/` : Politique de confidentialité et Mentions légales (`/legal/privacy`, `/legal/notice`, ouvertes sans connexion), bandeau de consentement à la première ouverture (`ConsentGate`, accord explicite aux données de bien-être, mémorisé par `shared_preferences`, retirable dans Réglages > Confidentialité). Suppression du compte : images Storage purgées avant le RPC. **Identité de l'éditeur à compléter** dans `legal_info.dart` (champs entre crochets) | Fait (textes à faire relire) |
| 2026-10-24 | P0 Logo, PWA & Rappels : logo A « Arbre-Neurone » affiné (houppier à lobes, synapses courbes) — `CqLogoPainter` (`lib/core/ui/cq_logo.dart`, couleurs du thème clair / sombre, `LogoPalette` dans `lib/core/theme/`) dans l'en-tête du rail ; SVG `assets/logo/cognicquest-logo*.svg` ; toutes les icônes générées depuis le painter (`flutter test --tags tool tool/generate_icons_test.dart` : favicon, PWA 192/512 + maskables fond #083B32, apple-touch-icon, mipmaps Android, AppIcon iOS, `app_icon.ico`). `manifest.json` (theme #FAF8F5, fond #083B32). Hors ligne : build `--no-web-resources-cdn`, `flutter_bootstrap.js` sans le SW Flutter, `cq_service_worker.js` (réseau d'abord pour la navigation, cache d'abord pour l'app) complété en CI par `tool/generate_service_worker.dart` (pré-cache ~24 Mo, version = empreinte). Rappels : `ReminderService` (`flutter_local_notifications`, fuseau via `flutter_timezone`) — fin de phase Pomodoro et rappel quotidien planifié (web : tant que l'onglet est ouvert), Réglages > Rappels ; Android : desugaring + récepteurs | Fait (hors ligne et notifications à vérifier sur appareil) |
| 2026-10-24 | Pomodoro — saisie libre : compteurs +/- remplacés par `PomodoroDurationsForm` / `WholeNumberField` (`lib/features/pomodoro/widgets/`), partagé Réglages + feuille « Régler le Pomodoro » sur l'écran du minuteur ; décimales `1,2` / `1.6` arrondies (`parseWholeNumber`), bornes élargies (focus 1–180, pauses 1–60 / 1–120, 1–12 sessions) avec message « Ramené à… » ; progression exacte « 2 / 3 » sous le minuteur | Fait |

Mesures au 2026-10-23 : ~36 k lignes Dart (hors généré), 667 tests verts,
`flutter analyze` sans problème.

## 8. Dette connue / prochaines étapes

1. Découper les fichiers géants : `notes/widgets/folder_explorer.dart`
   (1 333 l.), `kanban/views/kanban_page.dart` (1 025 l.).
2. Tests widget pour kanban, habits, planning, review (1 fichier chacun).
3. Sortir les migrations Drift dans un fichier dédié.
4. Backlog technique détaillé : `docs/backlog.md` (graphe à grande échelle…).

Manques fonctionnels vs cahier des charges : gamification avancée,
notifications/rappels, export PDF/CSV, collaboration temps réel, IA,
blocage de sites, monétisation.
