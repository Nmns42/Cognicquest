// Complète le service worker hors ligne après `flutter build web` :
//
//   flutter build web --release --no-web-resources-cdn …
//   dart run tool/generate_service_worker.dart build/web
//
// Remplace dans `cq_service_worker.js` la liste des fichiers à mettre en
// cache à l'installation et la version (empreinte de leur contenu) : un
// déploiement qui change un seul fichier installe un nouveau cache.
import 'dart:convert';
import 'dart:io';

/// Jamais mis en cache à l'installation : les service workers eux-mêmes,
/// les fichiers de build, les licences (lourdes, rarement ouvertes), le
/// moteur skwasm (seulement avec `--wasm`) et la variante expérimentale de
/// CanvasKit. Un fichier exclu chargé malgré tout est mis en cache à l'usage.
bool _excluded(String path) =>
    path == 'cq_service_worker.js' ||
    path == 'flutter_service_worker.js' ||
    path == '.last_build_id' ||
    path == 'version.json' ||
    path == 'assets/NOTICES' ||
    path.endsWith('.map') ||
    path.endsWith('.symbols') ||
    path.endsWith('.gitkeep') ||
    path.contains('skwasm') ||
    path.contains('experimental_webparagraph');

void main(List<String> args) {
  final root = Directory(args.isEmpty ? 'build/web' : args.first);
  final worker = File('${root.path}/cq_service_worker.js');
  if (!worker.existsSync()) {
    stderr.writeln('${worker.path} introuvable : lancer flutter build web.');
    exit(1);
  }

  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path
          .substring(root.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/'))
      .where((path) => !_excluded(path))
      .toList()
    ..sort();

  if (!files.any((f) => f.startsWith('canvaskit/'))) {
    stderr.writeln('CanvasKit absent : construire avec '
        '--no-web-resources-cdn, sinon l\'app ne démarre pas hors ligne.');
    exit(1);
  }

  // FNV-1a 64 bits sur les chemins et les contenus.
  var hash = 0xcbf29ce484222325;
  void feed(List<int> bytes) {
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
  }

  var total = 0;
  for (final path in files) {
    final bytes = File('${root.path}/$path').readAsBytesSync();
    total += bytes.length;
    feed(utf8.encode(path));
    feed(bytes);
  }
  final version =
      BigInt.from(hash).toUnsigned(64).toRadixString(16).padLeft(16, '0');

  final source = worker.readAsStringSync();
  if (!source.contains('__CQ_VERSION__')) {
    stderr.writeln('Service worker déjà complété.');
    exit(1);
  }
  worker.writeAsStringSync(source
      .replaceFirst('__CQ_VERSION__', version)
      .replaceFirst('/* __CQ_PRECACHE__ */ []', jsonEncode(files)));

  stdout.writeln('Service worker $version : ${files.length} fichiers, '
      '${(total / 1024 / 1024).toStringAsFixed(1)} Mo en cache.');
}
