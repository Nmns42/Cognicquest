import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../router/app_router.dart';
import '../../../shared/models/note_link_model.dart';
import '../../../shared/models/note_model.dart';
import '../../notes/providers/note_provider.dart';
import '../providers/graph_provider.dart';

/// Aperçu du contenu d'un nœud — CdC : « survol des nœuds avec aperçu du
/// contenu ». Permet aussi de créer et supprimer les liens depuis le graphe.
class NodePreviewSheet extends ConsumerWidget {
  const NodePreviewSheet({super.key, required this.noteId});

  final String noteId;

  static Future<void> show(BuildContext context, {required String noteId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NodePreviewSheet(noteId: noteId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteByIdProvider(noteId));
    if (note == null) return const SizedBox.shrink();

    final neighbours = ref.watch(neighboursProvider(noteId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration:  BoxDecoration(
        color: context.cq.beige,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cq.beigeDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(note.displayTitle,
                style: Theme.of(context).textTheme.titleMedium),
            if (note.subject != null) ...[
              const SizedBox(height: 4),
              Text(note.subject!,
                  style:  TextStyle(
                      fontSize: 12, color: context.cq.textMuted)),
            ],
            if (note.excerpt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                note.excerpt,
                style:  TextStyle(
                    fontSize: 13, color: context.cq.textMuted, height: 1.4),
              ),
            ],
            const SizedBox(height: 18),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      neighbours.isEmpty
                          ? 'Aucun lien'
                          : '${neighbours.length} lien'
                              '${neighbours.length > 1 ? 's' : ''}',
                      style:  TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.cq.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (neighbours.isEmpty)
                       Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Relie cette fiche à ce que tu sais déjà : '
                          'c\'est ce qui ancre une notion en mémoire.',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.cq.textHint,
                              height: 1.4),
                        ),
                      )
                    else
                      for (final (neighbour, link) in neighbours)
                        _NeighbourRow(
                          neighbour: neighbour,
                          link: link,
                          onRemove: () =>
                              ref.read(graphActionsProvider).unlink(link.id),
                        ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openLinkPicker(context, ref, note),
                    icon: const Icon(Icons.add_link, size: 18),
                    label: const Text('Relier'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('${AppRoute.notes}/${note.id}');
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Ouvrir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLinkPicker(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final all = ref.read(graphNotesProvider);
    final alreadyLinked = ref
        .read(neighboursProvider(note.id))
        .map((entry) => entry.$1.id)
        .toSet();

    // On ne propose ni la fiche elle-même, ni celles déjà reliées.
    final candidates = all
        .where((n) => n.id != note.id && !alreadyLinked.contains(n.id))
        .toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucune autre fiche disponible à relier.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkPickerSheet(source: note, candidates: candidates),
    );
  }
}

class _NeighbourRow extends StatelessWidget {
  const _NeighbourRow({
    required this.neighbour,
    required this.link,
    required this.onRemove,
  });

  final Note neighbour;
  final NoteLink link;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    neighbour.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:  TextStyle(
                        fontSize: 13, color: context.cq.textPrimary),
                  ),
                  Text(
                    link.type.label,
                    style:  TextStyle(
                        fontSize: 11, color: context.cq.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Supprimer ce lien',
              visualDensity: VisualDensity.compact,
              icon:  Icon(Icons.link_off, size: 17,
                  color: context.cq.textHint),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkPickerSheet extends ConsumerStatefulWidget {
  const _LinkPickerSheet({required this.source, required this.candidates});

  final Note source;
  final List<Note> candidates;

  @override
  ConsumerState<_LinkPickerSheet> createState() => _LinkPickerSheetState();
}

class _LinkPickerSheetState extends ConsumerState<_LinkPickerSheet> {
  NoteLinkType _type = NoteLinkType.related;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.candidates
        : widget.candidates
            .where((n) => n.searchableText.contains(query))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        decoration:  BoxDecoration(
          color: context.cq.beige,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cq.beigeDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Relier « ${widget.source.displayTitle} » à…',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),

            SegmentedButton<NoteLinkType>(
              segments: [
                for (final type in NoteLinkType.values)
                  ButtonSegment(
                    value: type,
                    label: Text(type.label,
                        style: const TextStyle(fontSize: 11)),
                  ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (values) =>
                  setState(() => _type = values.first),
            ),
            const SizedBox(height: 14),

            TextField(
              decoration: const InputDecoration(
                hintText: 'Filtrer les fiches…',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final note = visible[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      title: Text(note.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: note.subject == null
                          ? null
                          : Text(note.subject!,
                              style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.add_link, size: 18),
                      onTap: () async {
                        await ref.read(graphActionsProvider).link(
                              sourceId: widget.source.id,
                              targetId: note.id,
                              type: _type,
                            );
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
