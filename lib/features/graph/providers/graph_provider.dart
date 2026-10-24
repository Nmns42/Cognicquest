import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/note_link_model.dart';
import '../../../shared/models/note_model.dart';
import '../../notes/providers/note_provider.dart';
import '../data/note_link_repository.dart';
import '../domain/graph_settings.dart';
import '../domain/knowledge_graph.dart';

final noteLinksProvider = StreamProvider<List<NoteLink>>((ref) {
  final repository = ref.watch(noteLinkRepositoryProvider);
  if (repository == null) return Stream.value(const <NoteLink>[]);
  return repository.watchAll();
});

/// Fiches affichées dans le graphe : les archivées sont exclues, elles
/// encombreraient la carte sans rien apprendre.
final graphNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  return notes.where((n) => !n.isArchived).toList();
});

/// Filtre du graphe par sujet — « Zoom, filtrage et survol des nœuds » (CdC).
final graphSubjectFilterProvider = StateProvider<String?>((ref) => null);

/// Réglages du graphe (filtres, groupes, affichage, forces), mémorisés sur
/// l'appareil.
class GraphSettingsNotifier extends Notifier<GraphSettings> {
  static const String _key = 'cq_graph_settings';

  @override
  GraphSettings build() {
    unawaited(_load());
    return GraphSettings.defaults;
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        state = GraphSettings.fromJson(json);
      }
    } catch (_) {
      // Stockage indisponible : réglages par défaut.
    }
  }

  void update(GraphSettings Function(GraphSettings) change) {
    state = change(state);
    unawaited(_save());
  }

  void reset() {
    state = GraphSettings.defaults;
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(_key, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}

final graphSettingsProvider =
    NotifierProvider<GraphSettingsNotifier, GraphSettings>(
        GraphSettingsNotifier.new);

/// Vue du graphe : filtre par sujet, puis réglages (recherche, orphelins,
/// pièces jointes, fiches inexistantes).
final graphViewProvider = Provider<GraphViewData>((ref) {
  final subject = ref.watch(graphSubjectFilterProvider);
  final all = ref.watch(graphNotesProvider);
  final notes =
      subject == null ? all : all.where((n) => n.subject == subject).toList();
  return GraphView.build(
    notes,
    ref.watch(visibleLinksProvider),
    ref.watch(graphSettingsProvider),
  );
});

/// Nœuds du graphe, après application des filtres.
final graphNodesProvider =
    Provider<List<GraphNode>>((ref) => ref.watch(graphViewProvider).nodes);

/// Liens dont les deux extrémités sont visibles après filtrage.
final visibleLinksProvider = Provider<List<NoteLink>>((ref) {
  final links = ref.watch(noteLinksProvider).valueOrNull ?? const <NoteLink>[];
  final subject = ref.watch(graphSubjectFilterProvider);
  if (subject == null) return links;

  final visibleIds = ref
      .watch(graphNotesProvider)
      .where((n) => n.subject == subject)
      .map((n) => n.id)
      .toSet();

  return links
      .where((l) =>
          visibleIds.contains(l.sourceId) && visibleIds.contains(l.targetId))
      .toList();
});

/// Diagnostic du graphe, calculé sur l'ensemble du carnet (pas sur la vue
/// filtrée : « 3 fiches isolées » doit rester vrai quel que soit le filtre).
final graphInsightsProvider = Provider<GraphInsights>((ref) {
  final links = ref.watch(noteLinksProvider).valueOrNull ?? const <NoteLink>[];
  return KnowledgeGraph.analyse(ref.watch(graphNotesProvider), links);
});

final suggestedLinksProvider = Provider<List<SuggestedLink>>((ref) {
  final links = ref.watch(noteLinksProvider).valueOrNull ?? const <NoteLink>[];
  return KnowledgeGraph.suggest(ref.watch(graphNotesProvider), links);
});

/// Voisins directs d'une fiche, pour le panneau d'aperçu et l'éditeur.
final neighboursProvider =
    Provider.family<List<(Note, NoteLink)>, String>((ref, noteId) {
  final links = ref.watch(noteLinksProvider).valueOrNull ?? const <NoteLink>[];
  return KnowledgeGraph.neighboursOf(
    noteId,
    ref.watch(graphNotesProvider),
    links,
  );
});

class GraphActions {
  const GraphActions(this._ref);

  final Ref _ref;

  NoteLinkRepository? get _repository => _ref.read(noteLinkRepositoryProvider);

  Future<void> link({
    required String sourceId,
    required String targetId,
    NoteLinkType type = NoteLinkType.related,
    String? label,
  }) async =>
      _repository?.link(
        sourceId: sourceId,
        targetId: targetId,
        type: type,
        label: label,
      );

  Future<void> unlink(String linkId) async => _repository?.unlink(linkId);

  Future<void> acceptSuggestion(SuggestedLink suggestion) => link(
        sourceId: suggestion.sourceId,
        targetId: suggestion.targetId,
      );

  Future<void> sync() async {
    try {
      await _repository?.sync();
    } catch (_) {
      // Hors ligne : la file conserve les liens créés.
    }
  }
}

final graphActionsProvider = Provider<GraphActions>(GraphActions.new);
