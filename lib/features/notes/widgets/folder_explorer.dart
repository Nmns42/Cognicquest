import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/ordering/manual_order.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../../shared/models/note_model.dart';
import '../../../router/app_router.dart';
import '../../graph/providers/graph_provider.dart';
import '../../review/providers/review_provider.dart';
import '../data/folder_repository.dart';
import '../providers/note_provider.dart';
import 'note_meta_sheet.dart';
import 'slash_commands.dart';

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
        // Déposer sur « Tout » ou « Non rangé » : la fiche sort de son
        // dossier, le dossier remonte à la racine.
        FolderDropTarget(
          folderId: null,
          child: _StaticRow(
            icon: Icons.inventory_2_outlined,
            label: 'Tout',
            count: counts.values.fold(0, (a, b) => a + b),
            selected: selection.isAll,
            onTap: () => _select(const FolderSelection.all()),
          ),
        ),
        FolderDropTarget(
          folderId: null,
          child: _StaticRow(
            icon: Icons.inbox_outlined,
            label: 'Non rangé',
            count: counts[null] ?? 0,
            selected: selection.unfiled,
            onTap: () => _select(const FolderSelection.unfiled()),
          ),
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
    final row = _RowShell(
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
      trailing: Builder(
        builder: (buttonContext) => IconButton(
          tooltip: 'Actions du dossier',
          icon: Icon(Icons.more_horiz, size: Sizes.iconMd, color: ink),
          onPressed: () {
            final box = buttonContext.findRenderObject() as RenderBox;
            showFolderMenu(context, ref, folder,
                box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                onCreateChild: onCreateChild);
          },
        ),
      ),
    );
    // Clic droit / appui long : menu complet ; glisser : déplacer le dossier
    // dans un autre, ou le placer avant / après un dossier frère.
    return FolderDropTarget(
      folderId: folder.id,
      reorderable: true,
      child: ExplorerItemShell(
        item: FolderItem(folder.id),
        label: folder.name,
        icon: Icons.folder_outlined,
        onMenu: (position) => showFolderMenu(context, ref, folder, position,
            onCreateChild: onCreateChild),
        child: row,
      ),
    );
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
  String hint = 'Nom du dossier',
}) {
  return showDialog<String>(
    context: context,
    animationStyle: Motion.style(context),
    builder: (_) =>
        _FolderNameDialog(title: title, initial: initial, hint: hint),
  );
}

/// Le champ vit aussi longtemps que la boîte de dialogue, animation de
/// fermeture comprise (libéré par `dispose`, pas à la réponse).
class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog(
      {required this.title, required this.initial, required this.hint});

  final String title;
  final String initial;
  final String hint;

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
        decoration: InputDecoration(hintText: widget.hint),
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

// ─── Explorateur : presse-papiers, glisser-déposer, menu contextuel ────────

/// Élément de l'explorateur : une fiche ou un dossier. Sert de contenu au
/// presse-papiers interne et de donnée au glisser-déposer.
@immutable
sealed class ExplorerItem {
  const ExplorerItem(this.id);

  final String id;
}

class NoteItem extends ExplorerItem {
  const NoteItem(super.id);
}

class FolderItem extends ExplorerItem {
  const FolderItem(super.id);
}

/// « Copier » de l'explorateur : l'élément à coller ensuite dans un dossier.
class ExplorerClipboard extends Notifier<ExplorerItem?> {
  @override
  ExplorerItem? build() => null;

  void copy(ExplorerItem item) => state = item;
}

final explorerClipboardProvider =
    NotifierProvider<ExplorerClipboard, ExplorerItem?>(ExplorerClipboard.new);

/// Chemin lisible d'un dossier : « Biologie / Cellule ». Vide à la racine.
String folderPath(String? folderId, List<Folder> folders) {
  final byId = {for (final f in folders) f.id: f};
  final names = <String>[];
  var current = folderId == null ? null : byId[folderId];
  final seen = <String>{};
  while (current != null && seen.add(current.id)) {
    names.insert(0, current.name);
    current = current.parentId == null ? null : byId[current.parentId];
  }
  return names.join(' / ');
}

/// Lien interne d'une fiche (ouvre la fiche, cf. `WikiLinks`) ou d'un
/// dossier.
String explorerUri(ExplorerItem item) => switch (item) {
      NoteItem(:final id) => 'note://$id',
      FolderItem(:final id) => 'note://folder/$id',
    };

/// Nom de fichier sans caractère interdit sur Windows, macOS ou Linux.
String safeFileName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), '-').trim();
  return cleaned.isEmpty ? 'sans-titre' : cleaned;
}

/// Actions de l'explorateur qui portent sur plusieurs éléments à la fois
/// (copie de dossier, collage, placement, export).
extension ExplorerFolderActions on FolderActions {
  List<Folder> get _folders =>
      _ref.read(foldersProvider).valueOrNull ?? const <Folder>[];

  List<Note> get _notes => _ref.read(notesProvider).valueOrNull ?? const [];

  /// Duplique une fiche dans [folderId] (`null` : racine).
  Future<Note?> duplicateNote(Note note, String? folderId,
      {String suffix = ' (copie)'}) async {
    final copy =
        await _ref.read(noteActionsProvider).duplicate(note, suffix: suffix);
    if (copy != null && folderId != null) await moveNote(copy.id, folderId);
    return copy;
  }

  /// Copie récursive d'un dossier (sous-dossiers et fiches) sous [parentId].
  /// Le contenu est lu avant toute création : coller un dossier dans
  /// lui-même ne boucle pas.
  Future<Folder?> duplicateFolder(String folderId, String? parentId,
      {String suffix = ' (copie)'}) async {
    final folders = _folders;
    final notes = _notes;
    Future<Folder?> copy(String id, String? into, String suffix) async {
      final source = folders.where((f) => f.id == id).firstOrNull;
      if (source == null) return null;
      final created = await create('${source.name}$suffix', parentId: into);
      if (created == null) return null;
      for (final note in notes.where((n) => n.folderId == id)) {
        await duplicateNote(note, created.id, suffix: '');
      }
      for (final child in folders.where((f) => f.parentId == id)) {
        await copy(child.id, created.id, '');
      }
      return created;
    }

    return copy(folderId, parentId, suffix);
  }

  /// Colle le contenu du presse-papiers dans [folderId] (`null` : racine).
  Future<void> paste(String? folderId) async {
    final item = _ref.read(explorerClipboardProvider);
    switch (item) {
      case NoteItem(:final id):
        final note = _notes.where((n) => n.id == id).firstOrNull;
        if (note != null) await duplicateNote(note, folderId);
      case FolderItem(:final id):
        await duplicateFolder(id, folderId);
      case null:
        return;
    }
  }

  /// Place un dossier : sous [parentId], et, si [siblingId] est donné,
  /// juste avant (ou après, [after]) ce dossier frère. L'ordre est
  /// enregistré (clé d'ordre) et synchronisé. `false` si le déplacement est
  /// impossible (dossier glissé dans lui-même ou un descendant).
  Future<bool> placeFolder(String id, String? parentId,
      {String? siblingId, bool after = false}) async {
    final repository = _repository;
    if (repository == null || id == siblingId) return false;
    final folders = _folders;
    final moved = folders.where((f) => f.id == id).firstOrNull;
    if (moved == null) return false;
    if (moved.parentId != parentId) {
      if (!await repository.move(id, parentId)) return false;
    }
    if (siblingId == null) return true;
    final siblings = [
      for (final f in folders)
        if (f.parentId == parentId && f.id != id) f,
    ];
    var index = siblings.indexWhere((f) => f.id == siblingId);
    if (index < 0) return true;
    if (after) index++;
    final updates = ManualOrder.planMove(
      [
        for (final f in siblings) OrderedItem(f.id, f.position),
        OrderedItem(id, moved.position),
      ],
      id,
      index,
    );
    await repository.applyPositions(updates);
    return true;
  }

  /// Archive `.zip` d'un dossier : une fiche Markdown par fichier, rangée
  /// dans l'arborescence des sous-dossiers.
  Future<Uint8List> zipFolder(String folderId) async {
    final folders = _folders;
    final ids = await _repository?.subtreeOf(folderId) ?? {folderId};
    final root = folders.where((f) => f.id == folderId).firstOrNull;
    final rootPath = folderPath(root?.parentId, folders);
    final archive = Archive();
    final used = <String>{};
    for (final note in _notes.where((n) => ids.contains(n.folderId))) {
      var path = folderPath(note.folderId, folders);
      if (rootPath.isNotEmpty && path.startsWith(rootPath)) {
        path = path.substring(rootPath.length + 3);
      }
      final dir = path.split(' / ').map(safeFileName).join('/');
      var name = '$dir/${safeFileName(note.displayTitle)}.md';
      for (var i = 2; !used.add(name); i++) {
        name = '$dir/${safeFileName(note.displayTitle)} ($i).md';
      }
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(note.toMarkdown())));
    }
    return ZipEncoder().encodeBytes(archive);
  }
}

/// Archive `.zip` d'une seule fiche.
Uint8List zipNote(Note note) {
  final archive = Archive()
    ..addFile(ArchiveFile.bytes(
        '${safeFileName(note.displayTitle)}.md', utf8.encode(note.toMarkdown())));
  return ZipEncoder().encodeBytes(archive);
}

/// Propose d'enregistrer [bytes] sous [fileName] (boîte « Enregistrer
/// sous » du système, téléchargement sur le web).
Future<void> saveExport(BuildContext context, String fileName, Uint8List bytes,
    {required String mimeType}) async {
  try {
    final uri = await FilePicker.saveFile(
        fileName: fileName, bytes: bytes, mimeType: mimeType);
    if (uri != null) {
      if (!context.mounted) return;
      _snack(context, '« $fileName » exporté.');
    }
  } catch (_) {
    if (!context.mounted) return;
    _snack(context, 'Export impossible sur cet appareil.');
  }
}

/// Enveloppe d'un élément de l'explorateur : menu contextuel au clic droit
/// (ordinateur) ou à l'appui long (téléphone), et glisser-déposer vers un
/// dossier.
///
/// Sur téléphone, l'appui long sert aux deux : appui long puis glisser
/// déplace l'élément ; appui long relâché sur place ouvre le menu.
class ExplorerItemShell extends StatefulWidget {
  const ExplorerItemShell({
    super.key,
    required this.item,
    required this.label,
    required this.icon,
    required this.onMenu,
    required this.child,
    this.draggable = true,
  });

  final ExplorerItem item;

  /// Nom affiché pendant le glisser.
  final String label;
  final IconData icon;

  /// Ouvre le menu contextuel à cette position (coordonnées globales).
  final ValueChanged<Offset> onMenu;
  final Widget child;

  /// `false` quand l'appui long sert déjà à réordonner la liste.
  final bool draggable;

  @override
  State<ExplorerItemShell> createState() => _ExplorerItemShellState();
}

class _ExplorerItemShellState extends State<ExplorerItemShell> {
  Offset? _pointerDown;

  bool get _touch =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final longPressMenu = !_touch || !widget.draggable;
    final content = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) => widget.onMenu(details.globalPosition),
      onLongPressStart: longPressMenu
          ? (details) => widget.onMenu(details.globalPosition)
          : null,
      child: widget.child,
    );
    if (!widget.draggable) return content;

    final feedback = Material(
      color: context.cq.cardColor,
      elevation: Chrome.sheetElevation,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.md, vertical: Space.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: Sizes.iconMd, color: context.cq.textMuted),
            const SizedBox(width: Space.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
    final dimmed = Opacity(opacity: 0.4, child: widget.child);

    if (_touch) {
      return Listener(
        onPointerDown: (event) => _pointerDown = event.position,
        child: LongPressDraggable<ExplorerItem>(
          data: widget.item,
          feedback: feedback,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          childWhenDragging: dimmed,
          onDraggableCanceled: (_, offset) {
            final down = _pointerDown;
            if (down != null && (offset - down).distance < Space.lg) {
              widget.onMenu(down);
            }
          },
          child: content,
        ),
      );
    }
    return Draggable<ExplorerItem>(
      data: widget.item,
      feedback: feedback,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      childWhenDragging: dimmed,
      child: content,
    );
  }
}

/// Où tombe un dossier glissé sur un autre : avant, dedans ou après.
enum _DropZone { before, inside, after }

/// Cible de dépôt d'un dossier (ou de la racine, [folderId] `null`) : on y
/// range une fiche, on y déplace un dossier. Sur une ligne de dossier
/// ([reorderable]), le haut et le bas de la ligne placent le dossier glissé
/// avant ou après, le milieu le range dedans.
class FolderDropTarget extends ConsumerStatefulWidget {
  const FolderDropTarget({
    super.key,
    required this.folderId,
    required this.child,
    this.reorderable = false,
  });

  final String? folderId;
  final bool reorderable;
  final Widget child;

  @override
  ConsumerState<FolderDropTarget> createState() => _FolderDropTargetState();
}

class _FolderDropTargetState extends ConsumerState<FolderDropTarget> {
  _DropZone? _zone;

  _DropZone _zoneAt(Offset global, ExplorerItem item) {
    if (!widget.reorderable || item is! FolderItem) return _DropZone.inside;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return _DropZone.inside;
    final y = box.globalToLocal(global).dy / box.size.height;
    if (y < 0.25) return _DropZone.before;
    if (y > 0.75) return _DropZone.after;
    return _DropZone.inside;
  }

  Future<void> _accept(ExplorerItem item, _DropZone zone) async {
    final actions = ref.read(folderActionsProvider);
    switch (item) {
      case NoteItem(:final id):
        await actions.moveNote(id, widget.folderId);
      case FolderItem(:final id):
        final target = widget.folderId;
        final bool ok;
        if (zone == _DropZone.inside || target == null) {
          ok = await actions.placeFolder(id, target);
        } else {
          final folders =
              ref.read(foldersProvider).valueOrNull ?? const <Folder>[];
          final sibling = folders.where((f) => f.id == target).firstOrNull;
          ok = await actions.placeFolder(id, sibling?.parentId,
              siblingId: target, after: zone == _DropZone.after);
        }
        if (!ok) {
          if (!mounted) return;
          _snack(context, 'Un dossier ne peut pas aller dans lui-même.');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return DragTarget<ExplorerItem>(
      onWillAcceptWithDetails: (details) =>
          !(details.data is FolderItem && details.data.id == widget.folderId),
      onMove: (details) {
        final zone = _zoneAt(details.offset, details.data);
        if (zone != _zone) setState(() => _zone = zone);
      },
      onLeave: (_) => setState(() => _zone = null),
      onAcceptWithDetails: (details) {
        final zone = _zone ?? _DropZone.inside;
        setState(() => _zone = null);
        _accept(details.data, zone);
      },
      builder: (context, candidates, _) {
        final zone = candidates.isEmpty ? null : _zone ?? _DropZone.inside;
        final line = BorderSide(color: cq.vertDark, width: Borders.focus);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: zone == _DropZone.inside
                ? cq.vert.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(Radii.sm),
            border: switch (zone) {
              _DropZone.inside => Border.all(color: cq.vertDark),
              _DropZone.before => Border(top: line),
              _DropZone.after => Border(bottom: line),
              null => null,
            },
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Entrée de menu contextuel : icône, libellé, couleur d'alerte au besoin.
PopupMenuEntry<String> _menuItem(BuildContext context, String value,
    IconData icon, String label,
    {bool enabled = true, bool danger = false}) {
  final color = danger ? context.cq.errorColor : null;
  return PopupMenuItem<String>(
    value: value,
    enabled: enabled,
    height: Sizes.touchTarget - Space.sm,
    child: Row(
      children: [
        Icon(icon, size: Sizes.iconMd, color: color ?? context.cq.textMuted),
        const SizedBox(width: Space.md),
        Flexible(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: color == null ? null : TextStyle(color: color)),
        ),
      ],
    ),
  );
}

Future<String?> _showContextMenu(BuildContext context, Offset position,
    List<PopupMenuEntry<String>> items) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size),
    popUpAnimationStyle: Motion.style(context),
    items: items,
  );
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final confirmed = await showDialog<bool>(
    context: context,
    animationStyle: Motion.style(context),
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Text(body),
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

/// Menu contextuel complet d'une fiche, ouvert à [position].
Future<void> showNoteMenu(
    BuildContext context, WidgetRef ref, Note note, Offset position) async {
  final clipboard = ref.read(explorerClipboardProvider);
  final action = await _showContextMenu(context, position, [
    _menuItem(context, 'open', Icons.open_in_new, 'Ouvrir'),
    const PopupMenuDivider(),
    _menuItem(context, 'copy', Icons.content_copy, 'Copier'),
    _menuItem(context, 'paste', Icons.content_paste,
        'Coller dans ce dossier',
        enabled: clipboard != null),
    _menuItem(context, 'duplicate', Icons.file_copy_outlined, 'Dupliquer'),
    _menuItem(context, 'rename', Icons.drive_file_rename_outline, 'Renommer'),
    _menuItem(context, 'move', Icons.drive_file_move_outline, 'Déplacer vers…'),
    _menuItem(context, 'link', Icons.link, 'Lier à un autre fichier…'),
    const PopupMenuDivider(),
    _menuItem(context, 'favorite',
        note.isFavorite ? Icons.star : Icons.star_border,
        note.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
    _menuItem(context, 'archive', Icons.archive_outlined,
        note.isArchived ? 'Désarchiver' : 'Archiver'),
    _menuItem(context, 'path', Icons.tag, 'Copier le chemin'),
    _menuItem(context, 'zip', Icons.folder_zip_outlined, 'Compresser (.zip)'),
    _menuItem(context, 'export', Icons.download_outlined,
        'Exporter (.md)'),
    _menuItem(context, 'properties', Icons.info_outline, 'Propriétés'),
    const PopupMenuDivider(),
    _menuItem(context, 'delete', Icons.delete_outline, 'Supprimer',
        danger: true),
  ]);
  if (action == null || !context.mounted) return;

  final notes = ref.read(noteActionsProvider);
  final folders = ref.read(folderActionsProvider);
  switch (action) {
    case 'open':
      context.push('${AppRoute.notes}/${note.id}');
    case 'copy':
      ref.read(explorerClipboardProvider.notifier).copy(NoteItem(note.id));
      _snack(context, '« ${note.displayTitle} » copiée : colle-la dans '
              'un dossier.');
    case 'paste':
      await folders.paste(note.folderId);
    case 'duplicate':
      await folders.duplicateNote(note, note.folderId);
    case 'rename':
      final title = await askFolderName(context,
          title: 'Renommer la fiche',
          initial: note.title,
          hint: 'Titre de la fiche');
      if (title != null) await notes.rename(note, title);
    case 'move':
      final choice = await pickFolder(context, ref);
      if (choice != null) await folders.moveNote(note.id, choice.$2);
    case 'link':
      final all = ref.read(notesProvider).valueOrNull ?? const <Note>[];
      final target =
          await showNotePicker(context, notes: all, excludeId: note.id);
      if (target == null) return;
      await ref
          .read(graphActionsProvider)
          .link(sourceId: note.id, targetId: target.id);
      if (!context.mounted) return;
      _snack(context, 'Liée à « ${target.displayTitle} ».');
    case 'favorite':
      await notes.toggleFavorite(note);
    case 'archive':
      await notes.toggleArchived(note);
    case 'path':
      await Clipboard.setData(ClipboardData(text: explorerUri(NoteItem(note.id))));
      if (!context.mounted) return;
      _snack(context, 'Chemin copié.');
    case 'zip':
      if (!context.mounted) return;
      await saveExport(context, '${safeFileName(note.displayTitle)}.zip',
          zipNote(note), mimeType: 'application/zip');
    case 'export':
      if (!context.mounted) return;
      await saveExport(context, '${safeFileName(note.displayTitle)}.md',
          Uint8List.fromList(utf8.encode(note.toMarkdown())),
          mimeType: 'text/markdown');
    case 'properties':
      if (!context.mounted) return;
      await showNoteProperties(context, ref, note);
    case 'delete':
      if (!context.mounted) return;
      if (await _confirm(context, 'Supprimer « ${note.displayTitle} » ?',
          'Cette action est définitive.')) {
        await notes.delete(note.id);
      }
  }
}

/// Menu contextuel complet d'un dossier, ouvert à [position].
Future<void> showFolderMenu(BuildContext context, WidgetRef ref, Folder folder,
    Offset position, {VoidCallback? onCreateChild}) async {
  final clipboard = ref.read(explorerClipboardProvider);
  final action = await _showContextMenu(context, position, [
    _menuItem(context, 'open', Icons.folder_open_outlined, 'Ouvrir'),
    _menuItem(context, 'child', Icons.create_new_folder_outlined,
        'Nouveau sous-dossier'),
    const PopupMenuDivider(),
    _menuItem(context, 'copy', Icons.content_copy, 'Copier'),
    _menuItem(context, 'paste', Icons.content_paste, 'Coller ici',
        enabled: clipboard != null),
    _menuItem(context, 'duplicate', Icons.file_copy_outlined, 'Dupliquer'),
    _menuItem(context, 'rename', Icons.drive_file_rename_outline, 'Renommer'),
    _menuItem(context, 'move', Icons.drive_file_move_outline, 'Déplacer vers…'),
    const PopupMenuDivider(),
    _menuItem(context, 'path', Icons.tag, 'Copier le chemin'),
    _menuItem(context, 'zip', Icons.folder_zip_outlined,
        'Compresser / Exporter (.zip)'),
    _menuItem(context, 'properties', Icons.info_outline, 'Propriétés'),
    const PopupMenuDivider(),
    _menuItem(context, 'delete', Icons.delete_outline, 'Supprimer',
        danger: true),
  ]);
  if (action == null || !context.mounted) return;

  final actions = ref.read(folderActionsProvider);
  switch (action) {
    case 'open':
      ref
          .read(folderSelectionProvider.notifier)
          .select(FolderSelection.folder(folder.id));
    case 'child':
      if (onCreateChild != null) {
        onCreateChild();
      } else {
        final name =
            await askFolderName(context, title: 'Nouveau sous-dossier');
        if (name != null) await actions.create(name, parentId: folder.id);
      }
    case 'copy':
      ref.read(explorerClipboardProvider.notifier).copy(FolderItem(folder.id));
      _snack(context, '« ${folder.name} » copié : colle-le dans un autre '
              'dossier.');
    case 'paste':
      await actions.paste(folder.id);
    case 'duplicate':
      await actions.duplicateFolder(folder.id, folder.parentId);
    case 'rename':
      final name = await askFolderName(context,
          title: 'Renommer', initial: folder.name);
      if (name != null) await actions.rename(folder.id, name);
    case 'move':
      final choice = await pickFolder(context, ref);
      if (choice == null) return;
      if (!await actions.placeFolder(folder.id, choice.$2)) {
        if (!context.mounted) return;
        _snack(context, 'Un dossier ne peut pas aller dans lui-même.');
      }
    case 'path':
      await Clipboard.setData(
          ClipboardData(text: explorerUri(FolderItem(folder.id))));
      if (!context.mounted) return;
      _snack(context, 'Chemin copié.');
    case 'zip':
      final bytes = await actions.zipFolder(folder.id);
      if (!context.mounted) return;
      await saveExport(context, '${safeFileName(folder.name)}.zip', bytes,
          mimeType: 'application/zip');
    case 'properties':
      await showFolderProperties(context, ref, folder);
    case 'delete':
      if (await _confirm(
          context,
          'Supprimer « ${folder.name} » ?',
          'Ses sous-dossiers sont supprimés aussi. Les fiches et les cartes '
              'qu’ils contiennent ne sont pas perdues : elles reviennent dans '
              '« Non rangé ».')) {
        await actions.delete(folder.id);
      }
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}'
    '/${d.year} à ${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

Future<void> _showProperties(BuildContext context, String title,
    List<(String, String)> rows, {List<Widget> actions = const []}) {
  return showDialog<void>(
    context: context,
    animationStyle: Motion.style(context),
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 128,
                      child: Text(label,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                    Expanded(
                      child: SelectableText(value,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        ...actions,
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}

/// Fenêtre « Propriétés » d'une fiche : matière, tags, importance, dates,
/// taille, emplacement — et l'accès à leur modification.
Future<void> showNoteProperties(
    BuildContext context, WidgetRef ref, Note note) {
  final folders = ref.read(foldersProvider).valueOrNull ?? const <Folder>[];
  final location = folderPath(note.folderId, folders);
  return _showProperties(
    context,
    'Propriétés',
    [
      ('Titre', note.displayTitle),
      ('Emplacement', location.isEmpty ? 'Non rangé' : location),
      ('Matière', note.subject ?? '—'),
      ('Tags', note.tags.isEmpty ? '—' : note.tags.map((t) => '#$t').join(' ')),
      ('Importance', NoteImportance.fromLevel(note.importance).label),
      ('Créée le', _formatDate(note.createdAt)),
      ('Modifiée le', _formatDate(note.updatedAt)),
      ('Taille', formatSize(note.sizeInBytes)),
      ('Blocs', '${note.blocks.length}'),
      ('État', [
        if (note.isFavorite) 'Favori',
        if (note.isArchived) 'Archivée',
        note.isSynced ? 'Synchronisée' : 'En attente de synchronisation',
      ].join(' · ')),
      ('Chemin', explorerUri(NoteItem(note.id))),
    ],
    actions: [
      TextButton(
        onPressed: () async {
          Navigator.pop(context);
          final updated = await NoteMetaSheet.show(context, note: note);
          if (updated != null) await ref.read(noteActionsProvider).save(updated);
        },
        child: const Text('Modifier matière, tags, importance'),
      ),
    ],
  );
}

/// Fenêtre « Propriétés » d'un dossier : emplacement, contenu, taille.
Future<void> showFolderProperties(
    BuildContext context, WidgetRef ref, Folder folder) async {
  final folders = ref.read(foldersProvider).valueOrNull ?? const <Folder>[];
  final notes = ref.read(notesProvider).valueOrNull ?? const <Note>[];
  final ids = await ref.read(folderRepositoryProvider)?.subtreeOf(folder.id) ??
      {folder.id};
  final inside = notes.where((n) => ids.contains(n.folderId)).toList();
  final location = folderPath(folder.parentId, folders);
  if (!context.mounted) return;
  await _showProperties(context, 'Propriétés', [
    ('Nom', folder.name),
    ('Emplacement', location.isEmpty ? 'Racine' : location),
    ('Sous-dossiers', '${ids.length - 1}'),
    ('Fiches', '${inside.length}'),
    ('Taille', formatSize(inside.fold(0, (sum, n) => sum + n.sizeInBytes))),
    ('Chemin', explorerUri(FolderItem(folder.id))),
  ]);
}

/// Message bref, animé selon le réglage « Réduire les animations ».
void _snack(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)),
      snackBarAnimationStyle: Motion.style(context));
}
