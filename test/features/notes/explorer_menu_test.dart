import 'package:cognicquest/features/notes/widgets/folder_explorer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Menu contextuel de l'explorateur : clic droit sur ordinateur, appui long
/// quand le glisser est désactivé.
void main() {
  Future<List<Offset>> pump(WidgetTester tester, {required bool draggable}) async {
    final opened = <Offset>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ExplorerItemShell(
            item: const NoteItem('n1'),
            label: 'Cycle de Krebs',
            icon: Icons.description_outlined,
            draggable: draggable,
            onMenu: opened.add,
            child: const SizedBox(
                width: 200, height: 60, child: Text('Cycle de Krebs')),
          ),
        ),
      ),
    ));
    return opened;
  }

  testWidgets('clic droit : le menu s’ouvre sous le pointeur', (tester) async {
    final opened = await pump(tester, draggable: true);
    final center = tester.getCenter(find.text('Cycle de Krebs'));
    await tester.tapAt(center, buttons: kSecondaryButton);
    await tester.pump();
    expect(opened, [center]);
  });

  testWidgets('appui long : le menu s’ouvre', (tester) async {
    final opened = await pump(tester, draggable: false);
    await tester.longPress(find.text('Cycle de Krebs'));
    expect(opened, hasLength(1));
  });

  test('chemins et noms de fichier', () {
    expect(explorerUri(const NoteItem('abc')), 'note://abc');
    expect(explorerUri(const FolderItem('f1')), 'note://folder/f1');
    expect(safeFileName('Cours: 1/2 *final*'), 'Cours- 1-2 -final-');
    expect(safeFileName('   '), 'sans-titre');
    expect(formatSize(512), '512 o');
    expect(formatSize(2048), '2.0 Ko');
  });
}
