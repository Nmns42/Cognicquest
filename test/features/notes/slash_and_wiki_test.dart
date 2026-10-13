import 'package:cognicquest/features/notes/domain/wiki_links.dart';
import 'package:cognicquest/features/notes/widgets/slash_commands.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Note _note(String id, String title, {String content = ''}) => Note(
      id: id,
      userId: 'u1',
      title: title,
      content: content,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    );

TextEditingValue _typed(String text) => TextEditingValue(
    text: text, selection: TextSelection.collapsed(offset: text.length));

void main() {
  group('detectTrigger', () {
    test('« / » en début de ligne ou après un espace', () {
      expect(detectTrigger('', _typed('/')), Trigger.slash);
      expect(detectTrigger('Bonjour ', _typed('Bonjour /')), Trigger.slash);
      expect(detectTrigger('a\n', _typed('a\n/')), Trigger.slash);
    });

    test('pas de menu au milieu d’un mot (une URL, une fraction)', () {
      expect(detectTrigger('https:', _typed('https:/')), isNull);
      expect(detectTrigger('1', _typed('1/')), isNull);
    });

    test('« [[ » ouvre le choix d’une fiche', () {
      expect(detectTrigger('Voir [', _typed('Voir [[')), Trigger.wikiLink);
      expect(detectTrigger('Voir ', _typed('Voir [')), isNull);
    });

    test('un collage ou une suppression n’ouvre rien', () {
      expect(detectTrigger('', _typed('texte collé /')), isNull);
      expect(detectTrigger('abc/', _typed('abc')), isNull);
    });
  });

  group('WikiLinks', () {
    final notes = [
      _note('n1', 'Cycle de Krebs'),
      _note('n2', 'Insuffisance cardiaque'),
    ];

    test('reconnaît les titres cités, sans doublon ni sensibilité à la casse',
        () {
      expect(
        WikiLinks.titlesIn('Voir [[Cycle de Krebs]] et [[cycle  de krebs]].'),
        {'cycle de krebs'},
      );
    });

    test('relie seulement les fiches existantes, jamais la fiche elle-même',
        () {
      final note = _note('n2', 'Insuffisance cardiaque',
          content: '[[Cycle de Krebs]] [[Inconnue]] [[Insuffisance cardiaque]]');
      expect(WikiLinks.targetsOf(note, notes).map((n) => n.id), ['n1']);
    });

    test('aperçu : lien interne pour une fiche connue, italique sinon', () {
      final markdown =
          WikiLinks.toMarkdown('[[Cycle de Krebs]] et [[Inconnue]]', notes);
      expect(markdown, '[Cycle de Krebs](note://n1) et *Inconnue*');
      expect(WikiLinks.noteIdOf('note://n1'), 'n1');
      expect(WikiLinks.noteIdOf('https://exemple.fr'), isNull);
    });
  });

  test('menu des blocs : chaque commande a un type de bloc, sauf le lien', () {
    for (final command in SlashCommand.forBlocks) {
      expect(
          command.blockType != null || command == SlashCommand.noteLink, isTrue);
    }
  });
}
