import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/planning_model.dart' show formatDecimal;
import '../domain/graph_settings.dart';
import '../providers/graph_provider.dart';

/// Panneau de réglages du graphe, en quatre sections : filtres, groupes,
/// affichage, forces. Chaque changement s'applique en direct à la carte.
class GraphSettingsSheet extends ConsumerStatefulWidget {
  const GraphSettingsSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        sheetAnimationStyle: Motion.style(context),
        isScrollControlled: true,
        showDragHandle: true,
        // La carte reste visible derrière : on voit l'effet des curseurs.
        barrierColor: Colors.transparent,
        builder: (_) => const GraphSettingsSheet(),
      );

  @override
  ConsumerState<GraphSettingsSheet> createState() => _GraphSettingsSheetState();
}

class _GraphSettingsSheetState extends ConsumerState<GraphSettingsSheet> {
  late final _query =
      TextEditingController(text: ref.read(graphSettingsProvider).query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _update(GraphSettings Function(GraphSettings) change) =>
      ref.read(graphSettingsProvider.notifier).update(change);

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final settings = ref.watch(graphSettingsProvider);
    final forces = settings.forces;

    Widget toggle(String title, String subtitle, bool value,
            GraphSettings Function(GraphSettings, bool) change) =>
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: value,
          onChanged: (v) => _update((s) => change(s, v)),
          title: Text(title, style: const TextStyle(fontSize: TypeScale.body)),
          subtitle: Text(subtitle,
              style:
                  TextStyle(fontSize: TypeScale.caption, color: cq.textMuted)),
        );

    Widget slider(
      String label,
      double value,
      ({double min, double max}) range,
      ValueChanged<double> onChanged, {
      String Function(double)? format,
    }) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: TypeScale.body, color: cq.textPrimary)),
                ),
                Text(
                  (format ?? (v) => formatDecimal(v, maxDigits: 2))(value),
                  style: TextStyle(
                    fontSize: TypeScale.caption,
                    fontWeight: FontWeight.w600,
                    color: cq.textMuted,
                    fontFeatures: TypeScale.tabular,
                  ),
                ),
              ],
            ),
            Slider(
              value: value.clamp(range.min, range.max),
              min: range.min,
              max: range.max,
              label: label,
              onChanged: onChanged,
            ),
          ],
        );

    Widget section(String title, IconData icon, List<Widget> children,
            {bool initiallyExpanded = false}) =>
        Theme(
          // Pas de filets Material autour des sections dépliées.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: Space.md),
            leading: Icon(icon, size: Sizes.iconMd, color: cq.vertSauge),
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
            children: children,
          ),
        );

    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg,
              Space.lg + MediaQuery.viewInsetsOf(context).bottom),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Réglages du graphe',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: () {
                    _query.clear();
                    ref.read(graphSettingsProvider.notifier).reset();
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            section('Filtres', Icons.filter_alt_outlined, initiallyExpanded: true, [
              TextField(
                controller: _query,
                onChanged: (q) => _update((s) => s.copyWith(query: q)),
                decoration: InputDecoration(
                  labelText: 'Rechercher des fiches',
                  hintText: 'Titre, tag, sujet ou mot du texte',
                  prefixIcon: const Icon(Icons.search, size: Sizes.iconMd),
                  suffixIcon: settings.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Effacer la recherche',
                          icon: const Icon(Icons.close, size: Sizes.iconSm),
                          onPressed: () {
                            _query.clear();
                            _update((s) => s.copyWith(query: ''));
                          },
                        ),
                ),
              ),
              const SizedBox(height: Space.sm),
              toggle('Pièces jointes', 'Images, vidéos et PDF en satellites',
                  settings.showAttachments,
                  (s, v) => s.copyWith(showAttachments: v)),
              toggle(
                  'Fichiers existants uniquement',
                  'Masquer les [[liens]] vers des fiches qui n’existent pas',
                  settings.existingOnly,
                  (s, v) => s.copyWith(existingOnly: v)),
              toggle('Fiches orphelines', 'Afficher les fiches sans lien',
                  settings.showOrphans, (s, v) => s.copyWith(showOrphans: v)),
            ]),
            section('Groupes', Icons.workspaces_outline, [
              toggle('Couleur par dossier', 'Une teinte par dossier',
                  settings.colorByFolder,
                  (s, v) => s.copyWith(colorByFolder: v)),
              toggle('Regrouper par dossier',
                  'Les fiches d’un même dossier se rapprochent',
                  settings.groupByFolder,
                  (s, v) => s.copyWith(groupByFolder: v)),
              toggle('Couleur par type de lien',
                  'Lié à, vu, à revoir, prérequis',
                  settings.colorLinksByType,
                  (s, v) => s.copyWith(colorLinksByType: v)),
            ]),
            section('Affichage', Icons.tune, [
              slider(
                'Seuil d’apparition des titres',
                settings.labelThreshold,
                GraphSettings.labelRange,
                (v) => _update((s) => s.copyWith(labelThreshold: v)),
                format: (v) => 'zoom × ${formatDecimal(v, maxDigits: 2)}',
              ),
              slider('Taille des nœuds', settings.nodeSize,
                  GraphSettings.nodeSizeRange,
                  (v) => _update((s) => s.copyWith(nodeSize: v)),
                  format: (v) => '× ${formatDecimal(v, maxDigits: 1)}'),
              slider('Épaisseur des liens', settings.linkThickness,
                  GraphSettings.linkRange,
                  (v) => _update((s) => s.copyWith(linkThickness: v)),
                  format: (v) => '× ${formatDecimal(v, maxDigits: 1)}'),
            ]),
            section('Forces', Icons.scatter_plot_outlined, [
              slider('Force centrale', forces.center, GraphForces.centerRange,
                  (v) => _update((s) =>
                      s.copyWith(forces: s.forces.copyWith(center: v)))),
              slider('Force de répulsion', forces.repel,
                  GraphForces.repelRange,
                  (v) => _update((s) =>
                      s.copyWith(forces: s.forces.copyWith(repel: v)))),
              slider('Force de liaison', forces.link, GraphForces.linkRange,
                  (v) => _update((s) =>
                      s.copyWith(forces: s.forces.copyWith(link: v)))),
              slider('Distance entre les liens', forces.distance,
                  GraphForces.distanceRange,
                  (v) => _update((s) =>
                      s.copyWith(forces: s.forces.copyWith(distance: v))),
                  format: (v) => '${v.round()}'),
            ]),
          ],
        ),
      ),
    );
  }
}
