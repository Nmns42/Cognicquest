import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../notes/providers/note_provider.dart';
import '../../../core/theme/tokens.dart';

/// Le mode « Explique-moi » (technique Feynman) est désormais la troisième
/// étape de l'étude guidée (`Sq3rPage`, étape « Explication ») : ce fichier
/// garde le sélecteur de maîtrise et le choix de fiche, communs au parcours.

/// Niveau de maîtrise ressenti, de 1 (très flou) à 5 (limpide).
class ConfidencePicker extends StatelessWidget {
  const ConfidencePicker({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const List<String> labels = [
    'Très flou',
    'Flou',
    'Correct',
    'Solide',
    'Limpide',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var level = 1; level <= 5; level++) ...[
          if (level > 1) const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: labels[level - 1],
              child: InkWell(
                onTap: () => onChanged(level),
                borderRadius: BorderRadius.circular(Radii.md),
                child: AnimatedContainer(
                  duration: Motion.duration(context, const Duration(milliseconds: 160)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: level <= value
                        ? context.cq.vert
                        : context.cq.beigeDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Text(
                    '$level',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: TypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: level <= value ? context.onAccent : context.cq.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Sélecteur de fiche, commun à SQ3R et « Explique-moi ».
class NotePickerPage extends ConsumerWidget {
  const NotePickerPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.routeBuilder,
  });

  final String title;
  final String subtitle;
  final String Function(String noteId) routeBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider).valueOrNull ?? const [];
    final available = notes.where((n) => !n.isArchived).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: available.isEmpty
          ?  Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_outlined,
                        size: 44, color: context.cq.textHint),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune fiche à travailler.\n'
                      'Crée d\'abord une fiche de connaissance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.cq.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(subtitle,
                    style:  TextStyle(
                        fontSize: TypeScale.body,
                        color: context.cq.textMuted,
                        height: 1.4)),
                const SizedBox(height: 16),
                for (final note in available)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(note.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: TypeScale.body)),
                      subtitle: note.subject == null
                          ? null
                          : Text(note.subject!,
                              style: const TextStyle(fontSize: TypeScale.caption)),
                      trailing:  Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: context.cq.textMuted),
                      onTap: () => context.push(routeBuilder(note.id)),
                    ),
                  ),
              ],
            ),
    );
  }
}
