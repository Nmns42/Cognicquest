# AUDIT_PLAN — CognicQuest

Cahier des charges opérationnel destiné à **Claude Code** (exécution tâche par tâche dans le terminal). **Ne pas fusionner les phases. Une tâche à la fois. Ne pas commencer la Phase 2 tant que la Phase 1 n’est pas verte. Ne pas commencer la Phase 3 tant que la Phase 2 n’est pas verte.**

Date d’audit : 2026-10-08  
Projet : Flutter 3.x / Dart `>=3.6.0 <4.0.0` — `C:\Users\trois\Desktop\Cognicquest`  
Cahier des charges produit : `Cognicquest_.pdf` (22 pages, racine du dépôt)

---

## 0. Constat d’architecte (ne pas modifier ce diagnostic)

### Architecture & structure

CognicQuest est une **application Flutter unique** (pas un monorepo front/back). La séparation réelle est :

| Couche | Emplacement | Rôle |
|---|---|---|
| UI | `lib/features/*/views`, `widgets` | Pages Material + coquille adaptative |
| État | `lib/features/*/providers` | Riverpod 2.6 |
| Domaine | `lib/features/*/domain`, `lib/shared/models` | Règles pures (SM-2, graphe, Gantt) |
| Persistance locale | `lib/core/database` (Drift v6) | Source de vérité hors ligne |
| Distant | `supabase/schema.sql` + repos `*_repository.dart` | Miroir + auth |
| Navigation | `lib/router/app_router.dart` | go_router 14 + garde d’auth |

Points forts : feature-first clair, local-first (Lots 4–8 + 10), RLS sur presque toutes les tables, tests Drift/migrations, sync sérialisée + backoff.

Points faibles : **pas de backend applicatif** (pas d’Edge Functions, pas de migrations Supabase versionnées, un seul `schema.sql` monolithique). Dashboard layout et réglages sont encore **100 % serveur**. `graphview` est une dépendance morte (layout maison). README encore le template Flutter. Fichiers dump (`tout_le_code.txt`, `cognicquest_lib_dump.txt`) dans le dépôt.

### Dette technique & sécurité

| Gravité | Constat |
|---|---|
| P0 | `android/app/src/main/AndroidManifest.xml` : **pas d’intent-filter MAIN/LAUNCHER**. L’app Android n’apparaît pas sur le lanceur. Filtres OAuth dupliqués. |
| P0 | **Pas de `INTERNET` dans le manifeste principal** (seulement `debug`/`profile`). Un APK **release** ne peut pas joindre Supabase. |
| P0 | **macOS Release** (`macos/Runner/Release.entitlements`) : sandbox sans `network.client`. Build release macOS coupé du réseau. DebugProfile a `network.server` mais **pas** `network.client`. |
| P0 | RLS `profiles_update_own` : l’utilisateur peut **s’écrire `plan = 'premium'`** via l’anon key. La monétisation est contournable tant que cette politique existe. |
| P0 | `lib/core/config/app_config.dart` embarque en dur l’URL et la clé publishable du projet Supabase de dev. Tout binaire (même sans `env.json`) cible ce projet. |
| P1 | `DEV_BYPASS_AUTH` **true par défaut** en debug (verrouillé par `kDebugMode` donc OK en release, mais masque les bugs d’auth au quotidien). |
| P1 | `ios/Runner/Info.plist` : `CFBundleURLTypes` **répété 3 fois**. `applicationId` = `com.example.cognicquest`. Signing release = clés debug. |
| P1 | Mot de passe min = 6. UUID v4 via `dart:math` `Random()` (pas `Random.secure()`). Redirection post-login via query `from` non whitelistée. |
| P2 | `flutter_lints: ^3.0.1` (lock 3.0.2). Pas de CI. `graphview` inutilisé. Sons d’ambiance : `assets/sounds/.gitkeep` vide. |

### Performance & multiplateforme

- Web : Drift + `web/sqlite3.wasm` + `web/drift_worker.js` (OK, à garder alignés sur Drift 2.35). PWA encore template (`orientation: portrait-primary` casse le desktop). `index.html` / `manifest.json` génériques.
- Graphe : Fruchterman-Reingold **300 itérations sur le thread UI** (`lib/features/graph/domain/graph_layout.dart`) — bloquant dès quelques dizaines de nœuds (le seed démo dense aggrave).
- `note_repository.watchAll()` charge **tous les blocs de toutes les fiches** à chaque émission.
- Réglages / layout dashboard : flash de thème par défaut puis fetch réseau ; indisponibles hors ligne.
- Coins Pomodoro : dérivés en mémoire / stats, **pas une économie persistée**.
- Quotas CdC `maxFreeFlashcardsPerDay` / `maxFreeLinksPerDay` : **déclarés, jamais appliqués**.

### Auth & monétisation

**Auth (avancé, pas production-ready)** : email/mdp, inscription, reset, Google OAuth PKCE, messages FR, garde go_router, trigger `handle_new_user`. Deep links Android/iOS présents mais sales (doublons). Pas de page de reset réelle (deep link seulement). Pas de suppression de compte.

**Paiements : 0 %**. Aucune dépendance `stripe`, `purchases_flutter`, `in_app_purchase`. Colonne `profiles.plan` (`free` / `premium` / `pro`) + enum Dart `UserPlan` seulement. Aucun gating UI. Aucun webhook. Aucun paywall.

Modèle économique du CdC à implémenter en Phase 3 : freemium B2C (Premium) + abonnement Pro B2B, quotas flashcards/liens, pièces. **Stripe = web/desktop. RevenueCat = iOS/Android.** Le plan ne doit **jamais** être écrit par le client.

---

## Mode d’emploi Claude Code

Pour chaque tâche ci-dessous, coller **uniquement** le bloc `Prompt Claude Code`. Après exécution, lancer les **critères de vérification**. Si un critère échoue : corriger **dans la même tâche**, ne pas passer à la suivante.

Commandes globales à connaître :

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build web --no-tree-shake-icons
```

Ne pas committer `env.json`. Ne pas logger de secrets. Ne pas activer le bypass auth en release.

---

# Phase 1 — Correctifs critiques

Objectif : l’app se lance, parle au réseau, n’expose plus le plan, n’embarque plus le projet Supabase de dev par défaut.

---

## Tâche 1.1 — Android : lanceur + INTERNET + OAuth unique

**Fichiers**

- Modifier : `android/app/src/main/AndroidManifest.xml`
- Modifier : `android/app/build.gradle.kts` (applicationId uniquement si déjà décidé : laisser `com.example.cognicquest` ici, le rebranding est 2.8)

**Prompt Claude Code**

```
Tu travailles dans le dépôt Flutter CognicQuest. Ne touche qu’à android/app/src/main/AndroidManifest.xml.

Problème : le manifeste principal n’a PLUS l’intent-filter MAIN/LAUNCHER (remplacé par deux filtres OAuth identiques). L’app n’apparaît pas dans le lanceur. INTERNET n’est déclaré que dans android/app/src/debug et profile : un build release ne peut pas appeler Supabase.

Fais exactement ceci dans android/app/src/main/AndroidManifest.xml :
1. Ajoute <uses-permission android:name="android.permission.INTERNET"/> au niveau <manifest>, avant <application>.
2. Dans l’activity MainActivity, restaure UN intent-filter de lancement Flutter standard :
   - action MAIN
   - category LAUNCHER
3. Conserve UN SEUL intent-filter OAuth (supprime le doublon) :
   - action VIEW
   - categories DEFAULT + BROWSABLE
   - data android:scheme="io.cognicquest.app" android:host="login-callback"
4. Ne change pas le nom du package, le theme, ni flutterEmbedding.

Ne modifie aucun autre fichier. Vérifie en relisant le XML : MainActivity doit avoir exactement deux intent-filter (LAUNCHER + OAuth).
```

**Vérification**

```bash
# Le manifeste principal contient MAIN, LAUNCHER et INTERNET, et un seul host login-callback
python -c "p=open('android/app/src/main/AndroidManifest.xml',encoding='utf-8').read(); assert 'android.intent.action.MAIN' in p; assert 'android.intent.category.LAUNCHER' in p; assert 'android.permission.INTERNET' in p; assert p.count('login-callback')==1; print('OK 1.1')"
flutter analyze
```

---

## Tâche 1.2 — iOS : un seul CFBundleURLTypes

**Fichiers**

- Modifier : `ios/Runner/Info.plist`

**Prompt Claude Code**

```
Dans CognicQuest, ouvre ios/Runner/Info.plist. La clé CFBundleURLTypes est répétée trois fois avec le même schéma io.cognicquest.app. Un plist Apple ne doit déclarer chaque clé qu’une fois (la dernière gagne, les doublons sont une dette et un risque Xcode).

Garde tout le reste du plist intact (scènes, orientations, bundle). Remplace les trois blocs CFBundleURLTypes par UN seul :

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.cognicquest.app</string>
    </array>
    <key>CFBundleURLName</key>
    <string>login-callback</string>
  </dict>
</array>

Ne touche pas android/, macos/, ni le Dart. Vérifie qu’il n’existe plus qu’une occurrence de la chaîne CFBundleURLTypes.
```

**Vérification**

```bash
python -c "p=open('ios/Runner/Info.plist',encoding='utf-8').read(); assert p.count('<key>CFBundleURLTypes</key>')==1; assert 'io.cognicquest.app' in p; print('OK 1.2')"
```

---

## Tâche 1.3 — macOS : entitlement réseau client

**Fichiers**

- Modifier : `macos/Runner/DebugProfile.entitlements`
- Modifier : `macos/Runner/Release.entitlements`

**Prompt Claude Code**

```
CognicQuest est sandboxé sur macOS. DebugProfile.entitlements a com.apple.security.network.server mais PAS network.client. Release.entitlements n’a que app-sandbox. Un build macOS ne peut donc pas faire d’HTTPS vers Supabase.

Ajoute dans LES DEUX fichiers, à l’intérieur du dict, sans retirer les clés existantes :

<key>com.apple.security.network.client</key>
<true/>

Laisse allow-jit et network.server sur DebugProfile. Ne touche pas aux autres plateformes.
```

**Vérification**

```bash
python -c "
for f in ['macos/Runner/DebugProfile.entitlements','macos/Runner/Release.entitlements']:
    t=open(f,encoding='utf-8').read();
    assert 'com.apple.security.network.client' in t, f
print('OK 1.3')"
```

---

## Tâche 1.4 — Secrets : plus de défauts Supabase compilés

**Fichiers**

- Modifier : `lib/core/config/app_config.dart`
- Modifier : `lib/main.dart`
- Modifier : `env.example.json` (commentaire d’usage seulement si besoin)
- Créer : `test/core/config/app_config_test.dart` (si absent)

**Prompt Claude Code**

```
Sécurité : lib/core/config/app_config.dart compile en dur
  SUPABASE_URL defaultValue: https://lnsncmsxpshqokwchxls.supabase.co
  SUPABASE_ANON_KEY defaultValue: sb_publishable_h6Gn0x_pSZy_LuNMJ8f9Tw_CCYjKhVN
Tout binaire sans --dart-define-from-file=env.json cible donc le projet de dev.

Fais ceci, rien d’autre :
1. Dans AppConfig, defaultValue de supabaseUrl, supabaseAnonKey et oauthRedirectUrl = chaîne VIDE ('').
2. Garde isSupabaseConfigured = url non vide ET anon key non vide.
3. DEV_BYPASS_AUTH : change defaultValue du flag à false. Conserve `static bool get devBypassAuth => kDebugMode && _devBypassAuthFlag;` (impossible en release).
4. Dans main.dart : si !AppConfig.devBypassAuth && !AppConfig.isSupabaseConfigured, n’appelle PAS Supabase.initialize. Affiche _StartupErrorApp avec un message clair : il faut fournir env.json (modèle env.example.json) via --dart-define-from-file=env.json. Si devBypassAuth est true, l’app peut démarrer sans Supabase (ne pas appeler initialize, ou l’appeler seulement si configuré).
5. Ne commite aucun env.json. Ne réécris pas la clé réelle nulle part (tests, README, commentaires).
6. Adapte test/features/auth/auth_failure_test.dart : le groupe AppConfig.devBypassAuth s’attend aujourd’hui à isTrue par défaut. Le défaut devient false ; le test doit refléter le nouveau contrat (en debug sans dart-define, bypass = false). Si d’autres tests cassent uniquement à cause de ce défaut, corrige les attentes, pas la sémantique.

Vérifie : aucune occurrence de lnsncmsxpshqokwchxls ni de sb_publishable_h6Gn0x dans lib/ et test/.
```

**Vérification**

```bash
python -c "
import pathlib
bad=0
for p in pathlib.Path('.').rglob('*'):
    if p.suffix not in {'.dart','.md','.json','.txt'} or 'AUDIT_PLAN' in p.name: continue
    try: t=p.read_text(encoding='utf-8')
    except: continue
    if 'lnsncmsxpshqokwchxls' in t or 'sb_publishable_h6Gn0x' in t:
        print('LEAK', p); bad+=1
print('leaks', bad)
assert bad==0
"
flutter test test/features/auth/auth_failure_test.dart
flutter analyze
```

---

## Tâche 1.5 — RLS : l’utilisateur ne peut plus s’auto-promouvoir

**Fichiers**

- Modifier : `supabase/schema.sql`
- Créer : `supabase/migrations/20261008_lock_profiles_plan.sql` (patch rejouable, à coller aussi dans le SQL Editor)

**Prompt Claude Code**

```
Faille P0 monétisation : dans supabase/schema.sql, la policy profiles_update_own autorise UPDATE de TOUTES les colonnes de public.profiles pour auth.uid() = id. Un client avec la clé anon peut PATCH {plan:'premium'}.

Corrige le schéma de façon idempotente :

1. Ajoute à la fin de supabase/schema.sql (et crée supabase/migrations/20261008_lock_profiles_plan.sql avec le même SQL) :

-- Empêche l’auto-promotion. Seul le service_role (webhooks Stripe/RevenueCat) écrit `plan`.
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Colonne plan : les rôles authentifiés ne peuvent plus la modifier.
revoke update on public.profiles from authenticated;
grant update (full_name, avatar_url, updated_at) on public.profiles to authenticated;

Alternative PostgreSQL plus robuste si GRANT column-level pose problème avec PostgREST : crée un trigger BEFORE UPDATE qui force NEW.plan = OLD.plan sauf si current_user IN ('service_role', 'postgres', 'supabase_admin'). Utilise cette alternative trigger SI le GRANT column-level casse l’update du nom via le client Dart existant (profile_repository.updateName n’envoie que full_name — il doit continuer à marcher).

2. Ne change pas le code Dart de ProfileRepository (il n’envoie déjà pas `plan` dans toJson).
3. Commente clairement : « plan est écrit uniquement par webhook / service_role ».

N’ajoute pas Stripe dans cette tâche.
```

**Vérification**

```bash
python -c "
t=open('supabase/schema.sql',encoding='utf-8').read()
assert 'plan' in t
assert 'service_role' in t.lower() or 'NEW.plan' in t or 'grant update (full_name' in t.lower()
print('OK 1.5 — relire le SQL puis l’exécuter dans le SQL Editor Supabase')
"
```

Critère manuel obligatoire : coller le fichier de migration dans le SQL Editor du projet Supabase et l’exécuter. Puis, connecté en anon, tenter `update profiles set plan='premium'` — doit échouer.

---

## Tâche 1.6 — Redirection post-login whitelistée

**Fichiers**

- Modifier : `lib/router/app_router.dart`
- Modifier : `lib/features/auth/views/login_page.dart`
- Créer : `test/features/auth/login_redirect_test.dart`

**Prompt Claude Code**

```
Dans login_page.dart, après succès, context.go(widget.redirectTo!) utilise le query param `from` sans validation. Un lien /login?from=https://evil.example peut sortir du graphe d’app ou viser une route interne inattendue.

1. Ajoute dans AppRoute une méthode statique `bool isInternalRedirect(String? path)` :
   - null/vide → false
   - doit commencer par `/`
   - ne doit PAS commencer par `//`
   - ne doit PAS contenir `://`
   - doit matcher une route connue (préfixe d’une des constantes AppRoute, ou être login/register/forgot uniquement refusé : on redirige vers /home dans ce cas)
2. Dans le redirect de GoRouter, n’encode `from` que si isInternalRedirect(from).
3. Dans LoginPage, n’appelle context.go(redirectTo) que si isInternalRedirect(redirectTo) ; sinon context.go(AppRoute.home).
4. Teste les cas : '/notes', '/planning/gantt', '/login', '//evil', 'https://x', 'notes', null.

Pas d’autre changement UI.
```

**Vérification**

```bash
flutter test test/features/auth/login_redirect_test.dart
flutter analyze
```

---

## Tâche 1.7 — UUID cryptographiques + mot de passe min 8

**Fichiers**

- Modifier : `lib/core/config/app_config.dart` (`minPasswordLength = 8`)
- Modifier : tous les `newId()` / `Random()` UUID dans `lib/features/**/data/*_repository.dart` (notes au minimum : `note_repository.dart` ; factoriser si copié-collé)
- Créer si absent : `lib/core/ids/uuid_v4.dart`
- Modifier les tests qui figent `6 caractères`

**Prompt Claude Code**

```
1. Crée lib/core/ids/uuid_v4.dart avec une fonction unique `String newUuidV4()` utilisant Random.secure() (dart:math) pour 16 octets, bits version/variant RFC 4122, format 8-4-4-4-12. Aucune autre API.

2. Remplace TOUTES les implémentations locales newId()/UUID maison dans lib/features/**/data par un appel à newUuidV4(). Ne laisse aucun Random() non sécurisé pour générer des identifiants persistés.

3. AppConfig.minPasswordLength passe de 6 à 8. Mets à jour register_page, AuthFailure (message), et les tests qui attendent 6.

4. Ajoute test/core/ids/uuid_v4_test.dart : format regex UUID v4, unicité sur 200 tirages.

N’ajoute pas de package uuid si Random.secure suffit. Ne touche pas à la sync.
```

**Vérification**

```bash
flutter test test/core/ids/uuid_v4_test.dart test/features/auth/auth_failure_test.dart
flutter analyze
```

---

## Tâche 1.8 — Hygiène dépôt : dumps & gitignore

**Fichiers**

- Modifier : `.gitignore`
- Supprimer du tracking (pas forcément du disque si tu veux les garder localement) : `tout_le_code.txt`, `cognicquest_lib_dump.txt`, `_pdf_extract.txt`, `_pdf_extract.md` s’ils existent

**Prompt Claude Code**

```
Le dépôt CognicQuest contient des dumps de code (tout_le_code.txt, cognicquest_lib_dump.txt) et des extraits PDF temporaires. Ajoute-les à .gitignore :

tout_le_code.txt
cognicquest_lib_dump.txt
_pdf_extract.txt
_pdf_extract.md
*.iml
.aider.*

Ne supprime pas AUDIT_PLAN.md ni Cognicquest_.pdf. N’exécute pas git rm --cached que si ces fichiers sont déjà suivis par git ; dans ce cas, retire-les de l’index SANS git commit (l’humain committera). Ne touche pas à git config.
```

**Vérification**

```bash
git check-ignore -v tout_le_code.txt cognicquest_lib_dump.txt
flutter analyze
```

---

## Gate Phase 1

```bash
flutter pub get
flutter analyze
flutter test
```

Tous les tests existants + nouveaux doivent passer. Aucune clé Supabase de dev dans `lib/` / `test/`. Manifeste Android avec MAIN+INTERNET. Entitlements macOS avec network.client. RLS plan documentée et SQL prêt à coller.

---

# Phase 2 — Refactoring

Objectif : dette, perf, local-first complet, CI, identité store — **sans** Stripe/RevenueCat.

---

## Tâche 2.1 — Retirer graphview mort

**Fichiers**

- Modifier : `pubspec.yaml`
- Régénéré : `pubspec.lock`

**Prompt Claude Code**

```
La dépendance graphview: ^1.5.1 est dans pubspec.yaml mais le layout est 100 % maison (lib/features/graph/domain/graph_layout.dart). Aucun import package:graphview dans lib/.

Retire graphview de pubspec.yaml. Lance flutter pub get. Ne touche pas au code du graphe. Vérifie qu’aucun import graphview ne reste.
```

**Vérification**

```bash
flutter pub get
flutter analyze
flutter test test/features/graph/
```

---

## Tâche 2.2 — Graphe : layout hors thread UI

**Fichiers**

- Modifier : `lib/features/graph/domain/graph_layout.dart`
- Modifier : `lib/features/graph/providers/graph_provider.dart`
- Modifier : `lib/features/graph/views/graph_page.dart` si le compute est appelé depuis le widget
- Modifier : `test/features/graph/graph_layout_test.dart`

**Prompt Claude Code**

```
GraphLayout.compute fait jusqu’à 300 itérations Fruchterman-Reingold sur le isolate UI. Avec le seed démo dense, l’écran graphe freeze.

1. Garde l’algorithme (déterministe, isolated nodes, spacing). Ne réintroduis pas graphview.
2. Expose un point d’entrée top-level (fonction ou wrapper SendPort-compatible) pour Flutter compute() / Isolate.run, car compute exige une fonction top-level ou static.
3. Dans le provider du graphe, calcule la layout de façon asynchrone. Affiche le graphe précédent ou un placeholder pendant le calcul. Annule/ignore un résultat périmé si les nœuds changent.
4. Pour n <= 12, tu PEUX rester en synchrone (tests unitaires de GraphLayout.compute inchangés).
5. Ajoute un test : compute produit les mêmes positions que l’appel synchrone pour un graphe de 5 nœuds.

Ne change pas le dessin CustomPainter au-delà de ce qui est nécessaire pour consommer un Future/AsyncValue.
```

**Vérification**

```bash
flutter test test/features/graph/
flutter analyze
```

---

## Tâche 2.3 — Local-first : settings + dashboard layout

**Fichiers**

- Modifier : `lib/core/database/app_database.dart` (+ `app_database.g.dart` via build_runner)
- Créer : `test/core/database/migration_v7_test.dart`
- Modifier : `lib/features/settings/providers/settings_provider.dart`
- Modifier : `lib/features/dashboard/data/dashboard_layout_repository.dart`
- Modifier : `lib/features/sync/providers/sync_coordinator.dart`
- Modifier : `supabase/schema.sql` seulement si une colonne manque (déjà `settings` jsonb + `dashboard_layout`)

**Prompt Claude Code**

```
Les réglages (thème, texte, sons) et le layout du dashboard sont encore 100 % Supabase (SupabaseSettingsRepository, SupabaseDashboardLayoutRepository). Hors ligne / DEV_BYPASS ils restent aux défauts. De plus, deux upserts séparés sur user_preferences risquent de se marcher dessus.

Fais un Lot « local-first préférences » cohérent avec les autres repos :

1. Drift schemaVersion 7 : table local_user_preferences (user_id PK, dashboard_layout text JSON, settings text JSON, updated_at, is_synced).
2. Migration v7 + test migration_v7_test.dart sur le modèle des tests v3–v6 existants.
3. Un seul repository local-first UserPreferencesRepository : watch/save settings, watch/save layout, sync push/pull vers public.user_preferences (colonnes dashboard_layout + settings ensemble, un seul upsert pour ne pas écraser l’autre colonne).
4. SettingsNotifier et dashboard layout provider lisent SQLite d’abord, sync via SyncCoordinator (ajouter le module dans _modules()).
5. Conflits : last-write-wins sur updated_at comme les notes.
6. En DEV_BYPASS_AUTH sans session : tout reste local, pas d’appel réseau (comme les autres modules).
7. Lance dart run build_runner build --delete-conflicting-outputs pour app_database.g.dart.

Ne touche pas à Stripe. Conserve UserSettings.fromJson / DashboardLayout.fromJson existants.
```

**Vérification**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/database/ test/features/settings/
flutter analyze
```

---

## Tâche 2.4 — Factoriser la sync queue des repositories

**Fichiers**

- Modifier : `lib/core/database/sync_queue.dart`
- Modifier : `lib/features/notes/data/note_repository.dart` et les autres `LocalFirst*Repository` **uniquement** pour déléguer enqueue/pending/push déjà couverts par `SyncQueue` (pas de rewrite fonctionnel)

**Prompt Claude Code**

```
Les LocalFirst*Repository dupliquent le patron SerialSync + enqueue + pull paginé. sync_queue.dart a déjà SerialSync et SyncQueue.

Sans changer le comportement observable (mêmes tables Supabase, même LWW) :
1. Documente en tête de sync_queue.dart le contrat push/pull attendu.
2. Si un repository n’utilise pas encore SyncQueue.enqueue / pendingIds / remove, bascule-le.
3. Interdis toute nouvelle copie de fetchAllPages : tous les pulls passent par lib/core/database/remote_pagination.dart.
4. N’introduis pas de générique magique si ça casse la lisibilité : 2-3 helpers max.

Les tests test/features/sync/offline_repositories_test.dart doivent rester verts sans changer leurs assertions métier, sauf si un nom interne l’exige.
```

**Vérification**

```bash
flutter test test/features/sync/ test/core/database/
flutter analyze
```

---

## Tâche 2.5 — CI GitHub Actions

**Fichiers**

- Créer : `.github/workflows/ci.yml`

**Prompt Claude Code**

```
Crée .github/workflows/ci.yml pour CognicQuest (Flutter).

Jobs :
- trigger : push et pull_request sur main/master
- setup flutter stable
- flutter pub get
- flutter analyze --fatal-infos
- flutter test
- flutter build web --no-tree-shake-icons (sans secrets ; AppConfig supabase vide + bypass false : le BUILD doit réussir même si l’app affiche l’écran d’erreur config au runtime). Si le build web échoue à cause de sqlite3.wasm, copie/vérifie que web/sqlite3.wasm et web/drift_worker.js sont versionnés.

Pas de deploy. Pas de secrets dans le workflow. Ne bump pas les versions Flutter dans pubspec.
```

**Vérification**

```bash
# Fichier présent et parseable
python -c "import pathlib; t=pathlib.Path('.github/workflows/ci.yml').read_text(encoding='utf-8'); assert 'flutter test' in t; assert 'flutter analyze' in t; print('OK 2.5')"
flutter analyze
flutter test
```

---

## Tâche 2.6 — Identité store + PWA + README réel

**Fichiers**

- Modifier : `android/app/build.gradle.kts` (`applicationId` → `io.cognicquest.app` — **aligné sur le scheme OAuth déjà utilisé**)
- Modifier : `android/app/src/main/kotlin/com/example/cognicquest/MainActivity.kt` (déplacer le fichier vers `.../io/cognicquest/app/MainActivity.kt` et `package io.cognicquest.app`)
- Modifier : `android/app/src/main/AndroidManifest.xml` label `CognicQuest`
- Modifier : `web/index.html`, `web/manifest.json` (nom, description, retirer `orientation: portrait-primary`)
- Modifier : `README.md` (lancer, env.json, lots, tests)
- Modifier : `ios/Runner/Info.plist` display name `CognicQuest` (déjà proche)

**Prompt Claude Code**

```
Refonte identité, SANS changer les icônes PNG.

1. applicationId Android = io.cognicquest.app. Déplace MainActivity.kt vers android/app/src/main/kotlin/io/cognicquest/app/MainActivity.kt avec package io.cognicquest.app. namespace gradle = io.cognicquest.app. Laisse le signing debug tel quel (le keystore prod est Phase 3).
2. android:label et PWA : CognicQuest. Description : « Application d’apprentissage cognitif : fiches, répétition espacée, métacognition. »
3. web/manifest.json : enlève orientation portrait-primary (bloque le desktop). display standalone OK.
4. README.md : remplace le template Flutter par :
   - prérequis Flutter 3.24+
   - copier env.example.json → env.json (gitignored)
   - flutter run --dart-define-from-file=env.json --dart-define=DEV_BYPASS_AUTH=true pour l’UI hors ligne
   - flutter run --dart-define-from-file=env.json --dart-define=DEV_BYPASS_AUTH=false pour l’auth réelle
   - exécuter supabase/schema.sql dans le SQL Editor
   - flutter test / flutter analyze
   Ne recopie AUCUNE clé réelle.

Si un chemin kotlin orphelin com/example reste, supprime-le.
```

**Vérification**

```bash
python -c "
import pathlib
g=pathlib.Path('android/app/build.gradle.kts').read_text(encoding='utf-8')
assert 'io.cognicquest.app' in g
assert pathlib.Path('android/app/src/main/kotlin/io/cognicquest/app/MainActivity.kt').exists()
m=pathlib.Path('web/manifest.json').read_text(encoding='utf-8')
assert 'portrait-primary' not in m
print('OK 2.6')"
flutter analyze
```

---

## Tâche 2.7 — Notes : ne plus charger tous les blocs pour la liste

**Fichiers**

- Modifier : `lib/features/notes/data/note_repository.dart`
- Modifier : `lib/features/notes/providers/note_provider.dart`
- Modifier : `lib/features/notes/views/notes_page.dart` / `note_editor_page.dart` si l’éditeur a besoin d’un fetch par id
- Tests : `test/features/notes/` (étendre)

**Prompt Claude Code**

```
LocalFirstNoteRepository.watchAll() fait un select de TOUTES les notes puis TOUS les blocs (asyncMap). La liste des fiches n’a pas besoin des blocs.

1. watchAll() ne ramène que les colonnes de local_notes (sans blocs, blocks: const []).
2. Ajoute watchById(id) ou fetchById(id) qui hydrate les blocs pour l’éditeur uniquement.
3. NoteEditorPage / note_provider doivent utiliser watchById. La recherche (note_search) qui a besoin du contenu : si elle s’appuie sur note.content (champ texte de la fiche) et non sur les blocs, watchAll suffit. Si elle indexe les blocs, charge les blocs seulement pour la recherche, pas pour le rebuild de la liste.
4. Tests : watchAll n’attache pas de blocs ; fetchById les attache.

Comportement sync/CRUD inchangé.
```

**Vérification**

```bash
flutter test test/features/notes/ test/features/sync/offline_repositories_test.dart
flutter analyze
```

---

## Tâche 2.8 — Lints à jour + analyze propre

**Fichiers**

- Modifier : `pubspec.yaml` (`flutter_lints: ^5.0.0` ou dernière 5.x compatible)
- Modifier : `analysis_options.yaml` seulement si le nouveau package l’exige
- Corriger les infos/warnings bloquants introduits

**Prompt Claude Code**

```
Passe flutter_lints de ^3.0.1 à ^5.0.0 (ou 5.x courant compatible SDK >=3.6). flutter pub get. Adapte analysis_options.yaml si l’include change. Corrige les lints nouveaux dans lib/ et test/ SANS désactiver des règles en masse. flutter analyze --fatal-infos doit passer.
```

**Vérification**

```bash
flutter pub get
flutter analyze --fatal-infos
flutter test
```

---

## Gate Phase 2

```bash
flutter analyze --fatal-infos
flutter test
flutter build web --no-tree-shake-icons
```

Layout graphe non bloquant. Préférences locales. CI présente. applicationId `io.cognicquest.app`. Plus de `graphview`.

---

# Phase 3 — Fonctionnalités (auth production + monétisation)

Objectif CdC : freemium B2C (`premium`) + offre `pro` B2B. Stripe sur le web. RevenueCat sur iOS/Android. Le client ne écrit jamais `profiles.plan`.

---

## Tâche 3.1 — Entitlements (gating) sans paiement

**Fichiers**

- Créer : `lib/features/billing/domain/entitlements.dart`
- Créer : `lib/features/billing/providers/entitlements_provider.dart`
- Modifier : `lib/core/config/app_config.dart` (quotas déjà là : les brancher)
- Modifier : `lib/features/review/data/review_repository.dart` (createCard)
- Modifier : `lib/features/graph/data/note_link_repository.dart` (création de lien)
- Créer : `lib/features/billing/widgets/paywall_sheet.dart` (UI seulement, bouton « Plus tard »)
- Tests : `test/features/billing/entitlements_test.dart`

**Prompt Claude Code**

```
Avant Stripe, le gating doit exister et être testable.

1. Classe Entitlements(plan: UserPlan) :
   - isPremium => plan == premium || plan == pro
   - isPro => plan == pro
   - canCreateFlashcard(reviewedOrCreatedToday: int) : si !isPremium && count >= AppConfig.maxFreeFlashcardsPerDay → false
   - canCreateLink(createdToday: int) : idem maxFreeLinksPerDay
   - canUseKnowledgeGraphInsights : premium+
   - canUseAdvancedPlanning (Gantt dépendances / exam targets illimités) : premium+
   - canUseOrgFeatures : pro only (placeholder, pas d’UI orga encore)

2. entitlementsProvider lit profileProvider.plan (free si profil null / bypass).

3. createCard et création de lien : si Entitlements refuse, throw une DataFailure métier dédiée (code 'quota_exceeded') et l’UI ouvre PaywallSheet. Ne bloque PAS la révision des cartes déjà créées.

4. PaywallSheet : texte FR honnête (« Offre Premium — paiements bientôt » si billing non configuré). Pas de faux bouton qui prétend débiter.

5. Tests unitaires purs sur Entitlements, sans Stripe.

N’ajoute aucune clé Stripe/RevenueCat dans cette tâche.
```

**Vérification**

```bash
flutter test test/features/billing/
flutter analyze
```

---

## Tâche 3.2 — Backend : colonne billing + Edge Function webhook Stripe

**Fichiers**

- Créer : `supabase/migrations/20261009_billing.sql`
- Créer : `supabase/functions/stripe-webhook/index.ts`
- Créer : `supabase/functions/create-checkout-session/index.ts`
- Modifier : `supabase/schema.sql` (aligner)
- Créer : `env.example.json` clés documentées `STRIPE_PRICE_PREMIUM`, `STRIPE_PRICE_PRO` (valeurs placeholder)

**Prompt Claude Code**

```
Ajoute le backend monétisation CÔTÉ SERVEUR uniquement. Le client Flutter n’a toujours pas de clé secrète Stripe.

SQL (idempotent) :
- Table public.billing_customers (user_id PK → auth.users, stripe_customer_id text unique, revenuecat_app_user_id text unique, updated_at)
- RLS : select own only. Aucun insert/update pour authenticated (service_role only).
- Ne PAS élargir l’update de profiles.plan.

Edge Function stripe-webhook :
- Vérifie la signature Stripe (STRIPE_WEBHOOK_SECRET).
- checkout.session.completed / customer.subscription.updated / deleted → mappe price id → plan free|premium|pro, UPDATE profiles.plan via service role, upsert billing_customers.
- Répond 400 si signature invalide. Pas de log du raw body complet.

Edge Function create-checkout-session :
- JWT utilisateur requis (Authorization Bearer).
- Body { priceId } whitelisté (env STRIPE_PRICE_PREMIUM / STRIPE_PRICE_PRO seulement).
- Crée/réutilise stripe customer, session mode subscription, success_url / cancel_url = origine autorisée.
- Retourne { url }.

Documente dans un COMMENTAIRE en tête des functions les secrets Dashboard : STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_PRICE_*.
N’installe pas encore le package Flutter stripe. Ne committe aucun .env réel.
```

**Vérification**

```bash
python -c "import pathlib; assert pathlib.Path('supabase/functions/stripe-webhook/index.ts').exists(); assert pathlib.Path('supabase/functions/create-checkout-session/index.ts').exists(); print('OK 3.2 fichiers')"
# Déploiement manuel : supabase functions deploy (hors CI tant que les secrets ne sont pas dans GitHub)
```

Critère manuel : `supabase functions serve` + Stripe CLI `listen --forward-to` : un événement test met à jour `profiles.plan`.

---

## Tâche 3.3 — Flutter web : Checkout Stripe (pas d’IAP)

**Fichiers**

- Modifier : `pubspec.yaml` — **pas** de `flutter_stripe` obligatoire si on redirige vers `url_launcher` + session URL
- Ajouter : `url_launcher` si absent
- Modifier : `lib/features/billing/data/billing_repository.dart` (créer)
- Modifier : `lib/features/billing/widgets/paywall_sheet.dart`
- Modifier : `lib/core/config/app_config.dart` (flag `kIsWeb` pour le chemin Stripe)

**Prompt Claude Code**

```
Sur Flutter WEB uniquement, le PaywallSheet appelle l’Edge Function create-checkout-session (client supabase.functions.invoke) puis lance l’URL retournée (url_launcher, nouvelle fenêtre). 

Règles :
- Aucune STRIPE_SECRET_KEY dans le client. Anon + JWT session seulement.
- Si !kIsWeb, ce bouton affiche « Abonnement disponible sur l’App Store / Google Play » (RevenueCat = tâche 3.4) au lieu d’appeler Stripe.
- Après retour sur l’app, profileProvider se rafraîchit (invalidate). Ne fais PAS confiance au query param success pour setter le plan localement : relire profiles.plan.
- Gère les erreurs (non connecté, function 401, réseau) via DataFailure déjà existante.
- Test : fake FunctionsClient / repository mock — invoke appelé avec le bon price, pas d’écriture dans profiles depuis le client.

Ajoute url_launcher dans pubspec.yaml si manquant.
```

**Vérification**

```bash
flutter test test/features/billing/
flutter analyze
flutter build web --no-tree-shake-icons
```

---

## Tâche 3.4 — iOS/Android : RevenueCat

**Fichiers**

- Modifier : `pubspec.yaml` (`purchases_flutter`)
- Créer : `lib/features/billing/data/revenuecat_gateway.dart`
- Modifier : `lib/main.dart` (init RevenueCat seulement si `!kIsWeb` et clé `REVENUECAT_API_KEY` via dart-define, sinon no-op)
- Modifier : `env.example.json` (`REVENUECAT_API_KEY`)
- Créer : `supabase/functions/revenuecat-webhook/index.ts` (met à jour profiles.plan, service_role)
- Modifier : PaywallSheet (offre native)

**Prompt Claude Code**

```
Intègre RevenueCat pour iOS et Android seulement (import conditionnel / kIsWeb guard).

1. purchases_flutter, configure avec PurchasesConfiguration(apiKey) depuis String.fromEnvironment('REVENUECAT_API_KEY', defaultValue: ''). Si la clé est vide, n’initialise pas et le paywall mobile reste informatif.
2. logIn(appUserId) = currentUser.id Supabase dès la session disponible. logOut au signOut.
3. Paywall mobile : offerings.current, purchasePackage, restorePurchases. Après achat, n’écris PAS profiles.plan depuis le client. Attends le webhook (polling profileProvider toutes les 2s, max 15s) ou un refresh manuel.
4. Edge Function revenuecat-webhook : valide le secret Authorization (REVENUECAT_WEBHOOK_SECRET), mappe entitlement premium/pro → UPDATE profiles.plan, upsert billing_customers.revenuecat_app_user_id.
5. Android applicationId io.cognicquest.app doit correspondre à l’app Play/RevenueCat (déjà Phase 2).
6. Ne mélange pas Stripe et RevenueCat sur la même plateforme : web = Stripe, mobile = RevenueCat.

Pas de clé RevenueCat en dur dans le code (contrairement à l’ancienne clé Supabase, leçon Phase 1).
```

**Vérification**

```bash
flutter pub get
flutter analyze
flutter test test/features/billing/
# Builds natifs (sur machine avec toolchains) :
# flutter build apk --debug --dart-define-from-file=env.json
```

Critère manuel : sandbox StoreKit / Play license tester ; le webhook pose `plan=premium`.

---

## Tâche 3.5 — Compte : reset password + suppression RGPD

**Fichiers**

- Créer : `lib/features/auth/views/update_password_page.dart`
- Modifier : `lib/router/app_router.dart` (route publique `/update-password`, deep link recovery)
- Modifier : `lib/features/settings/views/settings_page.dart` (section compte : e-mail, plan, déconnexion, supprimer le compte)
- Créer : `supabase/functions/delete-account/index.ts` (service_role : delete auth.users → cascade)

**Prompt Claude Code**

```
1. Route /update-password : si le client Supabase a un recovery session (onAuthStateChange passwordRecovery), affiche un formulaire nouveau mot de passe + confirm. Sinon redirige login. Ajoute le path aux Redirect URLs documentées dans un commentaire AppConfig.

2. Settings : bloc Compte avec plan actuel (UserPlan.label), bouton déconnexion existant si absent, bouton « Supprimer mon compte » (dialog double confirmation). Appelle functions.invoke('delete-account') puis signOut + clear Drift (delete local_* de ce userId).

3. Edge Function delete-account : JWT required, supprime auth.users id = jwt.sub (cascade profiles et tables). Pas d’autre user_id accepté dans le body.

4. Tests widget/unit : isInternalRedirect inclut /update-password ; delete-account n’est pas appelable sans session (mock).
```

**Vérification**

```bash
flutter test test/features/auth/ test/features/billing/
flutter analyze
```

---

## Tâche 3.6 — Sons d’ambiance + polish PWA

**Fichiers**

- `assets/sounds/` (fichiers libres de droits, ou désactiver proprement les options sans fichier)
- Modifier : `lib/features/settings/data/ambient_sound_engine.dart`
- Modifier : `web/index.html` (theme-color, apple-mobile-web-app-title CognicQuest)

**Prompt Claude Code**

```
assets/sounds/ ne contient qu’un .gitkeep. AmbientSoundEngine échoue en silence.

Soit :
A) Ajoute 3 fichiers courts (rain, cafe, white) sous licence CC0, déclare-les dans pubspec assets, mappe les enum UserSettings.ambientSound existants.
Soit :
B) Si tu n’as pas de fichiers audio : retire les options orphelines de l’UI Réglages et documente TODO. Ne laisse pas des boutons qui ne jouent rien sans explication.

Harmonise web/index.html title/description avec web/manifest.json (tâche 2.6).
Ne casse pas les tests settings.
```

**Vérification**

```bash
flutter test test/features/settings/
flutter analyze
```

---

## Tâche 3.7 — Signing release Android/iOS (checklist, pas de secrets dans git)

**Fichiers**

- Créer : `android/key.properties.example`
- Modifier : `android/app/build.gradle.kts` (lire key.properties SI présent, sinon debug)
- Modifier : `.gitignore` (`key.properties`, `*.jks`, `*.keystore`)
- Documenter dans `README.md` les étapes Play / App Store Connect / RevenueCat / Stripe Dashboard

**Prompt Claude Code**

```
Prépare le signing release SANS générer de keystore dans le dépôt.

1. android/key.properties.example avec storePassword=, keyPassword=, keyAlias=, storeFile=
2. .gitignore : key.properties, *.jks, *.keystore
3. build.gradle.kts : si key.properties existe, signingConfigs.release l’utilise ; sinon fallback debug (comportement actuel) avec un commentaire TODO prod.
4. README : section « Publication » listant keystore local, Fastlane optionnel, produits Stripe, entitlements RevenueCat, Redirect URLs OAuth.

N’appelle pas keytool. N’invente pas de mots de passe.
```

**Vérification**

```bash
python -c "assert open('.gitignore',encoding='utf-8').read().find('key.properties')>=0; print('OK 3.7')"
flutter analyze
```

---

## Gate Phase 3 (recette produit)

| Critère | Commande / test manuel |
|---|---|
| Analyse + tests | `flutter analyze --fatal-infos && flutter test` |
| Web | `flutter build web` puis checkout Stripe test mode |
| Android | lanceur visible, OAuth Google, achat sandbox RevenueCat |
| Plan | impossible à setter depuis l’app / PostgREST authenticated |
| Quotas | compte free bloqué à 100 cartes/liens / jour + paywall |
| RGPD | delete-account cascade |
| Hors ligne | notes/tâches/réglages fonctionnent, bannière sync |

---

## Écarts CdC (`Cognicquest_.pdf`) vs code — Phase 4, après la 3

Le PDF (22 pages) cible d’abord une **application web** intuitive (Flutter web couvre ça). Plusieurs exigences **ne sont pas dans le code** et **ne sont pas** dans les Phases 1–3. À traiter seulement une fois auth + paiements verts :

| Exigence CdC | État |
|---|---|
| Fiches réflexes imprimables (module PDF, check-list d’attention) | Absent |
| Bibliothèque d’activités formelles / informelles (jeux de logique, défis créatifs) | Absent |
| Tests fonctions exécutives (inhibition, MdT, flexibilité) et biais cognitifs | Absent (profil d’apprentissage ≠ ces tests) |
| Sessions d’étude **en groupe** | Absent (todo/kanban solo seulement) |
| Commentaires vocaux / textuels | Textuel partiel (fiches) ; **vocal absent** |
| Espace « bienvenue » objectifs perso/pro | Partial (goals SMART, pas d’onboarding dédié) |
| KPI « −15 % de temps de révision à charge égale » | Non mesuré |
| Interface beige, animations douces, anti burn-out | Thème beige présent ; animations / tracker émotions = journal RPE partiel |

Ne pas ouvrir ces sujets dans Claude Code tant que les gates 1–3 ne sont pas vertes.

---

## Hors périmètre volontaire (ne pas faire dans ce plan)

- Backend Node/Nest séparé (Supabase + Edge Functions suffisent au stade actuel).
- Collaboration temps réel multi-utilisateurs sur une même fiche.
- IA générative (hors CdC actuel du code).
- Changement de Drift vers Hive/Isar.
- Force-push, `--no-verify`, modification de `git config`.

---

## Ordre d’exécution recommandé (une ligne par appel Claude Code)

1. 1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6 → 1.7 → 1.8 → **Gate Phase 1**  
2. 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6 → 2.7 → 2.8 → **Gate Phase 2**  
3. 3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6 → 3.7 → **Gate Phase 3**

Fin du cahier.
