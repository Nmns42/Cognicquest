import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media/media_store.dart';

/// Image d'une fiche ou d'une carte, quelle que soit sa source :
/// - `media://…` : déposée dans Storage (cache local, sinon téléchargée) ;
/// - `data:image/…;base64,…` : ancien format, encodée dans le texte ;
/// - `http(s)://…` : lien.
///
/// [broken] s'affiche si l'image est illisible ou introuvable.
class MediaImage extends ConsumerWidget {
  const MediaImage({
    super.key,
    required this.source,
    required this.broken,
    this.fit = BoxFit.contain,
  });

  final String source;
  final WidgetBuilder broken;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget fallback(BuildContext context, Object _, StackTrace? __) =>
        broken(context);

    if (MediaStore.isMediaRef(source)) {
      final bytes = ref.watch(mediaBytesProvider(source));
      return bytes.when(
        data: (data) => data == null
            ? broken(context)
            : Image.memory(data, fit: fit, errorBuilder: fallback),
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => broken(context),
      );
    }
    if (source.startsWith('data:')) {
      Uint8List? bytes;
      try {
        bytes = base64Decode(source.substring(source.indexOf(',') + 1));
      } catch (_) {
        bytes = null;
      }
      return bytes == null
          ? broken(context)
          : Image.memory(bytes, fit: fit, errorBuilder: fallback);
    }
    return Image.network(source, fit: fit, errorBuilder: fallback);
  }
}

/// Dépose l'image choisie dans Storage et renvoie sa référence ; sans
/// compte (mode démo), retombe sur l'image encodée dans le texte.
Future<String> storeImage(
  BuildContext context,
  Uint8List bytes, {
  String? extension,
}) async {
  final store = ProviderScope.containerOf(context, listen: false)
      .read(mediaStoreProvider);
  if (store != null) return store.put(bytes, extension: extension);
  return 'data:${MediaStore.mimeOf(extension)};base64,${base64Encode(bytes)}';
}
