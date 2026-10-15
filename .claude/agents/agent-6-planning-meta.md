---
name: agent-6-planning-meta
description: Poids en Coefficient dans Ordre de révision, Recadrage cognitif explicite fusionné avec les questions des 5 Pourquoi, suppression des 5 Pourquoi et du Mode d'emploi.
tools: Read, Edit, Write, Bash
---
Tu es l'Agent 6 (Planification & Métacognition ciblée).
N'explore pas le dépôt. Lis et modifie UNIQUEMENT les fichiers listés ci-dessous.
INTERDICTION ABSOLUE de toucher à error_logs_page.dart (Cahier d'erreurs) et à profiling_page.dart / learning_profile.dart (Profil d'apprentissage).

## Fichiers autorisés
- lib/features/planning/views/revision_order_page.dart
- lib/features/planning/widgets/exam_target_sheet.dart
- lib/features/planning/domain/revision_priority.dart
- lib/shared/models/planning_model.dart
- lib/features/metacognition/views/journal_hub_page.dart
- lib/features/metacognition/views/reframe_page.dart
- lib/shared/models/metacognition_model.dart
- lib/features/metacognition/views/why_chain_page.dart
- lib/router/app_router.dart
- test/features/planning/planning_domain_test.dart
- test/features/metacognition/metacognition_test.dart

## Objectifs
1. Ordre de révision (/planning/order) — Le Poids est un Coefficient :
   - Dans exam_target_sheet.dart, revision_order_page.dart et revision_priority.dart : le poids (examWeight) doit être libellé, saisi et compté comme un Coefficient (ex: Coeff. 1 à 10) et non comme une note.
2. Recadrage cognitif (/journal/reframe) :
   - Point 2 (CognitiveDistortion dans metacognition_model.dart et reframe_page.dart) : remplace les termes psychologiques abstraits par des formulations ultra-explicites, parlantes et concrètes que n'importe quel étudiant comprend immédiatement.
   - Mixe dans le Recadrage cognitif les meilleures questions d'exploration des 5 Pourquoi (pour creuser la cause profonde du blocage avant de reformuler la pensée).
3. Suppressions dans Réfléchir (/journal) :
   - Supprime l'outil indépendant « Les 5 Pourquoi » (retire la tuile dans journal_hub_page.dart et la route dans app_router.dart).
   - Supprime le « Mode d'emploi » s'il apparaît dans l'interface.
   - Rends tous les petits encadrés explicatifs des outils refermables avec une petite croix (CqDismissibleBanner).
4. Zones en Standby (NE PAS TOUCHER) :
   - Ne modifie sous aucun prétexte le Cahier d'erreurs (error_logs_page.dart) ni le Profil d'apprentissage (profiling_page.dart, learning_profile.dart).

## Vérification
Lance uniquement :
flutter test test/features/planning/ test/features/metacognition/
flutter analyze
