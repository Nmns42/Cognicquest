import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/ui/ui.dart';
import '../../dev/demo_seed.dart';
import '../../sync/providers/sync_coordinator.dart';

/// « Charger les données de démo » : remplit le compte d'un jeu réaliste
/// (tâches dans les trois colonnes, fiches rangées en dossiers et reliées,
/// habitudes cochées, cartes, journal, planning) pour voir l'application
/// pleinement utilisée, y compris sur la version déployée.
class DemoDataButton extends ConsumerStatefulWidget {
  const DemoDataButton({super.key});

  @override
  ConsumerState<DemoDataButton> createState() => _DemoDataButtonState();
}

class _DemoDataButtonState extends ConsumerState<DemoDataButton> {
  bool _loading = false;

  Future<void> _load() async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: Motion.style(context),
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Charger les données de démo ?'),
        content: const Text(
          'Des fiches, dossiers, tâches, habitudes, cartes de révision, '
          'entrées de journal et objectifs d’exemple sont ajoutés à ton '
          'compte et synchronisés. Tes propres données ne sont pas touchées ; '
          'tu pourras supprimer les exemples un par un.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Charger'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _loading = true);
    DemoLoadResult result;
    try {
      result = await loadDemoData(ref.read);
    } catch (_) {
      result = DemoLoadResult.unavailable;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == DemoLoadResult.loaded) {
      ref.read(syncCoordinatorProvider.notifier).syncNow().ignore();
    }

    final message = switch (result) {
      DemoLoadResult.loaded => 'Données de démo chargées.',
      DemoLoadResult.alreadyLoaded => 'Les données de démo sont déjà là.',
      DemoLoadResult.unavailable =>
        'Chargement impossible pour le moment. Réessaie.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      snackBarAnimationStyle: Motion.style(context),
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CqButton.secondary(
      label: 'Charger les données de démo',
      icon: Icons.auto_awesome_outlined,
      isLoading: _loading,
      onPressed: _load,
    );
  }
}
