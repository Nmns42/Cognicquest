import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/note_model.dart';
import '../domain/note_search.dart';
import '../providers/note_provider.dart';
import '../widgets/note_filter_sheet.dart';

/// Bibliothèque de fiches — « Base de données intelligente » du CdC.
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Une synchronisation d'ouverture : les fiches locales s'affichent
    // immédiatement, le réseau rattrape en arrière-plan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noteActionsProvider).sync();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // La recherche est locale donc instantanée, mais on évite de reclasser la
    // liste à chaque frappe sur un gros carnet.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      ref.read(noteFilterProvider.notifier).setQuery(value);
    });
  }

  Future<void> _createNote() async {
    final note = await ref.read(noteActionsProvider).create();
    if (note != null && mounted) {
      context.push('${AppRoute.notes}/${note.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final notes = ref.watch(filteredNotesProvider);
    final filter = ref.watch(noteFilterProvider);
    final pendingSync = ref.watch(unsyncedNotesCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes fiches'),
        actions: [
          if (pendingSync > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: '$pendingSync fiche${pendingSync > 1 ? 's' : ''} '
                    'en attente de synchronisation',
                child:  Icon(Icons.cloud_upload_outlined,
                    size: 20, color: context.cq.textMuted),
              ),
            ),
          IconButton(
            tooltip: 'Graphe de connaissances',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => context.push(AppRoute.graph),
          ),
          _FilterButton(activeCount: filter.activeFacetCount),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _SearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              ref.read(noteFilterProvider.notifier).setQuery('');
            },
          ),
          if (filter.activeFacetCount > 0)
            _ActiveFilterChips(filter: filter),
          Expanded(
            child: notesAsync.when(
              loading: () =>  Center(
                child: CircularProgressIndicator(color: context.cq.vert),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style:  TextStyle(color: context.cq.textMuted),
                  ),
                ),
              ),
              data: (all) {
                if (all.isEmpty) return _EmptyLibrary(onCreate: _createNote);
                if (notes.isEmpty) {
                  return _NoResults(
                    onReset: () {
                      _searchController.clear();
                      ref.read(noteFilterProvider.notifier).clearAll();
                    },
                  );
                }
                return RefreshIndicator(
                  color: context.cq.vert,
                  onRefresh: () => ref.read(noteActionsProvider).sync(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: notes.length,
                    itemBuilder: (context, index) =>
                        _NoteCard(note: notes[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle fiche',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher un titre, un tag, un mot…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Effacer',
                    onPressed: onClear,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends ConsumerWidget {
  const _FilterButton({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Filtres',
          icon: const Icon(Icons.filter_list),
          onPressed: () => NoteFilterSheet.show(context),
        ),
        if (activeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: context.cq.vert,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$activeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveFilterChips extends ConsumerWidget {
  const _ActiveFilterChips({required this.filter});

  final NoteFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(noteFilterProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (filter.subject != null)
            _Chip(
              label: filter.subject!,
              onRemove: () => notifier.setSubject(null),
            ),
          for (final tag in filter.tags)
            _Chip(label: '#$tag', onRemove: () => notifier.toggleTag(tag)),
          if (filter.importance != null)
            _Chip(
              label: filter.importance!.label,
              onRemove: () => notifier.setImportance(null),
            ),
          if (filter.updatedAfter != null)
            _Chip(
              label: 'Depuis le '
                  '${filter.updatedAfter!.day}/${filter.updatedAfter!.month}',
              onRemove: () => notifier.setUpdatedAfter(null),
            ),
          if (filter.favoritesOnly)
            _Chip(
              label: 'Favorites',
              onRemove: notifier.toggleFavoritesOnly,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 14),
        backgroundColor: context.cq.vert.withValues(alpha: 0.1),
        side: BorderSide(color: context.cq.vert.withValues(alpha: 0.3)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  String get _dateLabel {
    final now = DateTime.now();
    final d = note.updatedAt;
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    if (isToday) {
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day} ${_months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importance = NoteImportance.fromLevel(note.importance);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('${AppRoute.notes}/${note.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (importance == NoteImportance.essential)
                     Padding(
                      padding: const EdgeInsets.only(top: 3, right: 6),
                      child: Icon(Icons.priority_high,
                          size: 14, color: context.cq.errorColor),
                    ),
                  Expanded(
                    child: Text(
                      note.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:  TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.cq.textPrimary,
                        height: 1.25,
                      ),
                    ),
                  ),
                  if (!note.isSynced)
                     Padding(
                      padding: const EdgeInsets.only(left: 6, top: 2),
                      child: Icon(Icons.cloud_queue,
                          size: 14, color: context.cq.textHint),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    tooltip: note.isFavorite
                        ? 'Retirer des favorites'
                        : 'Ajouter aux favorites',
                    icon: Icon(
                      note.isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: note.isFavorite
                          ? const Color(0xFFE39A3B)
                          : context.cq.textHint,
                    ),
                    onPressed: () =>
                        ref.read(noteActionsProvider).toggleFavorite(note),
                  ),
                ],
              ),
              if (note.excerpt.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:  TextStyle(
                      fontSize: 13, color: context.cq.textMuted, height: 1.35),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (note.subject != null)
                    _MetaBadge(
                      label: note.subject!,
                      icon: Icons.folder_outlined,
                      color: context.cq.vertDark,
                    ),
                  for (final tag in note.tags.take(3))
                    _MetaBadge(label: '#$tag', color: context.cq.textMuted),
                  if (note.tags.length > 3)
                    _MetaBadge(
                      label: '+${note.tags.length - 3}',
                      color: context.cq.textHint,
                    ),
                  if (note.checklistTotal > 0)
                    _MetaBadge(
                      label:
                          '${note.checklistDone}/${note.checklistTotal}',
                      icon: Icons.check_box_outlined,
                      color: note.checklistDone == note.checklistTotal
                          ? context.cq.vertDark
                          : context.cq.textMuted,
                    ),
                  _MetaBadge(label: _dateLabel, color: context.cq.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.auto_stories_outlined,
                size: 48, color: context.cq.textHint),
            const SizedBox(height: 16),
            Text('Ton carnet est vide',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
             Text(
              'Crée une fiche par notion : « Chapitre 3 — Mécanique '
              'quantique ». Tu pourras les relier entre elles plus tard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.cq.textMuted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Créer ma première fiche'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.search_off, size: 44, color: context.cq.textHint),
            const SizedBox(height: 16),
             Text(
              'Aucune fiche ne correspond.',
              style: TextStyle(color: context.cq.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onReset,
              child: const Text('Réinitialiser la recherche'),
            ),
          ],
        ),
      ),
    );
  }
}
