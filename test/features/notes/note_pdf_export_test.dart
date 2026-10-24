import 'dart:io';
import 'dart:typed_data';

import 'package:cognicquest/features/notes/domain/note_pdf_export.dart';
import 'package:cognicquest/features/notes/domain/pdf_annotations.dart';
import 'package:cognicquest/shared/models/note_model.dart';
import 'package:flutter_test/flutter_test.dart';

ByteData font(String path) =>
    ByteData.sublistView(File(path).readAsBytesSync());

void main() {
  final fonts = PdfFonts.fromBytes(
    regular: font('assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf'),
    bold: font('assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf'),
    serif: font('assets/fonts/fraunces/Fraunces-Regular.ttf'),
    serifBold: font('assets/fonts/fraunces/Fraunces-SemiBold.ttf'),
    fallback: font('assets/fonts/noto_sans/NotoSans-Regular.ttf'),
  );

  Note note(String content, {List<NoteBlock> blocks = const []}) => Note(
        id: 'n1',
        userId: 'u1',
        title: 'Thermodynamique — 2e principe',
        content: content,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        subject: 'Physique',
        tags: const ['entropie'],
        blocks: blocks,
      );

  test('une fiche mise en forme devient un PDF valide', () async {
    final requested = <String>[];
    final exporter = NotePdfExporter(
      fonts: fonts,
      loadImage: (source) async {
        requested.add(source);
        return null; // Image indisponible : mention à la place.
      },
    );
    final bytes = await exporter.build(note('''
# Le cycle de Carnot
{centre} **Rendement** maximal : ++souligné++, =={vert}surligné==, ~~barré~~, *emphase*.
{justifié} Un long paragraphe justifié qui explique le principe.

- [x] Revoir la définition
- [ ] Faire l'exercice 3
1. Premier
2. Second

> Citation du cours

```
η = 1 − Tf / Tc
```

| Grandeur | Unité |
|---|---|
| Entropie | J/K |

![schéma](media://u1/schema.png)
''', blocks: [
      NoteBlock(
        id: 'b1',
        noteId: 'n1',
        type: NoteBlockType.pdf,
        content: const PdfBlockData(source: 'media://u1/td.pdf', name: 'TD.pdf',
            marks: [
              PdfMark(
                  id: 'm',
                  page: 2,
                  kind: PdfMarkKind.highlight,
                  color: 'jaune',
                  boxes: [PdfBox(10, 20, 30, 10)],
                  text: 'Théorème de Carnot'),
            ]).encode(),
        position: 0,
      ),
    ]));

    final out = Platform.environment['CQ_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
    expect(requested, ['media://u1/schema.png']);
  });

  test('annotations PDF : aller-retour JSON, contenu abîmé toléré', () {
    const data = PdfBlockData(source: 'media://u/a.pdf', name: 'a.pdf', marks: [
      PdfMark(
          id: '1',
          page: 3,
          kind: PdfMarkKind.strike,
          color: 'rose',
          boxes: [PdfBox(1, 9, 5, 2), PdfBox(6, 9, 8, 2)],
          text: 'faux'),
    ]);
    final decoded = PdfBlockData.decode(data.encode());
    expect(decoded.name, 'a.pdf');
    expect(decoded.marks.single.kind, PdfMarkKind.strike);
    expect(decoded.marks.single.boxes, hasLength(2));
    expect(decoded.marks.single.boxes.last.right, 8);

    expect(PdfBlockData.decode('{pas du json').isEmpty, isTrue);
    expect(PdfBlockData.decode('').isEmpty, isTrue);
  });
}
