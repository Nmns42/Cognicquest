import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/flashcard_model.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/providers/note_provider.dart';
import '../providers/review_provider.dart';

/// Mode « Explique-moi » — CdC : « expliquer avec ses propres mots ce qu'on
/// vient d'apprendre », technique Feynman.
///
/// La fiche est volontairement **masquée** pendant la rédaction : recopier
/// n'apprend rien, c'est l'effort de reformulation qui compte.
class ExplainPage extends ConsumerStatefulWidget {
  const ExplainPage({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<ExplainPage> createState() => _ExplainPageState();
}

class _ExplainPageState extends ConsumerState<ExplainPage> {
  final _controller = TextEditingController();
  int _confidence = 3;
  bool _showSource = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _controller.text.trim();
    return text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await ref.read(reviewActionsProvider).saveExplanation(
          Explanation(
            id: LocalFirstNoteRepository.newId(),
            userId: '',
            noteId: widget.noteId,
            content: text,
            confidence: _confidence,
            createdAt: DateTime.now(),
            isSynced: false,
          ),
        );

    if (!mounted) return;
    _controller.clear();
    setState(() => _confidence = 3);
    ScaffoldMessenger.of(context).showSnackBar(
      snackBarAnimationStyle: Motion.style(context),
      const SnackBar(content: Text('Explication enregistrée.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(noteByIdProvider(widget.noteId));
    final previous = ref.watch(explanationsForNoteProvider(widget.noteId));

    if (note == null) {
      return  Scaffold(
        body: Center(child: CircularProgressIndicator(color: context.cq.vert)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explique-moi'),
        actions: [
          IconButton(
            tooltip: _showSource ? 'Masquer la fiche' : 'Afficher la fiche',
            icon: Icon(_showSource
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            onPressed: () => setState(() => _showSource = !_showSource),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(note.displayTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
             Text(
              'Explique cette notion comme à quelqu\'un qui ne la connaît '
              'pas. Les trous dans ton explication sont les trous dans ta '
              'compréhension.',
              style: TextStyle(
                  fontSize: 12.5, color: context.cq.textMuted, height: 1.45),
            ),
            const SizedBox(height: 18),

            if (_showSource) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cq.beigeDark.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note.content.trim().isEmpty
                      ? note.excerpt
                      : note.content,
                  style:  TextStyle(
                      fontSize: 13, height: 1.5, color: context.cq.textMuted),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _controller,
              minLines: 8,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Avec tes mots, sans jargon…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_wordCount mot${_wordCount > 1 ? 's' : ''}',
                style:  TextStyle(fontSize: 11, color: context.cq.textHint),
              ),
            ),
            const SizedBox(height: 18),

             Text(
              'À quel point te sens-tu sûr ?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.cq.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            _ConfidencePicker(
              value: _confidence,
              onChanged: (value) => setState(() => _confidence = value),
            ),
            const SizedBox(height: 22),

            ElevatedButton(
              onPressed: _wordCount == 0 ? null : _save,
              child: const Text('Enregistrer mon explication'),
            ),

            if (previous.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Tes explications précédentes (${previous.length})',
                style:  TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.cq.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
               Text(
                'Les relire montre comment ta compréhension a évolué.',
                style: TextStyle(fontSize: 11, color: context.cq.textMuted),
              ),
              const SizedBox(height: 10),
              for (final explanation in previous)
                _PreviousExplanation(explanation: explanation),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidencePicker extends StatelessWidget {
  const _ConfidencePicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = [
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
              message: _labels[level - 1],
              child: InkWell(
                onTap: () => onChanged(level),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: Motion.duration(context, const Duration(milliseconds: 160)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: level <= value
                        ? context.cq.vert
                        : context.cq.beigeDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$level',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
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

class _PreviousExplanation extends StatelessWidget {
  const _PreviousExplanation({required this.explanation});

  final Explanation explanation;

  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  @override
  Widget build(BuildContext context) {
    final date = explanation.createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day} ${_months[date.month - 1]}',
                  style:  TextStyle(
                      fontSize: 11, color: context.cq.textHint),
                ),
                const Spacer(),
                Text(
                  'Confiance ${explanation.confidence}/5',
                  style:  TextStyle(
                      fontSize: 11, color: context.cq.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              explanation.content,
              style:  TextStyle(
                  fontSize: 13, height: 1.45, color: context.cq.textPrimary),
            ),
          ],
        ),
      ),
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
                        fontSize: 13,
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
                          style: const TextStyle(fontSize: 14)),
                      subtitle: note.subject == null
                          ? null
                          : Text(note.subject!,
                              style: const TextStyle(fontSize: 11)),
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
