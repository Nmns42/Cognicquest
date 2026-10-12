# Backlog technique — CognicQuest

Chantiers identifiés, **sans code engagé**. Chaque entrée garde ses mesures
de départ pour juger du gain le moment venu.

---

## 1. Graphe de connaissances à grande échelle

**Constat (chantier 12, VM desktop, 1 000 fiches / 3 000 liens)**

| Mesure | Valeur |
|---|---|
| Étape de simulation la plus longue | 104 ms |
| Calcul complet de la disposition | ≈ 10 s |
| Blocage max du thread principal sur le web (tranches de 8 ms) | 62 ms |

Cause : répulsion entre toutes les paires, O(n²) par itération × 300
itérations. Une étape ne pouvant pas être interrompue, le découpage web ne
descend pas sous sa durée. Mobile et desktop restent fluides (isolate), mais
le graphe met ~10 s à apparaître.

**Objectif proposé** : graphe affiché en moins de 2 s, aucune frame bloquée
plus de 16 ms sur le web.

**Approches**

| Approche | Gain estimé | Risque |
|---|---|---|
| A. Découper *l'intérieur* d'une itération (boucle de répulsion reprise ligne par ligne entre deux tranches) | Web : blocage ≤ budget de tranche (≈ 8–10 ms). Durée totale inchangée (≈ 10 s). | Faible : même arithmétique, testable au bit près comme au chantier 12. |
| B. Barnes-Hut (quadtree, θ ≈ 0,8) pour la répulsion | Étape O(n log n) : ≈ 10–15 ms à 1 000 fiches, calcul complet ≈ 1–2 s. | Moyen : carte **différente** de l'actuelle (approximation), nouveaux tests de référence, code plus complexe. |
| C. Disposition incrémentale persistée (positions gardées par fiche, quelques itérations locales après un ajout) | Mise à jour quasi instantanée après le premier calcul. Premier calcul inchangé. | Moyen à élevé : la carte dépend de l'historique (fin du déterminisme actuel), persistance et invalidation à gérer. |

**Recommandation** : A + B. A seul satisfait la contrainte web, B seul la
durée ; ensemble ils tiennent l'objectif. C ensuite, si l'édition fréquente
d'un grand carnet le justifie.

---

## 2. Liste des fiches — premier chargement (option 1 du chantier 12-C)

**Constat (VM desktop, 8 blocs de 150 caractères par fiche)**

| Fiches | Premier chargement | Blocs lus |
|---|---|---|
| 300 | 70 ms | 2 400 |
| 1 000 | 293 ms | 8 000 |
| 3 000 | 632 ms | 24 000 |

Depuis le chantier 12-C, une sauvegarde ne relit plus que les blocs de la
fiche modifiée ; reste le premier chargement, linéaire, payé une fois par
session.

**À faire** : remesurer sur un vrai téléphone Android pendant les tests de
l'APK, avec 1 000 et 3 000 fiches synthétiques.

**Règle de bascule** : si l'ouverture de la liste dépasse **1 s**, passer à
l'option 1 : liste sans blocs (texte de recherche et décompte des cases
dénormalisés dans `local_notes`), fiche complète chargée à la demande
(`watchById`) par l'éditeur, SQ3R, Feynman et l'aperçu du graphe.

---

## 3. `ThemeData` jamais égaux — ✅ résolu (`5e393ad`)

> Résolu : `==` et `hashCode` sur `CognicColors`, et second coupable trouvé
> en route — la barre de navigation utilisait `WidgetStateProperty.resolveWith`
> (closure comparée par identité), remplacé par `fromMap`. Deux thèmes
> construits pour la même variante sont désormais égaux.

**Constat** : deux `ThemeData` construits séparément pour le même thème ne
sont jamais égaux (`==`).

**Cause identifiée** : `CognicColors extends ThemeExtension<CognicColors>`
(`lib/core/theme/app_theme.dart`) ne redéfinit ni `operator ==` ni
`hashCode`. `ThemeData.==` compare ses extensions, donc ici par identité.

**Effet** : depuis le chantier 12-B, `appThemeProvider` n'est recalculé
qu'au changement de thème ; le coût restant est faible. Mais tout
reconstruction du thème (ex. `Motion.reducedTheme`) produit un thème
« différent » et notifie tous les widgets qui lisent `Theme.of`.

**Correction estimée** : `==` et `hashCode` sur les couleurs de
`CognicColors` (≈ 25 lignes) + un test « deux `AppTheme.build(v)` sont
égaux ». Risque faible. Environ 30 min.

---

## 4. Graphique d'humeur : débordement — ✅ résolu (`6da25ab`)

> Résolu : reproduit avec la police réelle (0,9 px à 100 %, 8,9 px à 200 %
> sur 320 px) ; hauteur fixe remplacée par une zone fixe pour la barre,
> l'initiale du jour prenant la hauteur dont elle a besoin. Échelle et
> couleurs inchangées.

**Constat** (chantier 12, animations réduites) : `MoodTrendChart` déborde
verticalement de 1,5 à 3 px dans les tests de widgets, **avec le code
d'origine**. Le test des animations tolère uniquement ces erreurs.

**À faire** : vérifier sur appareil (bande jaune et noire en debug) ;
corriger la hauteur réservée aux étiquettes du graphique. Change
l'affichage : à valider avant.

---

## 5. Réordonner les tâches à l'intérieur d'un quadrant d'Eisenhower

**Décision (R3)** : non pour l'instant. Ce serait un second ordre manuel, en
concurrence avec celui du Kanban (`tasks.position` est par colonne de statut,
alors qu'un quadrant mélange les statuts).

**Si on y revient** : une colonne dédiée (ex. `tasks.quadrant_position`),
donc une modification du schéma Supabase, ≈ 1 j.

**À noter** : le réordonnancement du Kanban renumérote aujourd'hui toute la
colonne à chaque déplacement (`moveTask` réécrit `position = 0..n-1`, puis
`saveOrder` envoie toutes les tâches) : un déplacement produit autant
d'écritures synchronisées que la colonne compte de tâches. Le principe retenu
pour les fiches et les habitudes (R1, R2) pourra lui être appliqué ensuite.

---

## 6. `UserSettings` : l'égalité ignore les routines

**Constat** (chantier 12, ajout de `manualNoteOrder`) : `operator ==` et
`hashCode` de `UserSettings` ne comparent pas `morningRoutine` ni
`eveningRoutine`. Deux réglages qui ne diffèrent que par une routine sont
donc « égaux » : un `select` ou un `==` sur les réglages ne voit pas le
changement.

**Correction estimée** : `==` et `hashCode` sur `Routine` (heure, minute,
activation, étapes) puis inclusion dans `UserSettings`, avec un test champ
par champ comme pour `CognicColors`. Risque faible, ≈ 30 min.
