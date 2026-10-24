import 'package:cognicquest/features/notes/domain/rich_text_format.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue sel(String text, int start, [int? end]) => TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: start, extentOffset: end ?? start),
    );

void main() {
  group('mise en forme du texte sélectionné', () {
    test('gras : encadre, puis retire au second appui', () {
      final once = RichTextFormat.applyInline(
          sel('Le cycle de Carnot', 12, 18), InlineFormat.bold);
      expect(once.text, 'Le cycle de **Carnot**');
      expect(once.selection.textInside(once.text), 'Carnot');

      final twice = RichTextFormat.applyInline(once, InlineFormat.bold);
      expect(twice.text, 'Le cycle de Carnot');
    });

    test('italique ne se confond pas avec le gras', () {
      final bold = RichTextFormat.applyInline(
          sel('mot', 0, 3), InlineFormat.bold);
      final both = RichTextFormat.applyInline(bold, InlineFormat.italic);
      expect(both.text, '***mot***');
    });

    test('souligné, barré, et sans sélection : curseur entre les marqueurs',
        () {
      expect(
          RichTextFormat.applyInline(sel('abc', 0, 3), InlineFormat.underline)
              .text,
          '++abc++');
      final empty =
          RichTextFormat.applyInline(sel('ab', 1), InlineFormat.strike);
      expect(empty.text, 'a~~~~b');
      expect(empty.selection.baseOffset, 3);
    });

    test('surlignage en couleur, et retrait', () {
      final green = RichTextFormat.highlight(
          sel('clé', 0, 3), HighlightColor.vert);
      expect(green.text, '=={vert}clé==');
      expect(RichTextFormat.highlight(green, HighlightColor.vert).text, 'clé');
      expect(
          RichTextFormat.highlight(sel('clé', 0, 3), HighlightColor.jaune).text,
          '==clé==');
    });
  });

  group('alignement par ligne', () {
    test('centrer la ligne du curseur, remplacer, revenir à gauche', () {
      final centered =
          RichTextFormat.align(sel('a\nTitre\nb', 3), LineAlignment.center);
      expect(centered.text, 'a\n{centre} Titre\nb');
      final right = RichTextFormat.align(centered, LineAlignment.right);
      expect(right.text, 'a\n{droite} Titre\nb');
      final left = RichTextFormat.align(right, LineAlignment.left);
      expect(left.text, 'a\nTitre\nb');
    });

    test('plusieurs lignes sélectionnées, lignes vides laissées vides', () {
      final value = RichTextFormat.align(
          sel('un\n\ndeux', 0, 7), LineAlignment.justify);
      expect(value.text, '{justifié} un\n\n{justifié} deux');
    });

    test('segments consécutifs de même alignement', () {
      final segments = RichTextFormat.segments(
          '{centre} A\n{centre} B\nC\n{droite} D');
      expect(segments, [
        (LineAlignment.center, 'A\nB'),
        (LineAlignment.left, 'C'),
        (LineAlignment.right, 'D'),
      ]);
    });
  });

  test('texte brut sans marqueurs propres à l\'app', () {
    expect(
        RichTextFormat.plain('{centre} ++souligné++ et =={rose}clé== et ==x=='),
        'souligné et clé et x');
  });
}
