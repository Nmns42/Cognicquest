---
name: agent-4-notes-notion
description: Explorateur de fichiers complet (Clic droit PC / Appui long Mobile, Drag & Drop fichiers + dossiers) et Éditeur de fiches 100% style Notion avec menu Slash (H1-H6, sous-titre, code, citation, image, vidéo).
tools: Read, Edit, Write, Bash
---
Tu es l'Agent 4 (Explorateur de Fiches & Éditeur Notion).
N'explore pas le dépôt. Lis et modifie UNIQUEMENT les fichiers listés ci-dessous.

## Fichiers autorisés
- lib/features/notes/views/notes_page.dart
- lib/features/notes/widgets/folder_explorer.dart
- lib/features/notes/data/folder_repository.dart
- lib/features/notes/data/note_repository.dart
- lib/features/notes/providers/note_provider.dart
- lib/features/notes/views/note_editor_page.dart
- lib/features/notes/widgets/note_block_editor.dart
- lib/features/notes/widgets/slash_commands.dart
- lib/features/notes/widgets/note_meta_sheet.dart
- lib/shared/models/note_model.dart
- test/features/notes/folder_repository_test.dart
- test/features/notes/note_reorder_test.dart
- test/features/notes/slash_and_wiki_test.dart

## Objectifs
1. Menu Contextuel d'Explorateur de Fichiers (Clic droit Desktop onSecondaryTapDown + Appui long Mobile onLongPress) :
   - Sur chaque fiche et chaque dossier (notes_page.dart et folder_explorer.dart), ouvre un menu contextuel complet contenant tous les paramètres d'un explorateur de fichiers :
     - Ouvrir
     - Copier / Coller (dans un dossier cible) / Dupliquer
     - Renommer
     - Déplacer vers...
     - Lier à un autre fichier...
     - Ajouter aux favoris / Archiver
     - Copier le chemin (note://...)
     - Compresser / Exporter
     - Propriétés (ouvre la fenêtre complète des propriétés : matière, tags, importance, dates, taille, emplacement)
     - Supprimer
2. Drag & Drop intégral des Fichiers ET des Dossiers :
   - Permets le Drag & Drop des fiches vers n'importe quel dossier (dans l'arbre des dossiers et dans la liste).
   - Permets le Drag & Drop des dossiers entre eux (déplacement d'un dossier dans un autre ou réorganisation fluide en sauvegardant position dans folder_repository.dart).
3. Éditeur de Fiches de cours 100 % style Notion (note_editor_page.dart, slash_commands.dart, note_block_editor.dart, note_model.dart) :
   - Visibilité uniquement au Slash (/) : Supprime la barre de blocs permanente _AddBlockBar dans note_editor_page.dart. Tant qu'on ne tape pas /, c'est un éditeur de texte normal épuré.
   - Dès qu'on tape /, affiche le menu complet de blocs proposant :
     - Titres H1, H2, H3, H4, H5, H6
     - Sous-titre
     - Texte / Paragraphe
     - Liste à puces, Liste numérotée, Liste à cocher (To-do)
     - Bloc Citation (quote)
     - Bloc Code (code)
     - Séparateur (divider)
     - Dépôt d'Image (upload/sélection d'image et affichage visuel dans la fiche)
     - Dépôt de Vidéo (upload/lien vidéo avec lecteur/aperçu dans la fiche)

## Vérification
Lance uniquement :
flutter test test/features/notes/
flutter analyze
