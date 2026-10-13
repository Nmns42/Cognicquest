import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/ambient_sound_engine.dart';
import '../domain/user_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/delete_account_button.dart';
import '../widgets/routine_editor.dart';

/// Système de configuration — « Changement de thème, taille du texte,
/// raccourcis clavier » et « sons d'ambiance réglables individuellement »
/// (CdC).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          const _SectionLabel('Apparence'),
          const SizedBox(height: 10),
          _ThemePicker(
            selected: settings.themeVariant,
            onSelect: notifier.setTheme,
          ),
          const SizedBox(height: 22),

          const _SectionLabel('Taille du texte'),
          const SizedBox(height: 4),
          Text(
            'S\'applique à toute l\'application, y compris aux écrans déjà '
            'ouverts.',
            style: TextStyle(fontSize: 11.5, color: context.cq.textMuted),
          ),
          const SizedBox(height: 10),
          SegmentedButton<TextScalePreset>(
            segments: [
              for (final preset in TextScalePreset.values)
                ButtonSegment(
                  value: preset,
                  label: Text(preset.label,
                      style: const TextStyle(fontSize: 11)),
                ),
            ],
            selected: {settings.textScale},
            showSelectedIcon: false,
            onSelectionChanged: (values) =>
                notifier.setTextScale(values.first),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cq.beigeDark.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            // Aperçu en direct : l'utilisateur voit l'effet avant de quitter
            // l'écran.
            child: Text(
              'Aperçu — CognicQuest t\'aide à apprendre mieux, chaque jour.',
              style: TextStyle(
                  fontSize: 14, height: 1.45, color: context.cq.textPrimary),
            ),
          ),
          const SizedBox(height: 26),

          const _SectionLabel('Ambiance sonore'),
          const SizedBox(height: 4),
          Text(
            'Un fond sonore constant masque les bruits parasites et aide à '
            'rester en place.',
            style: TextStyle(
                fontSize: 11.5, color: context.cq.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          _SoundPicker(settings: settings, notifier: notifier),
          const SizedBox(height: 26),

          const _SectionLabel('Confort et accessibilité'),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: settings.reduceMotion,
            onChanged: (_) => notifier.toggleReduceMotion(),
            title: const Text('Réduire les animations',
                style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Transitions plus courtes, moins de mouvement à l\'écran',
              style: TextStyle(fontSize: 12, color: context.cq.textMuted),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: settings.keyboardShortcutsEnabled,
            onChanged: (_) => notifier.toggleKeyboardShortcuts(),
            title: const Text('Raccourcis clavier',
                style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Navigation rapide au clavier sur web et bureau',
              style: TextStyle(fontSize: 12, color: context.cq.textMuted),
            ),
          ),
          if (settings.keyboardShortcutsEnabled) ...[
            const SizedBox(height: 10),
            const _ShortcutList(),
          ],
          const SizedBox(height: 26),

          const _SectionLabel('Routines'),
          const SizedBox(height: 4),
          Text(
            'Un cadre fixe le matin et le soir coûte moins d\'énergie qu\'une '
            'décision à reprendre chaque jour.',
            style: TextStyle(
                fontSize: 11.5, color: context.cq.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          RoutineEditor(
            title: 'Routine du matin',
            icon: Icons.wb_twilight,
            routine: settings.morningRoutine,
            onChanged: notifier.setMorningRoutine,
          ),
          const SizedBox(height: 10),
          RoutineEditor(
            title: 'Routine du soir',
            icon: Icons.nightlight_outlined,
            routine: settings.eveningRoutine,
            onChanged: notifier.setEveningRoutine,
          ),
          const SizedBox(height: 28),

          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                animationStyle: Motion.style(context),
                builder: (context) => AlertDialog(
                  title: const Text('Rétablir les réglages ?'),
                  content: const Text(
                    'Thème, taille de texte, sons et routines reviendront à '
                    'leurs valeurs d\'origine. Tes données ne sont pas '
                    'touchées.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Rétablir'),
                    ),
                  ],
                ),
              );
              if (confirmed ?? false) notifier.resetToDefaults();
            },
            icon: const Icon(Icons.settings_backup_restore, size: 18),
            label: const Text('Rétablir les réglages par défaut'),
          ),

          // Absent en mode démo : il n'y a pas de compte à supprimer.
          if (ref.watch(currentUserProvider) != null) ...[
            const SizedBox(height: 32),
            const _SectionLabel('Compte'),
            const SizedBox(height: 10),
            const DeleteAccountButton(),
          ],
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onSelect});

  final AppThemeVariant selected;
  final ValueChanged<AppThemeVariant> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final variant in AppThemeVariant.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onSelect(variant),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: Motion.duration(context, const Duration(milliseconds: 150)),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: variant == selected
                      ? context.cq.vert.withValues(alpha: 0.1)
                      : context.cq.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: variant == selected
                        ? context.cq.vert
                        : context.cq.beigeDark,
                    width: variant == selected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    _Swatch(variant: variant),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(variant.label,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.cq.textPrimary)),
                          const SizedBox(height: 1),
                          Text(variant.description,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: context.cq.textMuted)),
                        ],
                      ),
                    ),
                    Icon(
                      variant == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 19,
                      color: variant == selected
                          ? context.cq.vert
                          : context.cq.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Échantillon des couleurs réelles de la variante, pas une pastille unique :
/// on choisit un thème sur son rapport fond/accent, pas sur une seule teinte.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.variant});

  final AppThemeVariant variant;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsFor(variant);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.beige,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: palette.beigeDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 6,
            decoration: BoxDecoration(
              color: palette.vert,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 14,
            height: 4,
            decoration: BoxDecoration(
              color: palette.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundPicker extends ConsumerWidget {
  const _SoundPicker({required this.settings, required this.notifier});

  final UserSettings settings;
  final SettingsNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(ambientSoundEngineProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sound in AmbientSound.available)
              ChoiceChip(
                label: Text(sound.label, style: const TextStyle(fontSize: 12)),
                selected: settings.ambientSound == sound,
                onSelected: (_) {
                  notifier.setAmbientSound(sound);
                  engine.play(sound, volume: settings.ambientVolume);
                },
              ),
          ],
        ),
        if (!settings.ambientSound.isSilent) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.volume_down,
                  size: 18, color: context.cq.textMuted),
              Expanded(
                child: Slider(
                  value: settings.ambientVolume,
                  activeColor: context.cq.vert,
                  onChanged: (value) {
                    notifier.setAmbientVolume(value);
                    engine.setVolume(value);
                  },
                ),
              ),
              Icon(Icons.volume_up, size: 18, color: context.cq.textMuted),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cq.beigeDark.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Ces ambiances sont générées par l\'application : aucun fichier à '
            'télécharger. Pluie, café et vent demandent des enregistrements '
            'à déposer dans assets/sounds/.',
            style: TextStyle(
                fontSize: 11.5, color: context.cq.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ShortcutList extends StatelessWidget {
  const _ShortcutList();

  static const List<(String, String)> _shortcuts = [
    ('Ctrl + 1 … 4', "Aller à l'espace correspondant"),
    ('Ctrl + N', 'Nouvelle fiche'),
    ('Ctrl + K', 'Rechercher dans les fiches'),
    ('Ctrl + ,', 'Ouvrir les réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cq.beigeDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final (keys, description) in _shortcuts)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.cq.cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.cq.beigeDark),
                    ),
                    child: Text(keys,
                        style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: context.cq.textPrimary)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(description,
                        style: TextStyle(
                            fontSize: 12, color: context.cq.textMuted)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.cq.textPrimary,
        ),
      );
}
