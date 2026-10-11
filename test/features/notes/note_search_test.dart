import 'package:cognicquest/features/notes/domain/note_search.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:flutter_test/flutter_test.dart';

Note buildNote({
  required String id,
  String title = '',
  String content = '',
  String? subject,
  List<String> tags = const [],
  int importance = 1,
  bool isFavorite = false,
  bool isArchived = false,
  int updatedDaysAgo = 0,
  List<NoteBlock> blocks = const [],
}) {
  final now = DateTime.now();
  return Note(
    id: id,
    userId: 'u1',
    title: title,
    content: content,
    subject: subject,
    tags: tags,
    importance: importance,
    isFavorite: isFavorite,
    isArchived: isArchived,
    createdAt: now.subtract(const Duration(days: 90)),
    updatedAt: now.subtract(Duration(days: updatedDaysAgo)),
    blocks: blocks,
  );
}

void main() {
  group('NoteSearch — classement', () {
    test('le titre pèse plus que le corps', () {
      final titled = buildNote(id: 'a', title: 'Mécanique quantique');
      final mentioned =
          buildNote(id: 'b', title: 'Cours de chimie', content: 'voir quantique');

      final results = NoteSearch.apply(
        [mentioned, titled],
        const NoteFilter(query: 'quantique'),
      );

      expect(results.first.id, 'a');
      expect(results, hasLength(2));
    });

    test('un tag exact bat une occurrence dans le corps', () {
      final tagged = buildNote(id: 'a', title: 'Fiche', tags: ['algèbre']);
      final body = buildNote(id: 'b', title: 'Autre', content: 'un peu d\'algèbre');

      final results = NoteSearch.apply(
        [body, tagged],
        const NoteFilter(query: 'algèbre'),
      );

      expect(results.first.id, 'a');
    });

    test('tous les termes doivent correspondre', () {
      final note = buildNote(id: 'a', title: 'Mécanique quantique');

      expect(
        NoteSearch.apply([note], const NoteFilter(query: 'quantique')),
        hasLength(1),
      );
      // « biologie » n'apparaît nulle part : la fiche doit disparaître.
      expect(
        NoteSearch.apply([note], const NoteFilter(query: 'quantique biologie')),
        isEmpty,
      );
    });

    test('tolère une faute de frappe dans le titre', () {
      final note = buildNote(id: 'a', title: 'Thermodynamique');

      final results = NoteSearch.apply(
        [note],
        const NoteFilter(query: 'thermodynamiqu'),
      );

      expect(results, hasLength(1));
    });

    test('ne remonte rien pour une requête sans rapport', () {
      final note = buildNote(id: 'a', title: 'Thermodynamique');
      expect(
        NoteSearch.apply([note], const NoteFilter(query: 'xylophone')),
        isEmpty,
      );
    });

    test('sans requête, favorites d\'abord puis par date de modification', () {
      final old = buildNote(id: 'old', title: 'Ancienne', updatedDaysAgo: 10);
      final recent = buildNote(id: 'recent', title: 'Récente', updatedDaysAgo: 1);
      final favorite = buildNote(
          id: 'fav', title: 'Favorite', updatedDaysAgo: 30, isFavorite: true);

      final results =
          NoteSearch.apply([old, recent, favorite], NoteFilter.none);

      expect(results.map((n) => n.id), ['fav', 'recent', 'old']);
    });
  });

  group('NoteSearch — facettes', () {
    test('exclut les archivées par défaut, les inclut à la demande', () {
      final notes = [
        buildNote(id: 'a', title: 'Active'),
        buildNote(id: 'b', title: 'Archivée', isArchived: true),
      ];

      expect(NoteSearch.apply(notes, NoteFilter.none), hasLength(1));
      expect(
        NoteSearch.apply(notes, const NoteFilter(includeArchived: true)),
        hasLength(2),
      );
    });

    test('filtre par sujet', () {
      final notes = [
        buildNote(id: 'a', title: 'Un', subject: 'Physique'),
        buildNote(id: 'b', title: 'Deux', subject: 'Chimie'),
      ];

      final results =
          NoteSearch.apply(notes, const NoteFilter(subject: 'Physique'));

      expect(results.single.id, 'a');
    });

    test('les tags se combinent en ET, sans tenir compte de la casse', () {
      final both = buildNote(id: 'a', title: 'A', tags: ['Maths', 'exam']);
      final one = buildNote(id: 'b', title: 'B', tags: ['maths']);

      final results = NoteSearch.apply(
        [both, one],
        const NoteFilter(tags: {'maths', 'EXAM'}),
      );

      expect(results.single.id, 'a');
    });

    test('filtre par importance', () {
      final notes = [
        buildNote(id: 'a', title: 'A', importance: 2),
        buildNote(id: 'b', title: 'B', importance: 1),
      ];

      final results = NoteSearch.apply(
        notes,
        const NoteFilter(importance: NoteImportance.essential),
      );

      expect(results.single.id, 'a');
    });

    test('filtre par date de modification', () {
      final notes = [
        buildNote(id: 'recent', title: 'Récente', updatedDaysAgo: 1),
        buildNote(id: 'old', title: 'Ancienne', updatedDaysAgo: 40),
      ];

      final results = NoteSearch.apply(
        notes,
        NoteFilter(
          updatedAfter: DateTime.now().subtract(const Duration(days: 7)),
        ),
      );

      expect(results.single.id, 'recent');
    });

    test('combine recherche et facette', () {
      final notes = [
        buildNote(id: 'a', title: 'Quantique', subject: 'Physique'),
        buildNote(id: 'b', title: 'Quantique', subject: 'Chimie'),
      ];

      final results = NoteSearch.apply(
        notes,
        const NoteFilter(query: 'quantique', subject: 'Chimie'),
      );

      expect(results.single.id, 'b');
    });
  });

  group('NoteSearch.levenshtein', () {
    test('mesure les distances usuelles', () {
      expect(NoteSearch.levenshtein('chat', 'chat'), 0);
      expect(NoteSearch.levenshtein('chat', 'chats'), 1);
      expect(NoteSearch.levenshtein('chat', 'char'), 1);
      expect(NoteSearch.levenshtein('', 'abc'), 3);
    });

    test('l\'abandon anticipé ne dépasse jamais cutoff + 1', () {
      final distance =
          NoteSearch.levenshtein('abcdefgh', 'zzzzzzzz', cutoff: 2);
      expect(distance, lessThanOrEqualTo(3));
    });
  });

  group('NoteSearch — facettes disponibles', () {
    test('liste les sujets distincts, triés', () {
      final notes = [
        buildNote(id: 'a', subject: 'Physique'),
        buildNote(id: 'b', subject: 'Chimie'),
        buildNote(id: 'c', subject: 'Physique'),
        buildNote(id: 'd'),
      ];

      expect(NoteSearch.subjectsOf(notes), ['Chimie', 'Physique']);
    });

    test('classe les tags par fréquence décroissante', () {
      final notes = [
        buildNote(id: 'a', tags: ['exam', 'maths']),
        buildNote(id: 'b', tags: ['maths']),
        buildNote(id: 'c', tags: ['maths', 'exam']),
      ];

      expect(NoteSearch.tagsOf(notes), ['maths', 'exam']);
    });
  });

  group('Note — décodage des tags', () {
    test('accepte une liste (Supabase jsonb)', () {
      expect(Note.decodeTags(['a', 'b']), ['a', 'b']);
    });

    test('accepte une chaîne JSON (SQLite)', () {
      expect(Note.decodeTags('["a","b"]'), ['a', 'b']);
    });

    test('tolère une liste séparée par des virgules', () {
      expect(Note.decodeTags('a, b'), ['a', 'b']);
    });

    test('rend une liste vide pour null ou une chaîne vide', () {
      expect(Note.decodeTags(null), isEmpty);
      expect(Note.decodeTags(''), isEmpty);
    });

    test('fait l\'aller-retour d\'encodage', () {
      expect(Note.decodeTags(Note.encodeTags(['x', ' y ', ''])), ['x', 'y']);
    });
  });

  group('Note — rendu et extraits', () {
    test('rend les blocs en Markdown', () {
      final note = buildNote(
        id: 'a',
        title: 'Fiche',
        blocks: [
          const NoteBlock(
            id: 'b1',
            noteId: 'a',
            type: NoteBlockType.todo,
            content: 'Réviser',
            position: 0,
            isChecked: true,
          ),
          const NoteBlock(
            id: 'b2',
            noteId: 'a',
            type: NoteBlockType.quote,
            content: 'Citation',
            position: 1,
          ),
        ],
      );

      final markdown = note.toMarkdown();
      expect(markdown, contains('# Fiche'));
      expect(markdown, contains('- [x] Réviser'));
      expect(markdown, contains('> Citation'));
    });

    test('compte l\'avancement des cases à cocher', () {
      final note = buildNote(
        id: 'a',
        blocks: [
          const NoteBlock(
              id: 'b1', noteId: 'a', type: NoteBlockType.todo,
              content: 'x', position: 0, isChecked: true),
          const NoteBlock(
              id: 'b2', noteId: 'a', type: NoteBlockType.todo,
              content: 'y', position: 1),
          const NoteBlock(
              id: 'b3', noteId: 'a', type: NoteBlockType.paragraph,
              content: 'z', position: 2),
        ],
      );

      expect(note.checklistTotal, 2);
      expect(note.checklistDone, 1);
    });

    test('remplace un titre vide par « Sans titre »', () {
      expect(buildNote(id: 'a', title: '   ').displayTitle, 'Sans titre');
    });
  });
}
