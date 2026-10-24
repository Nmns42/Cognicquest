import 'package:flutter/services.dart';

/// Mise en forme du texte d'une fiche, en Markdown étendu :
///
/// | Effet | Syntaxe |
/// |---|---|
/// | Gras | `**texte**` |
/// | Italique | `*texte*` |
/// | Souligné | `++texte++` |
/// | Barré | `~~texte~~` |
/// | Surligné | `==texte==` (jaune) ou `=={vert}texte==` |
/// | Alignement | `{centre} `, `{droite} `, `{justifié} ` en début de ligne |
///
/// Le texte reste lisible tel quel (exports, recherche, autres appareils) ;
/// l'aperçu l'affiche mis en forme.
enum InlineFormat {
  bold('**', '**', 'Gras'),
  italic('*', '*', 'Italique'),
  underline('++', '++', 'Souligner'),
  strike('~~', '~~', 'Barrer');

  const InlineFormat(this.open, this.close, this.label);

  final String open;
  final String close;
  final String label;
}

/// Couleurs de surlignage, du marqueur `=={nom}` au libellé.
enum HighlightColor {
  jaune('Jaune'),
  vert('Vert'),
  bleu('Bleu'),
  rose('Rose'),
  orange('Orange');

  const HighlightColor(this.label);

  final String label;

  String get open => this == HighlightColor.jaune ? '==' : '=={$name}';

  static HighlightColor? fromName(String? name) {
    if (name == null || name.isEmpty) return HighlightColor.jaune;
    for (final color in values) {
      if (color.name == name) return color;
    }
    return null;
  }
}

enum LineAlignment {
  left('', 'Aligner à gauche'),
  center('{centre} ', 'Centrer'),
  right('{droite} ', 'Aligner à droite'),
  justify('{justifié} ', 'Justifier');

  const LineAlignment(this.marker, this.label);

  /// Préfixe de ligne ; vide pour l'alignement par défaut.
  final String marker;
  final String label;

  static final RegExp _prefix = RegExp(r'^\{(centre|droite|justifié)\} ');

  /// Alignement d'une ligne et son texte sans marqueur.
  static (LineAlignment, String) parse(String line) {
    final match = _prefix.firstMatch(line);
    if (match == null) return (LineAlignment.left, line);
    final alignment = switch (match.group(1)) {
      'centre' => LineAlignment.center,
      'droite' => LineAlignment.right,
      _ => LineAlignment.justify,
    };
    return (alignment, line.substring(match.end));
  }
}

abstract final class RichTextFormat {
  /// Encadre la sélection avec [open] / [close], ou retire l'encadrement
  /// s'il est déjà là (bascule, comme dans un traitement de texte). Sans
  /// sélection, insère les marqueurs et place le curseur entre eux.
  static TextEditingValue toggleWrap(
    TextEditingValue value,
    String open,
    String close,
  ) {
    final text = value.text;
    var selection = value.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
    }
    final start = selection.start;
    final end = selection.end;

    // Déjà encadrée (marqueurs juste autour de la sélection) : on retire.
    final before = start - open.length;
    final after = end + close.length;
    if (before >= 0 &&
        after <= text.length &&
        text.substring(before, start) == open &&
        text.substring(end, after) == close &&
        // « *texte* » ne doit pas être pris pour l'intérieur de « **texte** ».
        !(open == '*' && before > 0 && text[before - 1] == '*')) {
      final unwrapped =
          text.replaceRange(end, after, '').replaceRange(before, start, '');
      return TextEditingValue(
        text: unwrapped,
        selection:
            TextSelection(baseOffset: before, extentOffset: end - open.length),
      );
    }

    final selected = text.substring(start, end);
    final wrapped = text.replaceRange(start, end, '$open$selected$close');
    return TextEditingValue(
      text: wrapped,
      selection: selected.isEmpty
          ? TextSelection.collapsed(offset: start + open.length)
          : TextSelection(
              baseOffset: start + open.length, extentOffset: end + open.length),
    );
  }

  static TextEditingValue applyInline(TextEditingValue value, InlineFormat f) =>
      toggleWrap(value, f.open, f.close);

  /// Surligne la sélection dans [color] ; une sélection déjà surlignée dans
  /// la même couleur est rendue à la normale.
  static TextEditingValue highlight(
          TextEditingValue value, HighlightColor color) =>
      toggleWrap(value, color.open, '==');

  /// Applique [alignment] à toutes les lignes touchées par la sélection
  /// (l'ancien marqueur est remplacé).
  static TextEditingValue align(
      TextEditingValue value, LineAlignment alignment) {
    final text = value.text;
    var selection = value.selection;
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
    }
    final lineStart = selection.start == 0
        ? 0
        : text.lastIndexOf('\n', selection.start - 1) + 1;
    var lineEnd = text.indexOf('\n', selection.end);
    if (lineEnd < 0) lineEnd = text.length;

    final lines = text.substring(lineStart, lineEnd).split('\n');
    var delta = 0;
    final rewritten = [
      for (final line in lines)
        () {
          final (_, bare) = LineAlignment.parse(line);
          final next = bare.isEmpty ? bare : '${alignment.marker}$bare';
          delta += next.length - line.length;
          return next;
        }(),
    ].join('\n');

    final updated = text.replaceRange(lineStart, lineEnd, rewritten);
    return TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(
          offset: (selection.end + delta).clamp(0, updated.length)),
    );
  }

  /// Découpe le texte en blocs consécutifs de même alignement, pour
  /// l'aperçu (chaque bloc est rendu avec son alignement).
  static List<(LineAlignment, String)> segments(String text) {
    final out = <(LineAlignment, List<String>)>[];
    for (final line in text.split('\n')) {
      final (alignment, bare) = LineAlignment.parse(line);
      if (out.isNotEmpty && out.last.$1 == alignment) {
        out.last.$2.add(bare);
      } else {
        out.add((alignment, [bare]));
      }
    }
    return [for (final (a, lines) in out) (a, lines.join('\n'))];
  }

  /// Texte sans aucun marqueur propre à CognicQuest (recherche, export
  /// brut) : alignements retirés, `++` et `==` dépliés.
  static String plain(String text) => text
      .split('\n')
      .map((line) => LineAlignment.parse(line).$2)
      .join('\n')
      .replaceAllMapped(RegExp(r'\+\+(.+?)\+\+'), (m) => m.group(1)!)
      .replaceAllMapped(
          RegExp(r'==(?:\{[a-z]+\})?(.+?)=='), (m) => m.group(1)!);
}
