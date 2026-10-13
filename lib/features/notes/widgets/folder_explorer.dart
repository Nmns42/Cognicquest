import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/note_model.dart';
import '../../review/providers/review_provider.dart';
import '../data/folder_repository.dart';
import '../providers/note_provider.dart';

/// Ce que montre l'explorateur : tout, ce qui n'est rangé nulle part, ou un
/// dossier précis.
@immutable
class FolderSelection {
  const FolderSelection.all()
      : folderId = null,
        unfiled = false;
  const FolderSelection.unfiled()
      : folderId = null,
        unfiled = true;
  const FolderSelection.folder(String this.folderId) : unfiled = false;

  final String? folderId;
  final bool unfiled;

  bool get isAll => folderId == null && !unfiled;

  /// `true` si une fiche ou une carte rangée dans [itemFolderId] est visible.
  bool shows(String? itemFolderId) {
    if (isAll) return true;
    if (unfiled) return itemFolderId == null;
    return itemFolderId == folderId;
  }

  @override
  bool operator ==(Object other) =>
      other is FolderSelection &&
      other.folderId == folderId &&
      other.unfiled == unfiled;

  @override
  int get hashCode => Object.hash(folderId, unfiled);
}

class FolderSelectionNotifier extends Notifier<FolderSelection> {
  @override
  FolderSelection build() => const FolderSelection.all();

  void select(FolderSelection selection) => state = selection;
}

final folderSelectionProvider =
    NotifierProvider<FolderSelectionNotifier, FolderSelection>(
  FolderSelectionNotifier.new,
);

/// Actions de l'explorateur, une fois le dépôt et les synchronisations
/// branchés.
class FolderActions {
  FolderActions(this._ref);

  final Ref _ref;

  LocalFirstFolderRepository? get _repository =>
      _ref.read(folderRepositoryProvider);

  Future<Folder?> create(String name, {String? parentId}) async =>
      _repository?.create(name, parentId: parentId);

  Future<void> rename(String id, String name) async =>
      _repository?.rename(id, name);

  Future<bool> moveFolder(String id, String? parentId) async =>
      await _repository?.move(id, parentId) ?? false;

  Future<void> delete(String id) async {
    await _repository?.delete(id);
    final selection = _ref.read(folderSelectionProvider);
    if (selection.folderId == id) {
      _ref
          .read(folderSelectionProvider.notifier)
          .select(const FolderSelection.all());
    }
  }

  Future<void> moveNote(String noteId, String? folderId) async {
    await _repository?.moveNote(noteId, folderId);
    _ref.read(noteActionsProvider).sync().ignore();
  }

  Future<void> moveCard(String cardId, String? folderId) async {
    await _repository?.moveCard(cardId, folderId);
    _ref.read(reviewActionsProvider).sync().ignore();
  }
}

final folderActionsProvider = Provider<FolderActions>(FolderActions.new);

/// Nombre d'éléments (fiches et cartes) rangés directement dans chaque
/// dossier ; la clé `null` compte ceux qui ne sont rangés nulle part.
final folderCountsProvider = Provider<Map<String?, int>>((ref) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const <Note>[];
  final cards =
      ref.watch(flashcardsProvider).valueOrNull ?? const <Flashcard>[];
  final counts = <String?, int>{};
  for (final id in [
    ...notes.map((n) => n.folderId),
    ...cards.map((c) => c.folderId),
  ]) {
    counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
});

/// Arborescence des dossiers : « Tout », « Non rangé », puis les dossiers
/// et sous-dossiers, repliables.
class FolderTree extends ConsumerStatefulWidget {
  const FolderTree({super.key, this.onSelected});

  /// Appelé après un choix (pour refermer la feuille sur téléphone).
  final VoidCallback? onSelected;

  @override
  ConsumerState<FolderTree> createState() => _FolderTreeState();
}

class _FolderTreeState extends ConsumerState<FolderTree> {
  final Set<String> _expanded = {};

  void _select(FolderSelection selection) {
    ref.read(folderSelectionProvider.notifier).select(selection);
    widget.onSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider).valueOrNull ?? const <Folder>[];
    final selection = ref.watch(folderSelectionProvider);
    final counts = ref.watch(folderCountsProvider);
    final children = <String?, List<Folder>>{};
    for (final folder in folders) {
      children.putIfAbsent(folder.parentId, () => []).add(folder);
    }

    List<Widget> branch(String? parentId, int depth) => [
          for (final folder in children[parentId] ?? const <Folder>[]) ...[
            _FolderRow(
              folder: folder,
              depth: depth,
              count: counts[folder.id] ?? 0,
              hasChildren: children[folder.id]?.isNotEmpty ?? false,
              expanded: _expanded.contains(folder.id),
              selected: selection.folderId == folder.id,
              onTap: () => _select(FolderSelection.folder(folder.id)),
              onToggle: () => setState(() {
                if (!_expanded.remove(folder.id)) _expanded.add(folder.id);
              }),
              onCreateChild: () async {
                final name =
                    await askFolderName(context, title: 'Nouveau sous-dossier');
                if (name == null) return;
                await ref
                    .read(folderActionsProvider)
                    .create(name, parentId: folder.id);
                setState(() => _expanded.add(folder.id));
              },
            ),
            if (_expanded.contains(folder.id)) ...branch(folder.id, depth + 1),
          ],
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StaticRow(
          icon: Icons.inventory_2_outlined,
          label: 'Tout',
          count: counts.values.fold(0, (a, b) => a + b),
          selected: selection.isAll,
          onTap: () => _select(const FolderSelection.all()),
        ),
        _StaticRow(
          icon: Icons.inbox_outlined,
          label: 'Non rangé',
          count: counts[null] ?? 0,
          selected: selection.unfiled,
          onTap: () => _select(const FolderSelection.unfiled()),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: Space.sm),
          child: Divider(),
        ),
        ...branch(null, 0),
        const SizedBox(height: Space.xs),
        CqButton.text(
          label: 'Nouveau dossier',
          icon: Icons.create_new_folder_outlined,
          onPressed: () async {
            final name = await askFolderName(context, title: 'Nouveau dossier');
            if (name == null) return;
            await ref.read(folderActionsProvider).create(name);
          },
        ),
      ],
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      selected: selected,
      onTap: onTap,
      depth: 0,
      leading: Icon(icon, size: Sizes.iconMd),
      label: label,
      count: count,
    );
  }
}

class _FolderRow extends ConsumerWidget {
  const _FolderRow({
    required this.folder,
    required this.depth,
    required this.count,
    required this.hasChildren,
    required this.expanded,
    required this.selected,
    required this.onTap,
    required this.onToggle,
    required this.onCreateChild,
  });

  final Folder folder;
  final int depth;
  final int count;
  final bool hasChildren;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onCreateChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ink = selected ? context.onAccent : context.cq.textMuted;
    return _RowShell(
      selected: selected,
      onTap: onTap,
      depth: depth,
      leading: hasChildren
          ? InkResponse(
              onTap: onToggle,
              radius: Sizes.iconLg,
              child: Semantics(
                button: true,
                expanded: expanded,
                label: expanded ? 'Replier' : 'Déplier',
                child: Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: Sizes.iconMd,
                  color: ink,
                ),
              ),
            )
          : Icon(
              expanded ? Icons.folder_open_outlined : Icons.folder_outlined,
              size: Sizes.iconMd,
              color: ink,
            ),
      label: folder.name,
      count: count,
      trailing: PopupMenuButton<String>(
        tooltip: 'Actions du dossier',
        popUpAnimationStyle: Motion.style(context),
        icon: Icon(Icons.more_horiz, size: Sizes.iconMd, color: ink),
        onSelected: (action) async {
          final actions = ref.read(folderActionsProvider);
          switch (action) {
            case 'child':
              onCreateChild();
            case 'rename':
              final name = await askFolderName(context,
                  title: 'Renommer', initial: folder.name);
              if (name != null) await actions.rename(folder.id, name);
            case 'delete':
              final confirmed = await _confirmDelete(context, folder);
              if (confirmed) await actions.delete(folder.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'child', child: Text('Nouveau sous-dossier')),
          PopupMenuItem(value: 'rename', child: Text('Renommer')),
          PopupMenuItem(value: 'delete', child: Text('Supprimer')),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text('Supprimer « ${folder.name} » ?'),
        content: const Text(
          'Ses sous-dossiers sont supprimés aussi. Les fiches et les cartes '
          'qu’ils contiennent ne sont pas perdues : elles reviennent dans '
          '« Non rangé ».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: TextStyle(color: context.cq.errorColor)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

/// Ligne commune de l'arborescence : retrait selon la profondeur, sélection
/// sur l'accent, compte discret.
class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.selected,
    required this.onTap,
    required this.depth,
    required this.leading,
    required this.label,
    required this.count,
    this.trailing,
  });

  final bool selected;
  final VoidCallback onTap;
  final int depth;
  final Widget leading;
  final String label;
  final int count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final color = selected ? context.onAccent : cq.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? cq.vert : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sm),
          onTap: onTap,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: Sizes.touchTarget - Space.sm),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                  start: Space.sm + depth * Space.lg, end: Space.xs),
              child: Row(
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                        color: selected ? context.onAccent : cq.textMuted),
                    child: leading,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                  ),
                  if (count > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                      child: Text(
                        '$count',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: selected ? context.onAccent : null),
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fil du dossier courant (téléphone) : un bouton qui ouvre l'arborescence
/// dans une feuille.
class FolderBreadcrumb extends ConsumerWidget {
  const FolderBreadcrumb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(folderSelectionProvider);
    final folders = ref.watch(foldersProvider).valueOrNull ?? const <Folder>[];
    final label = selection.isAll
        ? 'Tout'
        : selection.unfiled
            ? 'Non rangé'
            : folders
                    .where((f) => f.id == selection.folderId)
                    .map((f) => f.name)
                    .firstOrNull ??
                'Dossier';
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => showCqSheet<void>(
          context: context,
          title: 'Dossiers',
          builder: (sheetContext) => FolderTree(
            onSelected: () => Navigator.pop(sheetContext),
          ),
        ),
        icon: const Icon(Icons.folder_outlined, size: Sizes.iconMd),
        label: Text(label),
      ),
    );
  }
}

/// Demande un nom de dossier ; `null` si l'utilisateur annule.
Future<String?> askFolderName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    animationStyle: Motion.style(context),
    builder: (_) => _FolderNameDialog(title: title, initial: initial),
  );
}

/// Le champ vit aussi longtemps que la boîte de dialogue, animation de
/// fermeture comprise (libéré par `dispose`, pas à la réponse).
class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    Navigator.pop(context, value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 120,
        decoration: const InputDecoration(hintText: 'Nom du dossier'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}

/// Choix d'un dossier de destination ; renvoie `(true, id)` (id `null` :
/// « Non rangé »), ou `null` si l'utilisateur annule.
Future<(bool, String?)?> pickFolder(BuildContext context, WidgetRef ref) {
  final folders = ref.read(foldersProvider).valueOrNull ?? const <Folder>[];
  final byParent = <String?, List<Folder>>{};
  for (final folder in folders) {
    byParent.putIfAbsent(folder.parentId, () => []).add(folder);
  }
  List<(Folder, int)> flatten(String? parentId, int depth) => [
        for (final folder in byParent[parentId] ?? const <Folder>[]) ...[
          (folder, depth),
          ...flatten(folder.id, depth + 1),
        ],
      ];
  final entries = flatten(null, 0);

  return showCqSheet<(bool, String?)>(
    context: context,
    title: 'Ranger dans…',
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CqListRow(
          title: 'Non rangé',
          leadingIcon: Icons.inbox_outlined,
          onTap: () => Navigator.pop(sheetContext, (true, null)),
        ),
        for (final (folder, depth) in entries)
          Padding(
            padding: EdgeInsetsDirectional.only(start: depth * Space.lg),
            child: CqListRow(
              title: folder.name,
              leadingIcon: Icons.folder_outlined,
              onTap: () => Navigator.pop(sheetContext, (true, folder.id)),
            ),
          ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text(
              'Aucun dossier pour l’instant : crée-en un depuis l’explorateur.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
          ),
      ],
    ),
  );
}
