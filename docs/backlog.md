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

## 3. `ThemeData` jamais égaux

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

## 4. Graphique d'humeur : débordement de 1,5 à 3 px

**Constat** (chantier 12, animations réduites) : `MoodTrendChart` déborde
verticalement de 1,5 à 3 px dans les tests de widgets, **avec le code
d'origine**. Le test des animations tolère uniquement ces erreurs.

**À faire** : vérifier sur appareil (bande jaune et noire en debug) ;
corriger la hauteur réservée aux étiquettes du graphique. Change
l'affichage : à valider avant.
