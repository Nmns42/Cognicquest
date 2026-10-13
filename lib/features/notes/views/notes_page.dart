import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/note_model.dart';
import '../../settings/providers/settings_provider.dart';
import '../domain/note_search.dart';
import '../providers/note_provider.dart';
import '../widgets/note_filter_sheet.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../review/providers/review_provider.dart';
import '../widgets/folder_explorer.dart';

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
    // Créée depuis un dossier : elle y est rangée d'emblée.
    final folderId = ref.read(folderSelectionProvider).folderId;
    if (note != null && folderId != null) {
      await ref.read(folderActionsProvider).moveNote(note.id, folderId);
    }
    if (note != null && mounted) {
      context.push('${AppRoute.notes}/${note.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final selection = ref.watch(folderSelectionProvider);
    // Explorateur : seules les fiches du dossier choisi.
    final notes = [
      for (final note in ref.watch(filteredNotesProvider))
        if (selection.shows(note.folderId)) note,
    ];
    final filter = ref.watch(noteFilterProvider);
    final pendingSync = ref.watch(unsyncedNotesCountProvider);
    final manualOrder = ref.watch(manualNoteOrderProvider);
    // Ordre manuel : sur la bibliothèque entière seulement.
    final canReorder = ref.watch(canReorderNotesProvider) && selection.isAll;
    final cardsHere = selection.folderId == null
        ? const <Flashcard>[]
        : [
            for (final card in ref.watch(flashcardsProvider).valueOrNull ??
                const <Flashcard>[])
              if (card.folderId == selection.folderId) card,
          ];

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (pendingSync > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: '$pendingSync fiche${pendingSync > 1 ? 's' : ''} '
                    'en attente de synchronisation',
                child: Icon(Icons.cloud_upload_outlined,
                    size: 20, color: context.cq.textMuted),
              ),
            ),
          _SortButton(manual: manualOrder),
          _FilterButton(activeCount: filter.activeFacetCount),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= _explorerWideMin;
          final library = Column(
            children: [
              if (!wide)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Space.md),
                  child: FolderBreadcrumb(),
                ),
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
                  loading: () => Center(
                    child:
                        CircularProgressIndicator(color: context.cq.vertDark),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.cq.textMuted),
                      ),
                    ),
                  ),
                  data: (all) {
                    if (all.isEmpty) {
                      return _EmptyLibrary(onCreate: _createNote);
                    }
                    if (notes.isEmpty &&
                        cardsHere.isEmpty &&
                        !selection.isAll) {
                      return const CqEmptyState(
                        icon: Icons.folder_open_outlined,
                        message:
                            'Ce dossier est vide. Range-y une fiche avec le '
                            'bouton dossier de sa carte.',
                      );
                    }
                    if (notes.isEmpty) {
                      return _NoResults(
                        onReset: () {
                          _searchController.clear();
                          ref.read(noteFilterProvider.notifier).clearAll();
                        },
                      );
                    }
                    return RefreshIndicator(
                      color: context.cq.vertDark,
                      onRefresh: () => ref.read(noteActionsProvider).sync(),
                      // Glisser-déposer seulement en tri « Manuel », sans recherche
                      // ni filtre (cf. canReorderNotesProvider).
                      child: canReorder
                          ? ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                              physics: const AlwaysScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              itemCount: notes.length,
                              onReorderItem: (from, to) => ref
                                  .read(noteActionsProvider)
                                  .move(notes, notes[from].id, to),
                              itemBuilder: (context, index) =>
                                  CqReorderableItem(
                                key: ValueKey(notes[index].id),
                                index: index,
                                child: _NoteCard(note: notes[index]),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                for (final note in notes) _NoteCard(note: note),
                                if (cardsHere.isNotEmpty) ...[
                                  const SizedBox(height: Space.lg),
                                  for (final card in cardsHere)
                                    _FolderCardRow(card: card),
                                ],
                              ],
                            ),
                    );
                  },
                ),
              ),
            ],
          );
          if (!wide) return library;
          // Grand écran : l'arborescence à gauche, le contenu à droite.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _explorerPaneWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      Space.md, Space.sm, Space.sm, Space.xl),
                  child: const FolderTree(),
                ),
              ),
              VerticalDivider(width: 1, color: context.cq.beigeDark),
              Expanded(child: library),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        backgroundColor: context.cq.vert,
        tooltip: 'Nouvelle fiche',
        child: Icon(Icons.add, color: context.onAccent),
      ),
    );
  }
}

/// Largeur à partir de laquelle l'arborescence s'affiche à côté du contenu.
const double _explorerWideMin = 840;
const double _explorerPaneWidth = 264;

/// Carte de révision rangée dans le dossier ouvert.
class _FolderCardRow extends ConsumerWidget {
  const _FolderCardRow({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: CqCard(
        padding: EdgeInsets.zero,
        child: CqListRow(
          title: card.front,
          subtitle: card.back,
          leadingIcon: Icons.style_outlined,
          trailing: IconButton(
            tooltip: 'Ranger dans un dossier',
            icon: Icon(Icons.drive_file_move_outline,
                size: Sizes.iconSm, color: context.cq.textMuted),
            onPressed: () async {
              final choice = await pickFolder(context, ref);
              if (choice == null) return;
              await ref
                  .read(folderActionsProvider)
                  .moveCard(card.id, choice.$2);
            },
          ),
        ),
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

/// Choix du tri : « Récentes » (par défaut) ou « Manuel » (glisser-déposer).
class _SortButton extends ConsumerWidget {
  const _SortButton({required this.manual});

  final bool manual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<bool>(
      popUpAnimationStyle: Motion.style(context),
      tooltip: 'Trier les fiches',
      icon: const Icon(Icons.sort),
      initialValue: manual,
      onSelected: ref.read(settingsProvider.notifier).setManualNoteOrder,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
            value: false, checked: !manual, child: const Text('Récentes')),
        CheckedPopupMenuItem(
            value: true, checked: manual, child: const Text('Manuel')),
      ],
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
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(
                '$activeCount',
                style: TextStyle(
                  color: context.onAccent,
                  fontSize: TypeScale.caption,
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
        label: Text(label, style: const TextStyle(fontSize: TypeScale.caption)),
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
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  String get _dateLabel {
    final now = DateTime.now();
    final d = note.updatedAt;
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
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
                      style: TextStyle(
                        fontSize: TypeScale.bodyLarge,
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
                    tooltip: 'Ranger dans un dossier',
                    icon: Icon(Icons.drive_file_move_outline,
                        size: Sizes.iconSm, color: context.cq.textMuted),
                    onPressed: () async {
                      final choice = await pickFolder(context, ref);
                      if (choice == null) return;
                      await ref
                          .read(folderActionsProvider)
                          .moveNote(note.id, choice.$2);
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: note.isFavorite
                        ? 'Retirer des favorites'
                        : 'Ajouter aux favorites',
                    icon: Icon(
                      note.isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: note.isFavorite
                          ? context.cq.warning
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
                  style: TextStyle(
                      fontSize: TypeScale.body,
                      color: context.cq.textMuted,
                      height: 1.35),
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
                      label: '${note.checklistDone}/${note.checklistTotal}',
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
        borderRadius: BorderRadius.circular(Radii.md),
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
                fontSize: TypeScale.caption,
                color: color,
                fontWeight: FontWeight.w500),
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
                  color: context.cq.textMuted,
                  fontSize: TypeScale.body,
                  height: 1.4),
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
              style: TextStyle(
                  color: context.cq.textMuted, fontSize: TypeScale.body),
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
