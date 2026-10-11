import 'package:cognicquest/features/notes/data/note_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Identifiants générés côté client (fiches, tâches, cartes, journal…) : ils
/// deviennent des clés primaires `uuid` côté Supabase.
void main() {
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('respecte le format UUID v4 (version et variante RFC 4122)', () {
    for (var i = 0; i < 1000; i++) {
      expect(LocalFirstNoteRepository.newId(), matches(uuidV4));
    }
  });

  test('ne produit pas de doublon', () {
    final ids = {for (var i = 0; i < 10000; i++) LocalFirstNoteRepository.newId()};

    expect(ids, hasLength(10000));
  });
}
