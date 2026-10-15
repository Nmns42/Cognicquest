import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ordering/manual_order.dart';
import '../../../shared/models/note_model.dart';
import '../../settings/providers/settings_provider.dart';
import '../data/note_repository.dart';
import '../domain/note_search.dart';

/// Flux des fiches, alimenté par SQLite.
///
/// `StreamProvider` et non `FutureProvider` : Drift émet une nouvelle liste à
/// chaque écriture locale, donc l'interface se met à jour sans rechargement
/// manuel ni invalidation explicite.
final notesProvider = StreamProvider<List<Note>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  if (repository == null) return Stream.value(const <Note>[]);
  return repository.watchAll();
});

/// Filtre courant de la bibliothèque de fiches.
class NoteFilterNotifier extends Notifier<NoteFilter> {
  @override
  NoteFilter build() => NoteFilter.none;

  void setQuery(String query) => state = state.copyWith(query: query);

  void setSubject(String? subject) => state = subject == null
      ? state.copyWith(clearSubject: true)
      : state.copyWith(subject: subject);

  void toggleTag(String tag) {
    final tags = Set<String>.from(state.tags);
    if (!tags.remove(tag)) tags.add(tag);
    state = state.copyWith(tags: tags);
  }

  void setImportance(NoteImportance? importance) => importance == null
      ? state = state.copyWith(clearImportance: true)
      : state = state.copyWith(importance: importance);

  void setUpdatedAfter(DateTime? date) => date == null
      ? state = state.copyWith(clearUpdatedAfter: true)
      : state = state.copyWith(updatedAfter: date);

  void toggleFavoritesOnly() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);

  void toggleIncludeArchived() =>
      state = state.copyWith(includeArchived: !state.includeArchived);

  /// Efface les facettes mais conserve la recherche en cours : vider un filtre
  /// ne doit pas faire perdre ce que l'utilisateur vient de taper.
  void clearFacets() => state = NoteFilter(query: state.query);

  void clearAll() => state = NoteFilter.none;
}

final noteFilterProvider =
    NotifierProvider<NoteFilterNotifier, NoteFilter>(NoteFilterNotifier.new);

/// Tri « Manuel » choisi (préférence mémorisée et synchronisée).
final manualNoteOrderProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider.select((s) => s.manualNoteOrder)),
);

/// Glisser-déposer possible : tri « Manuel », sans recherche ni filtre — un
/// déplacement dans une liste partielle n'aurait pas de sens pour l'ordre
/// complet.
final canReorderNotesProvider = Provider<bool>(
  (ref) =>
      ref.watch(manualNoteOrderProvider) &&
      !ref.watch(noteFilterProvider).isActive,
);

/// Fiches filtrées et classées par pertinence.
final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  return NoteSearch.apply(
    notes,
    ref.watch(noteFilterProvider),
    manualOrder: ref.watch(manualNoteOrderProvider),
  );
});

/// Sujets disponibles, calculés sur l'ensemble des fiches (pas sur le résultat
/// filtré : sinon sélectionner un sujet ferait disparaître les autres).
final noteSubjectsProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  return NoteSearch.subjectsOf(notes);
});

final noteTagsProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  return NoteSearch.tagsOf(notes);
});

/// Une fiche par identifiant, pour l'éditeur.
final noteByIdProvider = Provider.family<Note?, String>((ref, id) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  for (final note in notes) {
    if (note.id == id) return note;
  }
  return null;
});

/// Nombre de fiches en attente de synchronisation, pour l'indicateur d'état.
final unsyncedNotesCountProvider = Provider<int>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  return notes.where((n) => !n.isSynced).length;
});

/// Actions d'écriture sur les fiches.
class NoteActions {
  const NoteActions(this._ref);

  final Ref _ref;

  NoteRepository? get _repository => _ref.read(noteRepositoryProvider);

  Future<Note?> create({String title = '', String? subject}) =>
      _repository?.create(title: title, subject: subject) ??
      Future.value(null);

  Future<void> save(Note note) async => _repository?.save(note);

  Future<void> delete(String id) async => _repository?.delete(id);

  /// Renomme une fiche.
  Future<void> rename(Note note, String title) =>
      save(note.copyWith(title: title.trim(), updatedAt: DateTime.now()));

  /// Copie complète d'une fiche (texte, métadonnées, blocs), créée à côté de
  /// l'original : « Titre (copie) ». Renvoie la copie, sans dossier : c'est
  /// à l'appelant de la ranger.
  Future<Note?> duplicate(Note note, {String suffix = ' (copie)'}) async {
    final repository = _repository;
    if (repository == null) return null;
    final created = await repository.create(
        title: '${note.displayTitle}$suffix', subject: note.subject);
    final copy = created.copyWith(
      content: note.content,
      tags: note.tags,
      importance: note.importance,
      isFavorite: note.isFavorite,
      blocks: [
        for (final block in note.blocks)
          NoteBlock(
            id: LocalFirstNoteRepository.newId(),
            noteId: created.id,
            type: block.type,
            content: block.content,
            position: block.position,
            isChecked: block.isChecked,
          ),
      ],
    );
    await repository.save(copy);
    return copy;
  }

  Future<void> toggleFavorite(Note note) =>
      save(note.copyWith(isFavorite: !note.isFavorite));

  /// Déplace [noteId] à [newIndex] de la liste affichée [visible] (tri
  /// « Manuel », sans filtre). Une seule écriture dans le cas courant.
  Future<void> move(List<Note> visible, String noteId, int newIndex) async {
    final updates = ManualOrder.planMove(
      [for (final note in visible) OrderedItem(note.id, note.position)],
      noteId,
      newIndex,
    );
    await _repository?.applyPositions(updates);
  }

  Future<void> toggleArchived(Note note) =>
      save(note.copyWith(isArchived: !note.isArchived));

  /// Coche / décoche une case d'une fiche sans réécrire le reste.
  Future<void> toggleBlockCheck(Note note, String blockId) {
    final blocks = [
      for (final block in note.blocks)
        if (block.id == blockId)
          block.copyWith(isChecked: !block.isChecked)
        else
          block,
    ];
    return save(note.copyWith(blocks: blocks));
  }

  Future<void> sync() async {
    try {
      await _repository?.sync();
    } catch (_) {
      // Hors ligne : la file reste en attente, rien n'est perdu.
    }
  }
}

final noteActionsProvider = Provider<NoteActions>(NoteActions.new);
