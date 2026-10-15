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

  group('menu « / » complet', () {
    test('titres H1 à H6, sous-titre, listes, citation, code, séparateur, '
        'image, vidéo', () {
      expect(
        SlashCommand.values.map((c) => c.label),
        containsAll([
          'Titre 1', 'Titre 2', 'Titre 3', 'Titre 4', 'Titre 5', 'Titre 6',
          'Sous-titre', 'Texte', 'Liste à puces', 'Liste numérotée',
          'Liste à cocher', 'Citation', 'Code', 'Séparateur', 'Image',
          'Vidéo',
        ]),
      );
    });

    test('chaque niveau de titre insère le bon nombre de « # »', () {
      final headings = [
        SlashCommand.h1, SlashCommand.h2, SlashCommand.h3,
        SlashCommand.h4, SlashCommand.h5, SlashCommand.h6,
      ];
      for (final (i, command) in headings.indexed) {
        expect(command.markdown, '${'#' * (i + 1)} ');
      }
    });

    test('le code et le sous-titre se referment après le curseur', () {
      expect(SlashCommand.code.suffix, '\n```');
      expect(SlashCommand.subtitle.markdown, '_');
      expect(SlashCommand.subtitle.suffix, '_');
    });

    test('image et vidéo ajoutent un bloc média, pas du texte', () {
      expect(SlashCommand.image.isMedia, isTrue);
      expect(SlashCommand.video.isMedia, isTrue);
      expect(SlashCommand.video.blockType, NoteBlockType.video);
      expect(SlashCommand.quote.isMedia, isFalse);
      expect(SlashCommand.forBlocks, containsAll([SlashCommand.image,
          SlashCommand.video]));
    });
  });

  group('blocs média', () {
    final note = Note(
      id: 'n1',
      userId: 'u1',
      title: 'Cellule',
      content: '',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      blocks: const [
        NoteBlock(
            id: 'b1',
            noteId: 'n1',
            type: NoteBlockType.image,
            content: 'data:image/png;base64,AAAA',
            position: 0),
        NoteBlock(
            id: 'b2',
            noteId: 'n1',
            type: NoteBlockType.video,
            content: 'https://youtu.be/abc',
            position: 1),
        NoteBlock(
            id: 'b3',
            noteId: 'n1',
            type: NoteBlockType.paragraph,
            content: 'Mitochondrie',
            position: 2),
      ],
    );

    test('ni l’extrait ni la recherche ne lisent une image ou une vidéo', () {
      expect(note.excerpt, 'Mitochondrie');
      expect(note.searchableText, isNot(contains('base64')));
      expect(note.searchableText, isNot(contains('youtu')));
    });

    test('type vidéo relu depuis sa valeur enregistrée', () {
      expect(NoteBlockType.fromValue('video'), NoteBlockType.video);
      expect(note.blocks[1].toMarkdown(), '[Vidéo](https://youtu.be/abc)');
    });

    test('la taille compte le Markdown complet', () {
      expect(note.sizeInBytes, greaterThan(0));
    });
  });
}
