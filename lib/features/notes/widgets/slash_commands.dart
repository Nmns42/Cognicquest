import 'package:flutter/material.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/note_model.dart';

/// Commandes du menu « / » de l'éditeur de fiches (à la Notion).
///
/// Dans le texte libre, une commande insère sa syntaxe Markdown ; dans un
/// bloc vide, elle change le type du bloc ([blockType]).
enum SlashCommand {
  heading('Titre', Icons.title, '# ', NoteBlockType.heading),
  subheading('Sous-titre', Icons.text_fields, '## ', null),
  bulleted('Liste à puces', Icons.format_list_bulleted, '- ',
      NoteBlockType.bulleted),
  numbered('Liste numérotée', Icons.format_list_numbered, '1. ', null),
  todo('Case à cocher', Icons.check_box_outlined, '- [ ] ', NoteBlockType.todo),
  quote('Citation', Icons.format_quote, '> ', NoteBlockType.quote),
  code('Code', Icons.code, '```\n', NoteBlockType.code),
  divider('Séparateur', Icons.horizontal_rule, '---\n', NoteBlockType.divider),
  noteLink('Lien vers une fiche', Icons.link, '[[', null);

  const SlashCommand(this.label, this.icon, this.markdown, this.blockType);

  final String label;
  final IconData icon;

  /// Syntaxe insérée dans le texte libre.
  final String markdown;

  /// Type de bloc correspondant, ou `null` si la commande n'existe pas en
  /// bloc.
  final NoteBlockType? blockType;

  /// Commandes proposées dans un bloc : celles qui ont un type de bloc, plus
  /// le lien vers une fiche.
  static List<SlashCommand> get forBlocks => [
        for (final command in values)
          if (command.blockType != null || command == noteLink) command,
      ];
}

/// Ce que vient de taper l'utilisateur, d'après l'ancien et le nouveau texte.
enum Trigger { slash, wikiLink }

/// Détecte « / » (en début de ligne ou après un espace) et « [[ » juste
/// tapés au curseur. Ne réagit qu'à une frappe d'un seul caractère : un
/// collage ou une suppression n'ouvre rien.
Trigger? detectTrigger(String previous, TextEditingValue value) {
  final text = value.text;
  final caret = value.selection.baseOffset;
  if (text.length != previous.length + 1 || caret < 1 || caret > text.length) {
    return null;
  }
  final typed = text[caret - 1];
  if (typed == '/') {
    final before = caret >= 2 ? text[caret - 2] : '\n';
    if (before == '\n' || before == ' ') return Trigger.slash;
  }
  if (typed == '[' && caret >= 2 && text[caret - 2] == '[') {
    return Trigger.wikiLink;
  }
  return null;
}

/// Rectangle global du curseur dans un champ (approximation par mise en
/// page du texte qui le précède, au style et à la largeur du champ) : le
/// menu s'ouvre juste sous la ligne en cours, pas au bord du champ.
Rect caretRect(BuildContext fieldContext, TextEditingValue value,
    TextStyle style, {EdgeInsets padding = EdgeInsets.zero}) {
  final box = fieldContext.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Rect.zero;
  final width = (box.size.width - padding.horizontal).clamp(1.0, 4000.0);
  final painter = TextPainter(
    text: TextSpan(
        text: value.text.substring(0, value.selection.baseOffset),
        style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(fieldContext),
  )..layout(maxWidth: width);
  final caret = painter.getOffsetForCaret(
      TextPosition(offset: value.selection.baseOffset), Rect.zero);
  final lineHeight = painter.preferredLineHeight;
  painter.dispose();
  final topLeft =
      box.localToGlobal(Offset(padding.left, padding.top) + caret);
  return Rect.fromLTWH(topLeft.dx, topLeft.dy, 1, lineHeight);
}

/// Menu « / », discret, ouvert sous le curseur. Clavier : flèches et Entrée ;
/// Échap le ferme sans rien changer.
Future<SlashCommand?> showSlashMenu(
  BuildContext context, {
  required Rect anchor,
  List<SlashCommand> commands = SlashCommand.values,
}) {
  final overlay =
      Overlay.of(context).context.findRenderObject()! as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromLTWH(anchor.left, anchor.bottom, 1, 1),
    Offset.zero & overlay.size,
  );
  return showMenu<SlashCommand>(
    context: context,
    position: position,
    popUpAnimationStyle: Motion.style(context),
    items: [
      for (final command in commands)
        PopupMenuItem(
          value: command,
          height: Sizes.touchTarget,
          child: Row(
            children: [
              Icon(command.icon,
                  size: Sizes.iconMd, color: context.cq.textMuted),
              const SizedBox(width: Space.md),
              // Le menu s'élargit en s'ouvrant : le libellé ne doit pas
              // déborder pendant l'animation.
              Flexible(
                child: Text(command.label,
                    maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
              ),
            ],
          ),
        ),
    ],
  );
}

/// Choix d'une fiche à lier, avec recherche par titre.
Future<Note?> showNotePicker(
  BuildContext context, {
  required List<Note> notes,
  String? excludeId,
}) {
  return showDialog<Note>(
    context: context,
    animationStyle: Motion.style(context),
    builder: (_) => _NotePickerDialog(
      notes: [
        for (final note in notes)
          if (note.id != excludeId) note,
      ],
    ),
  );
}

class _NotePickerDialog extends StatefulWidget {
  const _NotePickerDialog({required this.notes});

  final List<Note> notes;

  @override
  State<_NotePickerDialog> createState() => _NotePickerDialogState();
}

class _NotePickerDialogState extends State<_NotePickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matches = [
      for (final note in widget.notes)
        if (query.isEmpty || note.displayTitle.toLowerCase().contains(query))
          note,
    ];
    return AlertDialog(
      title: const Text('Lier une fiche'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Rechercher une fiche',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) {
                if (matches.isNotEmpty) Navigator.pop(context, matches.first);
              },
            ),
            const SizedBox(height: Space.sm),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Space.lg),
                      child: Text('Aucune fiche ne correspond.',
                          style: Theme.of(context).textTheme.bodySmall),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final note in matches.take(30))
                          ListTile(
                            title: Text(note.displayTitle,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: note.subject == null
                                ? null
                                : Text(note.subject!),
                            onTap: () => Navigator.pop(context, note),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
