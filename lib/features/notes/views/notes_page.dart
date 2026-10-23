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
import '../data/folder_repository.dart';
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
        title: const Text("Fiches d'apprentissage"),
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
                    final subfolders = [
                      for (final folder in ref.watch(foldersProvider).valueOrNull ??
                          const <Folder>[])
                        if (!selection.unfiled &&
                            folder.parentId == selection.folderId)
                          folder,
                    ];
                    if (notes.isEmpty &&
                        cardsHere.isEmpty &&
                        subfolders.isEmpty &&
                        !selection.isAll) {
                      return const CqEmptyState(
                        icon: Icons.folder_open_outlined,
                        message:
                            'Ce dossier est vide. Glisses-y une fiche, ou '
                            'utilise « Déplacer vers… » dans son menu.',
                      );
                    }
                    final folderRows = _FolderRows(
                      folders: subfolders,
                      parentOf: selection.folderId,
                    );
                    if (notes.isEmpty && subfolders.isEmpty) {
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
                              padding: const EdgeInsets.fromLTRB(
                                  Space.xl, Space.xs, Space.xl, Space.xxxl * 2),
                              physics: const AlwaysScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              header: folderRows,
                              itemCount: notes.length,
                              onReorderItem: (from, to) => ref
                                  .read(noteActionsProvider)
                                  .move(notes, notes[from].id, to),
                              itemBuilder: (context, index) =>
                                  CqReorderableItem(
                                key: ValueKey(notes[index].id),
                                index: index,
                                // L'appui long réordonne : pas de glisser
                                // vers un dossier dans ce mode.
                                child: _NoteCard(
                                    note: notes[index], draggable: false),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  Space.xl, Space.xs, Space.xl, Space.xxxl * 2),
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                folderRows,
                                for (final note in notes) _NoteCard(note: note),
                                if (cardsHere.isNotEmpty) ...[
                                  const SizedBox(height: Space.xl),
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

/// Largeur de ligne sous laquelle la date passe sous le titre d'une fiche.
const double _compactRowMax = 520;

/// Largeur à partir de laquelle l'arborescence s'affiche à côté du contenu.
const double _explorerWideMin = 840;
const double _explorerPaneWidth = 264;

/// Carte de révision rangée dans le dossier ouvert : ligne dense.
class _FolderCardRow extends ConsumerWidget {
  const _FolderCardRow({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DenseRow(
      icon: Icons.style_outlined,
      title: card.front,
      subtitle: card.back,
      trailing: IconButton(
        tooltip: 'Ranger dans un dossier',
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.drive_file_move_outline,
            size: Sizes.iconSm, color: context.cq.textMuted),
        onPressed: () async {
          final choice = await pickFolder(context, ref);
          if (choice == null) return;
          await ref.read(folderActionsProvider).moveCard(card.id, choice.$2);
        },
      ),
    );
  }
}

/// Ligne de liste façon Notion : posée sur le fond, filet d'un pixel
/// dessous, aplat discret au survol. Icône linéaire, titre, sous-titre en
/// écorce.
class _DenseRow extends StatelessWidget {
  const _DenseRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cq.beigeDark)),
      ),
      child: InkWell(
        onTap: onTap,
        hoverColor: cq.sauge,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.sm, vertical: Space.sm),
            child: Row(
              children: [
                Icon(icon, size: Sizes.iconMd, color: cq.textMuted),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: TypeScale.body,
                          fontWeight: FontWeight.w600,
                          color: cq.textPrimary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: TypeScale.caption, color: cq.terre),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
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
    final cq = context.cq;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.sm),
      borderSide: BorderSide(color: cq.beigeDark),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.xs, Space.xl, Space.md),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher un titre, un tag, un mot…',
          // Champ blanc et net, filet d'un pixel (pas d'aplat teinté).
          filled: true,
          fillColor: cq.cardColor,
          isDense: true,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
              borderSide: BorderSide(color: cq.vertSauge, width: Borders.focus)),
          prefixIcon: Icon(Icons.search, size: Sizes.iconMd, color: cq.textHint),
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
                color: context.cq.vertSauge,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(
                '$activeCount',
                style: TextStyle(
                  color: context.cq.beige,
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
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
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
        label: Text(label,
            style: TextStyle(
                fontSize: TypeScale.caption,
                fontWeight: FontWeight.w600,
                color: context.cq.vertSauge)),
        onDeleted: onRemove,
        deleteIcon: Icon(Icons.close, size: 14, color: context.cq.vertSauge),
        backgroundColor: context.cq.sauge,
        side: BorderSide(color: context.cq.beigeDark),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note, this.draggable = true});

  final Note note;

  /// Glisser la carte vers un dossier (désactivé en tri « Manuel », où
  /// l'appui long réordonne la liste).
  final bool draggable;

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

    // Clic droit / appui long : menu de l'explorateur ; glisser : ranger la
    // fiche dans un dossier (arborescence ou dossiers en tête de liste).
    return ExplorerItemShell(
      item: NoteItem(note.id),
      label: note.displayTitle,
      icon: Icons.description_outlined,
      draggable: draggable,
      onMenu: (position) => showNoteMenu(context, ref, note, position),
      child: _card(context, ref, importance),
    );
  }

  Widget _card(
      BuildContext context, WidgetRef ref, NoteImportance importance) {
    final cq = context.cq;
    return LayoutBuilder(builder: (context, box) {
    // Écran étroit : date et état de synchronisation passent sous le titre,
    // qui garde toute la largeur.
    final compact = box.maxWidth < _compactRowMax;
    final date = Text(
      _dateLabel,
      style: TextStyle(
        fontSize: TypeScale.caption,
        color: cq.textMuted,
        fontFeatures: TypeScale.tabular,
      ),
    );
    final unsynced =
        Icon(Icons.cloud_queue, size: Sizes.iconSm, color: cq.textHint);
    return DecoratedBox(
      // Ligne façon Notion : filet d'un pixel, pas de carte.
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cq.beigeDark)),
      ),
      child: InkWell(
        onTap: () => context.push('${AppRoute.notes}/${note.id}'),
        hoverColor: cq.sauge,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.sm, Space.md, Space.xs, Space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: Space.xs / 2),
                child: Icon(
                  importance == NoteImportance.essential
                      ? Icons.priority_high
                      : Icons.description_outlined,
                  size: Sizes.iconMd,
                  color: importance == NoteImportance.essential
                      ? cq.terre
                      : cq.textMuted,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: TypeScale.body,
                        fontWeight: FontWeight.w600,
                        color: cq.textPrimary,
                      ),
                    ),
                    if (note.excerpt.isNotEmpty)
                      Text(
                        note.excerpt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: TypeScale.caption, color: cq.terre),
                      ),
                    if (compact ||
                        note.subject != null ||
                        note.tags.isNotEmpty ||
                        note.checklistTotal > 0) ...[
                      const SizedBox(height: Space.xs),
                      Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (note.subject != null)
                            _MetaBadge(
                                label: note.subject!, color: cq.vertSauge),
                          for (final tag in note.tags.take(3))
                            _MetaBadge(label: '#$tag', color: cq.terre),
                          if (note.tags.length > 3)
                            _MetaBadge(
                              label: '+${note.tags.length - 3}',
                              color: cq.textMuted,
                            ),
                          if (note.checklistTotal > 0)
                            _MetaBadge(
                              label:
                                  '${note.checklistDone}/${note.checklistTotal}',
                              icon: Icons.check_box_outlined,
                              color: note.checklistDone == note.checklistTotal
                                  ? cq.vertSauge
                                  : cq.textMuted,
                            ),
                          if (compact) date,
                          if (compact && !note.isSynced) unsynced,
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: Space.sm),
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs / 2),
                  child: date,
                ),
                if (!note.isSynced)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: Space.xs, top: Space.xs / 2),
                    child: unsynced,
                  ),
              ],
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: note.isFavorite
                    ? 'Retirer des favorites'
                    : 'Ajouter aux favorites',
                icon: Icon(
                  note.isFavorite ? Icons.star : Icons.star_border,
                  size: Sizes.iconSm,
                  color: note.isFavorite ? cq.warning : cq.textHint,
                ),
                onPressed: () =>
                    ref.read(noteActionsProvider).toggleFavorite(note),
              ),
              // Le même menu que le clic droit, accessible au clavier et
              // aux lecteurs d'écran.
              Builder(
                builder: (buttonContext) => IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Actions de la fiche',
                  icon: Icon(Icons.more_horiz,
                      size: Sizes.iconSm, color: cq.textMuted),
                  onPressed: () {
                    final box = buttonContext.findRenderObject() as RenderBox;
                    showNoteMenu(context, ref, note,
                        box.localToGlobal(box.size.bottomLeft(Offset.zero)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    });
  }
}

/// Dossiers en tête de liste, comme dans un explorateur de fichiers : un
/// appui les ouvre, on y dépose une fiche ou un dossier. Dans un dossier,
/// la première ligne remonte au dossier parent (et reçoit aussi les dépôts).
class _FolderRows extends ConsumerWidget {
  const _FolderRows({required this.folders, required this.parentOf});

  final List<Folder> folders;

  /// Dossier ouvert (`null` : vue « Tout »).
  final String? parentOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(foldersProvider).valueOrNull ?? const <Folder>[];
    final current = all.where((f) => f.id == parentOf).firstOrNull;
    final select = ref.read(folderSelectionProvider.notifier).select;
    if (folders.isEmpty && current == null) return const SizedBox.shrink();

    Widget row({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) =>
        _DenseRow(icon: icon, title: title, onTap: onTap);

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        children: [
          if (current != null)
            Padding(
              padding: EdgeInsets.zero,
              child: FolderDropTarget(
                folderId: current.parentId,
                child: row(
                  icon: Icons.arrow_upward,
                  title: 'Dossier parent',
                  onTap: () => select(current.parentId == null
                      ? const FolderSelection.all()
                      : FolderSelection.folder(current.parentId!)),
                ),
              ),
            ),
          for (final folder in folders)
            Padding(
              padding: EdgeInsets.zero,
              child: FolderDropTarget(
                folderId: folder.id,
                child: ExplorerItemShell(
                  item: FolderItem(folder.id),
                  label: folder.name,
                  icon: Icons.folder_outlined,
                  onMenu: (position) =>
                      showFolderMenu(context, ref, folder, position),
                  child: row(
                    icon: Icons.folder_outlined,
                    title: folder.name,
                    onTap: () => select(FolderSelection.folder(folder.id)),
                  ),
                ),
              ),
            ),
        ],
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
      padding: const EdgeInsets.symmetric(
          horizontal: Space.sm, vertical: Space.xs / 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          // Un tag long, à 200 % de texte, se tronque au lieu de déborder.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: TypeScale.caption,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
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
