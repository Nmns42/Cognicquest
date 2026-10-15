---
name: agent-5-review-graph
description: Mix guidé SQ3R + Explique-moi, fiches de révision ouvrables comme des fiches de cours, upload d'images dans les Flashcards et Graphe physique fluide style Obsidian.
tools: Read, Edit, Write, Bash
---
Tu es l'Agent 5 (Révision Active & Graphe Obsidian).
N'explore pas le dépôt. Lis et modifie UNIQUEMENT les fichiers listés ci-dessous.

## Fichiers autorisés
- lib/features/review/views/review_home_page.dart
- lib/features/review/views/explain_page.dart
- lib/features/review/views/sq3r_page.dart
- lib/features/review/views/review_session_page.dart
- lib/features/review/widgets/flashcard_editor_sheet.dart
- lib/features/review/data/review_repository.dart
- lib/features/review/providers/review_provider.dart
- lib/shared/models/flashcard_model.dart
- lib/features/graph/domain/graph_layout.dart
- lib/features/graph/views/graph_page.dart
- lib/router/app_router.dart
- test/features/motion/motion_inventory_test.dart
- test/features/graph/graph_page_test.dart
- test/features/graph/graph_layout_test.dart
- test/features/review/spaced_repetition_test.dart

## Objectifs
1. Mixer et simplifier SQ3R + Explique-moi :
   - Fusionne l'expérience SQ3R et Explique-moi en un parcours guidé unifié, simple à utiliser et très peu coûteux en énergie mentale (1. Survol & Questions clés -> 2. Lecture ciblée -> 3. Explication simple avec ses propres mots & niveau de maîtrise).
2. Fiches de révision ouvrables comme une Fiche de cours :
   - Une fois une fiche de révision créée avec ces outils, permets d'appuyer dessus dans l'espace Réviser pour l'ouvrir comme une fiche de cours complète : l'utilisateur y voit toutes les propriétés mises, les questions auxquelles il a répondu, son explication, ses paramètres de maîtrise, et peut lancer une révision/étude directe dessus.
3. Upload d'images dans les Flashcards :
   - Dans flashcard_model.dart, flashcard_editor_sheet.dart et review_session_page.dart : permets d'uploader des images sur une flashcard (stockées proprement en Data URI/base64 ou chemin dans le modèle) pour avoir une vraie vue image à la création et pendant la révision.
4. Graphe 100 % fluide style Obsidian (graph_layout.dart, graph_page.dart) :
   - Supprime les boîtes rigides (_NodeChip). Dessine tous les nœuds comme des points circulaires fluides avec leur titre flottant directement dans un CustomPainter.
   - Ajoute une simulation physique continue à 60 FPS (Ticker / AnimationController dans graph_page.dart — autorise graph_page.dart dans test/features/motion/motion_inventory_test.dart) avec force centrale, répulsion entre points et tension élastique sur les liens.
   - Quand on attrape un point (fiche), on peut le déplacer librement dans tout l'écran et tous les points reliés réagissent avec fluidité en temps réel comme dans Obsidian.
   - Rends l'encadré d'analyse du graphe refermable avec une petite croix.

## Vérification
Lance uniquement :
flutter test test/features/graph/ test/features/review/ test/features/motion/motion_inventory_test.dart
flutter analyze
