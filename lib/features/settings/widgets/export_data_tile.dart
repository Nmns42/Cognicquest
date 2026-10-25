import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../legal/consent.dart';
import '../../notes/widgets/folder_explorer.dart' show saveExport;
import '../../sync/providers/sync_coordinator.dart';
import '../data/data_export.dart';

/// « Exporter mes données » : un fichier JSON de tout le compte (droits
/// d'accès et de portabilité).
class ExportDataTile extends ConsumerStatefulWidget {
  const ExportDataTile({super.key});

  @override
  ConsumerState<ExportDataTile> createState() => _ExportDataTileState();
}

class _ExportDataTileState extends ConsumerState<ExportDataTile> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      // Rapatrie d'abord ce qui vient des autres appareils ; hors ligne,
      // l'export porte sur ce que l'appareil connaît.
      try {
        await ref
            .read(syncCoordinatorProvider.notifier)
            .syncNow()
            .timeout(const Duration(seconds: 20));
      } catch (_) {}
      final consent = ref.read(consentProvider).valueOrNull;
      final now = DateTime.now();
      final export = await UserDataExport.collect(
        ref.read(appDatabaseProvider),
        userId: ref.read(currentUserIdProvider) ?? '',
        email: ref.read(currentUserProvider)?.email,
        consent: {
          'version': consent?.version ?? 0,
          'wellbeing': consent?.wellbeing ?? false,
        },
        now: now,
      );
      if (!mounted) return;
      await saveExport(
          context, UserDataExport.fileName(now), UserDataExport.encode(export),
          mimeType: 'application/json');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
      title: const Text('Exporter mes données',
          style: TextStyle(fontSize: TypeScale.body)),
      subtitle: Text(
        'Un fichier JSON avec tes fiches, cartes, révisions, tâches, '
        'habitudes, journal et réglages, et les images gardées sur cet '
        'appareil.',
        style: TextStyle(fontSize: TypeScale.caption, color: cq.textMuted),
      ),
      trailing: _busy
          ? const SizedBox.square(
              dimension: Sizes.iconMd,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.download_outlined,
              size: Sizes.iconMd, color: cq.vertSauge),
      onTap: _busy ? null : _export,
    );
  }
}
