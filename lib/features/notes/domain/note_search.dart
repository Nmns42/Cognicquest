import '../../../shared/models/note_model.dart';

/// Critères de filtrage — « Filtres par sujet, date, importance, type de
/// contenu » (CdC).
class NoteFilter {
  const NoteFilter({
    this.query = '',
    this.subject,
    this.tags = const {},
    this.importance,
    this.updatedAfter,
    this.favoritesOnly = false,
    this.includeArchived = false,
  });

  final String query;
  final String? subject;
  final Set<String> tags;
  final NoteImportance? importance;
  final DateTime? updatedAfter;
  final bool favoritesOnly;
  final bool includeArchived;

  bool get isActive =>
      query.trim().isNotEmpty ||
      subject != null ||
      tags.isNotEmpty ||
      importance != null ||
      updatedAfter != null ||
      favoritesOnly ||
      includeArchived;

  /// Nombre de filtres actifs hors recherche textuelle, pour la pastille de
  /// la barre d'outils.
  int get activeFacetCount => [
        subject != null,
        tags.isNotEmpty,
        importance != null,
        updatedAfter != null,
        favoritesOnly,
      ].where((active) => active).length;

  NoteFilter copyWith({
    String? query,
    String? subject,
    bool clearSubject = false,
    Set<String>? tags,
    NoteImportance? importance,
    bool clearImportance = false,
    DateTime? updatedAfter,
    bool clearUpdatedAfter = false,
    bool? favoritesOnly,
    bool? includeArchived,
  }) =>
      NoteFilter(
        query: query ?? this.query,
        subject: clearSubject ? null : (subject ?? this.subject),
        tags: tags ?? this.tags,
        importance: clearImportance ? null : (importance ?? this.importance),
        updatedAfter:
            clearUpdatedAfter ? null : (updatedAfter ?? this.updatedAfter),
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        includeArchived: includeArchived ?? this.includeArchived,
      );

  static const NoteFilter none = NoteFilter();
}

/// Moteur de recherche interne des fiches.
///
/// Le CdC demande une « recherche instantanée via moteur interne (fuzzy search
/// JS) ». À l'échelle d'un carnet d'étudiant (quelques centaines de fiches
/// déjà chargées depuis SQLite), un classement en mémoire est instantané et
/// évite d'ajouter FTS5 et sa complexité de migration.
abstract final class NoteSearch {
  /// Applique les facettes, puis classe par pertinence quand une requête
  /// textuelle est présente.
  static List<Note> apply(List<Note> notes, NoteFilter filter) {
    final facetted = notes.where((note) => _matchesFacets(note, filter));

    final query = filter.query.trim().toLowerCase();
    if (query.isEmpty) {
      final results = facetted.toList()
        ..sort((a, b) {
          // Les favorites remontent, puis la modification la plus récente.
          if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
      return results;
    }

    final scored = <(Note, int)>[];
    for (final note in facetted) {
      final score = relevance(note, query);
      if (score > 0) scored.add((note, score));
    }

    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      return b.$1.updatedAt.compareTo(a.$1.updatedAt);
    });

    return scored.map((entry) => entry.$1).toList();
  }

  static bool _matchesFacets(Note note, NoteFilter filter) {
    if (!filter.includeArchived && note.isArchived) return false;
    if (filter.favoritesOnly && !note.isFavorite) return false;

    if (filter.subject != null && note.subject != filter.subject) return false;

    if (filter.importance != null &&
        note.importance != filter.importance!.level) {
      return false;
    }

    if (filter.updatedAfter != null &&
        note.updatedAt.isBefore(filter.updatedAfter!)) {
      return false;
    }

    // Tags : conjonctif. Cocher deux tags cherche les fiches portant les deux,
    // ce qui est le comportement attendu d'un filtre (et non d'une recherche).
    if (filter.tags.isNotEmpty) {
      final noteTags = note.tags.map((t) => t.toLowerCase()).toSet();
      for (final tag in filter.tags) {
        if (!noteTags.contains(tag.toLowerCase())) return false;
      }
    }

    return true;
  }

  /// Score de pertinence d'une fiche pour [query] (0 = pas de correspondance).
  ///
  /// Les champs sont pondérés : un mot trouvé dans le titre pèse plus que dans
  /// le corps, pour qu'une fiche intitulée « Mécanique quantique » sorte avant
  /// une fiche qui ne fait que la citer.
  static int relevance(Note note, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return 0;

    final title = note.title.toLowerCase();
    final subject = (note.subject ?? '').toLowerCase();
    final tags = note.tags.map((t) => t.toLowerCase()).toList();
    final body = note.searchableText;

    var score = 0;

    // Chaque terme doit correspondre quelque part : taper « quantique chap »
    // ne doit pas remonter une fiche qui ne contient que « quantique ».
    for (final term in normalizedQuery.split(RegExp(r'\s+'))) {
      if (term.isEmpty) continue;
      var termScore = 0;

      if (title == term) {
        termScore = 120;
      } else if (title.startsWith(term)) {
        termScore = 90;
      } else if (title.contains(term)) {
        termScore = 70;
      } else if (tags.any((tag) => tag == term)) {
        termScore = 60;
      } else if (tags.any((tag) => tag.contains(term))) {
        termScore = 45;
      } else if (subject.contains(term)) {
        termScore = 40;
      } else if (body.contains(term)) {
        termScore = 25;
      } else if (_isFuzzyMatch(title, term)) {
        // Tolérance aux fautes de frappe, sur le titre uniquement : l'étendre
        // au corps ferait remonter n'importe quoi.
        termScore = 15;
      }

      if (termScore == 0) return 0;
      score += termScore;
    }

    if (note.isFavorite) score += 5;
    return score;
  }

  /// Correspondance approximative : accepte une distance d'édition de 1 pour
  /// les termes courts, 2 au-delà de 5 caractères.
  static bool _isFuzzyMatch(String haystack, String term) {
    if (term.length < 3) return false;
    final tolerance = term.length > 5 ? 2 : 1;

    for (final word in haystack.split(RegExp(r'[\s\-_/]+'))) {
      if (word.isEmpty) continue;
      if ((word.length - term.length).abs() > tolerance) continue;
      if (levenshtein(word, term, cutoff: tolerance) <= tolerance) return true;
    }
    return false;
  }

  /// Distance de Levenshtein, avec abandon anticipé au-delà de [cutoff].
  ///
  /// Implémentée sur deux lignes seulement : la matrice complète serait
  /// inutilement coûteuse en mémoire pour des mots.
  static int levenshtein(String a, String b, {int? cutoff}) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (i) => i);
    var current = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      var rowMin = current[0];

      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        final deletion = previous[j + 1] + 1;
        final insertion = current[j] + 1;
        final substitution = previous[j] + cost;

        var best = deletion < insertion ? deletion : insertion;
        if (substitution < best) best = substitution;
        current[j + 1] = best;
        if (best < rowMin) rowMin = best;
      }

      if (cutoff != null && rowMin > cutoff) return cutoff + 1;

      final swap = previous;
      previous = current;
      current = swap;
    }

    return previous[b.length];
  }

  /// Sujets distincts présents dans le carnet, pour alimenter le filtre.
  static List<String> subjectsOf(List<Note> notes) {
    final subjects = notes
        .map((n) => n.subject)
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return subjects;
  }

  /// Tags distincts, classés par fréquence décroissante — « Mots-clés et tags
  /// dynamiques pour la recherche » (CdC).
  static List<String> tagsOf(List<Note> notes) {
    final counts = <String, int>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        final clean = tag.trim();
        if (clean.isEmpty) continue;
        counts[clean] = (counts[clean] ?? 0) + 1;
      }
    }

    final tags = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return tags;
  }
}
