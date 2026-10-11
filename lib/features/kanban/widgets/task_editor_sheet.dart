import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/task_model.dart';

/// Résultat de l'édition d'une carte.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.isUrgent = false,
    this.isImportant = false,
  });

  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final bool isUrgent;
  final bool isImportant;
}

/// Feuille d'édition d'une carte — CdC : « Détails des cartes : description,
/// checklist, tags, échéance, priorité ».
///
/// Remplace l'`AlertDialog` à champ unique qui ne permettait que de saisir un
/// titre (et ne permettait ni la modification ni la suppression).
class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task, this.initialStatus});

  final Task? task;
  final TaskStatus? initialStatus;

  static Future<TaskDraft?> show(
    BuildContext context, {
    Task? task,
    TaskStatus? initialStatus,
  }) {
    return showModalBottomSheet<TaskDraft>(
      context: context,
      sheetAnimationStyle: Motion.style(context),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskEditorSheet(task: task, initialStatus: initialStatus),
    );
  }

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TaskPriority _priority;
  late TaskStatus _status;
  late bool _isUrgent;
  late bool _isImportant;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? widget.initialStatus ?? TaskStatus.todo;
    _isUrgent = task?.isUrgent ?? false;
    _isImportant = task?.isImportant ?? false;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Échéance de la tâche',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TaskDraft(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        status: _status,
        dueDate: _dueDate,
        isUrgent: _isUrgent,
        isImportant: _isImportant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Padding(
      // Remonte la feuille au-dessus du clavier.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration:  BoxDecoration(
          color: context.cq.beige,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                Text(
                  isEditing ? 'Modifier la tâche' : 'Nouvelle tâche',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    hintText: 'Que dois-tu faire ?',
                  ),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Donne un titre à ta tâche.'
                      : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (facultatif)',
                  ),
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 18),

                const _Label('Colonne'),
                const SizedBox(height: 8),
                SegmentedButton<TaskStatus>(
                  segments: [
                    for (final status in TaskStatus.values)
                      ButtonSegment(value: status, label: Text(status.label)),
                  ],
                  selected: {_status},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      setState(() => _status = values.first),
                ),
                const SizedBox(height: 18),

                const _Label('Priorité'),
                const SizedBox(height: 8),
                SegmentedButton<TaskPriority>(
                  segments: [
                    for (final priority in TaskPriority.values)
                      ButtonSegment(value: priority, label: Text(priority.label)),
                  ],
                  selected: {_priority},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      setState(() => _priority = values.first),
                ),
                const SizedBox(height: 18),

                const _Label('Matrice d\'Eisenhower'),
                const SizedBox(height: 4),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isUrgent,
                  onChanged: (value) => setState(() => _isUrgent = value),
                  title: const Text('Urgent', style: TextStyle(fontSize: 14)),
                  subtitle:  Text(
                    'Demande une action immédiate',
                    style: TextStyle(fontSize: 12, color: context.cq.textMuted),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isImportant,
                  onChanged: (value) => setState(() => _isImportant = value),
                  title: const Text('Important', style: TextStyle(fontSize: 14)),
                  subtitle:  Text(
                    'Contribue à tes objectifs de fond',
                    style: TextStyle(fontSize: 12, color: context.cq.textMuted),
                  ),
                ),
                const SizedBox(height: 10),

                const _Label('Échéance'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(
                          _dueDate == null
                              ? 'Aucune échéance'
                              : '${_dueDate!.day.toString().padLeft(2, '0')}/'
                                  '${_dueDate!.month.toString().padLeft(2, '0')}/'
                                  '${_dueDate!.year}',
                        ),
                      ),
                    ),
                    if (_dueDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Retirer l\'échéance',
                        onPressed: () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:  TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.cq.textMuted,
      ),
    );
  }
}
