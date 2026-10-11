import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/user_settings.dart';

/// Édition d'une routine matin ou soir.
///
/// CdC : « Instaurer des routines : Matin et Soir », et « instaurer un non
/// négociable chaque jour ». Les étapes sont modifiables : une routine imposée
/// par l'application ne serait pas tenue.
class RoutineEditor extends StatelessWidget {
  const RoutineEditor({
    super.key,
    required this.title,
    required this.icon,
    required this.routine,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final Routine routine;
  final ValueChanged<Routine> onChanged;

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: routine.hour, minute: routine.minute),
      helpText: title,
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked == null) return;
    onChanged(routine.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _editSteps(BuildContext context) async {
    final steps = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StepsSheet(title: title, steps: routine.steps),
    );
    if (steps != null) onChanged(routine.copyWith(steps: steps));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 19,
                    color: routine.isEnabled
                        ? context.cq.vertDark
                        : context.cq.textHint),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.cq.textPrimary)),
                ),
                Switch.adaptive(
                  value: routine.isEnabled,
                  onChanged: (value) =>
                      onChanged(routine.copyWith(isEnabled: value)),
                ),
              ],
            ),
            if (routine.isEnabled) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _pickTime(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: context.cq.beigeDark
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule,
                                    size: 14, color: context.cq.textMuted),
                                const SizedBox(width: 6),
                                Text(routine.timeLabel,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: context.cq.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _editSteps(context),
                          child: const Text('Modifier les étapes'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < routine.steps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.cq.textHint)),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(routine.steps[i],
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.35,
                                      color: context.cq.textMuted)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepsSheet extends StatefulWidget {
  const _StepsSheet({required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  State<_StepsSheet> createState() => _StepsSheetState();
}

class _StepsSheetState extends State<_StepsSheet> {
  late List<String> _steps = List<String>.from(widget.steps);
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps = [..._steps, text];
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.cq.beige,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            Text(widget.title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Trois étapes suffisent. Une routine trop longue ne se tient pas.',
              style: TextStyle(fontSize: 11.5, color: context.cq.textMuted),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                hintText: 'Ajouter une étape',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Ajouter',
                  onPressed: _add,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _steps.length,
                onReorderItem: (oldIndex, newIndex) => setState(() {
                  final steps = List<String>.from(_steps);
                  steps.insert(
                      newIndex.clamp(0, steps.length - 1),
                      steps.removeAt(oldIndex));
                  _steps = steps;
                }),
                itemBuilder: (context, index) => Card(
                  key: ValueKey('${_steps[index]}-$index'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.drag_indicator,
                        size: 18, color: context.cq.textHint),
                    title: Text(_steps[index],
                        style: const TextStyle(fontSize: 13)),
                    trailing: IconButton(
                      icon: Icon(Icons.close,
                          size: 16, color: context.cq.textHint),
                      onPressed: () => setState(
                          () => _steps = [..._steps]..removeAt(index)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => Navigator.pop(context, _steps),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
