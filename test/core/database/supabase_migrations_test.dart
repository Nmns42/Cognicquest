import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `supabase/schema.sql` est l'instantané des migrations versionnées : une
/// base montée par l'un ou l'autre doit être identique.
void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  test('schema.sql = concaténation des migrations, dans l\'ordre', () {
    final migrations = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .map((f) => f.path)
        .toList()
      ..sort();

    expect(migrations, isNotEmpty);
    expect(migrations.first, endsWith('_baseline.sql'));
    final rebuilt = migrations.map(read).join('\n');
    expect(read('supabase/schema.sql'), rebuilt);
  });

  test('noms de migration au format de la CLI Supabase', () {
    final names = Directory('supabase/migrations')
        .listSync()
        .map((f) => f.uri.pathSegments.last);
    for (final name in names) {
      expect(name, matches(RegExp(r'^\d{14}_[a-z0-9_]+\.sql$')), reason: name);
    }
  });
}
