@Tags(['pdfium'])
library;

import 'dart:io';

import 'package:cognicquest/core/media/media_store.dart';
import 'package:cognicquest/core/theme/app_theme.dart';
import 'package:cognicquest/features/notes/domain/pdf_annotations.dart';
import 'package:cognicquest/features/notes/widgets/pdf_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';

/// Annotation d'un vrai PDF (moteur PDFium natif) : sélectionner, surligner,
/// enregistrer les rectangles des mots. Étiqueté `pdfium` : exclu de la CI
/// Linux, lancé en local.
void main() {
  testWidgets('sélection puis « Surligner » : annotation enregistrée',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => Directory.systemTemp.path);

    final doc = pw.Document()
      ..addPage(pw.Page(
          build: (c) => pw.Column(children: [
                pw.Text('Machines thermiques'),
                pw.Text('Le rendement de Carnot est maximal.'),
              ])));
    final bytes = await tester.runAsync(() => doc.save());

    PdfBlockData? saved;
    await tester.pumpWidget(ProviderScope(
      overrides: [mediaBytesProvider.overrideWith((ref, src) async => bytes)],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PdfAnnotatorPage(
          data: const PdfBlockData(source: 'media://u/td.pdf', name: 'TD.pdf'),
          onChanged: (data) => saved = data,
        ),
      ),
    ));

    Future<void> settleNative() async {
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await settleNative();
    final viewer =
        tester.state(find.byType(PdfViewer)) as PdfTextSelectionDelegate;
    await tester.runAsync(viewer.selectAllText);
    await settleNative();

    await tester.tap(find.text('Surligner'));
    await settleNative();

    expect(saved, isNotNull);
    final mark = saved!.marks.single;
    expect(mark.kind, PdfMarkKind.highlight);
    expect(mark.page, 1);
    expect(mark.text, contains('Carnot'));
    expect(mark.boxes, isNotEmpty);
    expect(mark.boxes.first.top, greaterThan(mark.boxes.first.bottom));

    await tester.pumpWidget(const SizedBox());
    await settleNative();
  });
}
