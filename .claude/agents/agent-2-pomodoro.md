---
name: agent-2-pomodoro
description: Pomodoro plein écran statique sans scroll, auto-switch travail/pauses avec sonnerie, choix du nombre de sessions dans Settings et suppression des pièces.
tools: Read, Edit, Write, Bash
---
Tu es l'Agent 2 (Moteur & UI Pomodoro).
N'explore pas le dépôt. Lis et modifie UNIQUEMENT les fichiers listés ci-dessous.

## Fichiers autorisés
- lib/features/pomodoro/views/pomodoro_page.dart
- lib/features/pomodoro/providers/pomodoro_provider.dart
- lib/shared/models/pomodoro_session_model.dart
- lib/core/config/app_config.dart
- lib/features/settings/domain/user_settings.dart
- lib/features/settings/views/settings_page.dart
- test/features/pomodoro/pomodoro_size_test.dart
- test/features/motion/micro_pomodoro_pulse_test.dart
- test/shared/models/pomodoro_session_model_test.dart

## Objectifs
1. Responsive 100 % Statique (Zéro Scroll sur mobile, Plein écran bien agencé sur grand écran) :
   - Dans pomodoro_page.dart, supprime le plafonnement rigide _minDial = 180, _maxDial = 260, _maxPageWidth = 520 et tout défilement vertical.
   - Utilise un LayoutBuilder occupant 100 % de la hauteur et largeur disponibles : sur téléphone, toute la vue Concentration tient sur un seul écran statique sans défiler ; sur grand écran (desktop/web), le cadran et l'interface prennent la taille de l'écran de façon proportionnelle et bien agencée.
   - Mets à jour test/features/pomodoro/pomodoro_size_test.dart pour valider ces nouvelles dimensions adaptatives.
2. Auto-Switch Complet & Sonnerie à chaque fin de tranche :
   - Dans pomodoro_provider.dart (_completePhase / _advancePhase) :
     - Quand les 25 min de travail sont écoulées : joue une sonnerie (via audioplayers AssetSource('sounds/bell.mp3') avec fallback sonore synthétisé + SystemSound.play(SystemSoundType.alert) si le fichier est absent), bascule automatiquement vers la pause courte (5 min) ou la pause longue (10 min) ET lance automatiquement le décompte (status = PomodoroStatus.running).
     - Quand la pause (courte ou longue) est écoulée : joue la sonnerie, bascule automatiquement vers la session de travail suivante ET relance automatiquement le décompte jusqu'à la fin du nombre de sessions configuré.
3. Paramètres Pomodoro (/settings) :
   - Dans PomodoroSettings (user_settings.dart) : mets la pause longue par défaut à 10 minutes (longBreakMinutes = 10).
   - Dans _PomodoroSettings (settings_page.dart) : permets de choisir librement le Nombre de sessions (ex: 2 sessions, 3 sessions, 4 sessions... de 25 min avec 5 min de pause et 10 min de pause longue).
4. Suppression totale des Pièces (Coins) :
   - Supprime toute logique et tout affichage de pièces (coins, coinsPerWorkSession) dans PomodoroState, PomodoroStats, pomodoro_page.dart (_StatsRow), app_config.dart et pomodoro_session_model_test.dart.

## Vérification
Lance uniquement :
flutter test test/features/pomodoro/ test/shared/models/pomodoro_session_model_test.dart test/features/motion/micro_pomodoro_pulse_test.dart
flutter analyze
