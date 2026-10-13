import '../../../shared/models/note_model.dart';

/// Liens textuels entre fiches, à la manière d'un wiki : `[[Titre]]`.
///
/// Écrire `[[Cycle de Krebs]]` dans une fiche la relie à la fiche de ce
/// titre : le lien apparaît dans le graphe et devient cliquable dans
/// l'aperçu.
abstract final class WikiLinks {
  /// `[[…]]` sur une seule ligne, sans crochet à l'intérieur.
  static final RegExp pattern = RegExp(r'\[\[([^\[\]\n]+)\]\]');

  /// Titres cités dans [text], sans doublon (casse et espaces ignorés).
  static Set<String> titlesIn(String text) => {
        for (final match in pattern.allMatches(text))
          if (match.group(1)!.trim().isNotEmpty) _key(match.group(1)!),
      };

  /// Fiche désignée par [title] (casse et espaces ignorés), ou `null`.
  static Note? resolve(String title, Iterable<Note> notes) {
    final key = _key(title);
    for (final note in notes) {
      if (_key(note.displayTitle) == key || _key(note.title) == key) {
        return note;
      }
    }
    return null;
  }

  /// Fiches citées par une fiche (texte et blocs), elle-même exclue.
  static List<Note> targetsOf(Note note, Iterable<Note> notes) {
    final titles = {
      ...titlesIn(note.content),
      for (final block in note.blocks) ...titlesIn(block.content),
    };
    final targets = <String, Note>{};
    for (final title in titles) {
      final target = resolve(title, notes);
      if (target != null && target.id != note.id) targets[target.id] = target;
    }
    return targets.values.toList();
  }

  /// Markdown où chaque `[[Titre]]` connu devient un lien interne
  /// `note://<id>` ; un titre inconnu reste lisible, en italique.
  static String toMarkdown(String markdown, Iterable<Note> notes) =>
      markdown.replaceAllMapped(pattern, (match) {
        final title = match.group(1)!.trim();
        final target = resolve(title, notes);
        return target == null ? '*$title*' : '[$title](${uriFor(target.id)})';
      });

  static const String scheme = 'note';

  static String uriFor(String noteId) => '$scheme://$noteId';

  /// Identifiant de fiche d'un lien interne, ou `null` pour un lien externe.
  static String? noteIdOf(String? href) {
    if (href == null || !href.startsWith('$scheme://')) return null;
    return href.substring(scheme.length + 3);
  }

  static String _key(String title) =>
      title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
