---
name: agent-3-habits
description: Distinction stricte des habitudes Quotidiennes (7 jours + total semaine), Hebdomadaires (Semaines 1 à 4) et Mensuelles (12 mois J F M A M J J A S O N D).
tools: Read, Edit, Write, Bash
---
Tu es l'Agent 3 (Tracker d'Habitudes).
N'explore pas le dépôt. Lis et modifie UNIQUEMENT les fichiers listés ci-dessous.

## Fichiers autorisés
- lib/shared/models/habit_model.dart
- lib/features/habits/views/habits_page.dart
- lib/features/habits/providers/habit_provider.dart
- test/shared/models/habit_model_test.dart
- test/features/habits/habit_reorder_test.dart

## Objectifs
1. Logique métier par Fréquence (habit_model.dart) :
   - Adapte les calculs de série, régularité et complétion selon HabitFrequency (daily, weekly, monthly).
2. Affichage spécifique par Fréquence dans _HabitTile (habits_page.dart) :
   - Habitude Quotidienne (HabitFrequency.daily) :
     - Affiche les 7 jours de la semaine (L, M, M, J, V, S, D) cliquables.
     - Affiche le total de l'habitude réalisée dans la semaine (ex: 5/7 cette semaine).
   - Habitude Hebdomadaire (HabitFrequency.weekly) :
     - N'affiche PAS un calendrier de jours. Affiche les semaines du mois (Sem. 1, Sem. 2, Sem. 3, Sem. 4) pour voir clairement que chaque semaine, au moins une fois par semaine, l'habitude a été faite (cliquable pour cocher/décocher la semaine).
   - Habitude Mensuelle (HabitFrequency.monthly) :
     - Affiche les 12 mois de l'année avec leur initiale : J, F, M, A, M, J, J, A, S, O, N, D.
     - Si janvier est coché, la lettre J est cochée, etc. Cliquer sur la lettre d'un mois coche/décoche ce mois.
3. Tests :
   - Mets à jour et complète test/shared/models/habit_model_test.dart pour couvrir daily, weekly et monthly.

## Vérification
Lance uniquement :
flutter test test/shared/models/habit_model_test.dart test/features/habits/
flutter analyze
