import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/user_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/delete_account_button.dart';
import '../widgets/sign_out_button.dart';
import '../widgets/routine_editor.dart';
import '../../../core/theme/tokens.dart';

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
            style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
          ),
          const SizedBox(height: 10),
          SegmentedButton<TextScalePreset>(
            segments: [
              for (final preset in TextScalePreset.values)
                ButtonSegment(
                  value: preset,
                  label: Text(preset.label,
                      style: const TextStyle(fontSize: TypeScale.caption)),
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
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            // Aperçu en direct : l'utilisateur voit l'effet avant de quitter
            // l'écran.
            child: Text(
              'Aperçu — CognicQuest t\'aide à apprendre mieux, chaque jour.',
              style: TextStyle(
                  fontSize: TypeScale.body, height: 1.45, color: context.cq.textPrimary),
            ),
          ),
          const SizedBox(height: 26),

          // Ambiance sonore : retirée de l'interface en attendant une
          // intégration externe (le moteur reste en place, inactif).
          const _SectionLabel('Pomodoro'),
          const SizedBox(height: Space.xs),
          Text(
            'Règle tes cycles de concentration : durées et nombre de '
            'sessions avant la pause longue.',
            style: TextStyle(
                fontSize: TypeScale.caption,
                color: context.cq.textMuted,
                height: 1.4),
          ),
          const SizedBox(height: Space.sm),
          _PomodoroSettings(
            config: settings.pomodoro,
            onChanged: notifier.setPomodoro,
          ),
          const SizedBox(height: Space.xl),

          const _SectionLabel('Confort et accessibilité'),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: settings.reduceMotion,
            onChanged: (_) => notifier.toggleReduceMotion(),
            title: const Text('Réduire les animations',
                style: TextStyle(fontSize: TypeScale.body)),
            subtitle: Text(
              'Transitions plus courtes, moins de mouvement à l\'écran',
              style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: settings.keyboardShortcutsEnabled,
            onChanged: (_) => notifier.toggleKeyboardShortcuts(),
            title: const Text('Raccourcis clavier',
                style: TextStyle(fontSize: TypeScale.body)),
            subtitle: Text(
              'Navigation rapide au clavier sur web et bureau',
              style: TextStyle(fontSize: TypeScale.caption, color: context.cq.textMuted),
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
                fontSize: TypeScale.caption, color: context.cq.textMuted, height: 1.4),
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
                  scrollable: true,
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
            const SignOutButton(),
            const SizedBox(height: Space.sm),
            const DeleteAccountButton(),
          ],
        ],
      ),
    );
  }
}

/// Durées et cycles du Pomodoro, chacun avec – / + (bornes de
/// [PomodoroSettings]).
class _PomodoroSettings extends StatelessWidget {
  const _PomodoroSettings({required this.config, required this.onChanged});

  final PomodoroSettings config;
  final ValueChanged<PomodoroSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Stepper(
          label: 'Session de travail',
          value: config.workMinutes,
          unit: 'min',
          range: PomodoroSettings.workRange,
          step: 5,
          onChanged: (v) => onChanged(config.copyWith(workMinutes: v)),
        ),
        _Stepper(
          label: 'Pause courte',
          value: config.shortBreakMinutes,
          unit: 'min',
          range: PomodoroSettings.shortBreakRange,
          step: 1,
          onChanged: (v) => onChanged(config.copyWith(shortBreakMinutes: v)),
        ),
        _Stepper(
          label: 'Pause longue',
          value: config.longBreakMinutes,
          unit: 'min',
          range: PomodoroSettings.longBreakRange,
          step: 5,
          onChanged: (v) => onChanged(config.copyWith(longBreakMinutes: v)),
        ),
        _Stepper(
          label: 'Sessions avant la pause longue',
          value: config.sessionsBeforeLongBreak,
          unit: '',
          range: PomodoroSettings.sessionsRange,
          step: 1,
          onChanged: (v) =>
              onChanged(config.copyWith(sessionsBeforeLongBreak: v)),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.range,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final (int, int) range;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = unit.isEmpty ? '$value' : '$value $unit';
    return Semantics(
      label: label,
      value: text,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(
            tooltip: 'Diminuer : $label',
            onPressed: value <= range.$1
                ? null
                : () => onChanged((value - step).clamp(range.$1, range.$2)),
            icon: const Icon(Icons.remove, size: Sizes.iconMd),
          ),
          SizedBox(
            width: Space.xxxl + Space.lg,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Augmenter : $label',
            onPressed: value >= range.$2
                ? null
                : () => onChanged((value + step).clamp(range.$1, range.$2)),
            icon: const Icon(Icons.add, size: Sizes.iconMd),
          ),
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
              borderRadius: BorderRadius.circular(Radii.md),
              child: AnimatedContainer(
                duration: Motion.duration(context, const Duration(milliseconds: 150)),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: variant == selected
                      ? context.cq.vert.withValues(alpha: 0.1)
                      : context.cq.cardColor,
                  borderRadius: BorderRadius.circular(Radii.md),
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
                                  fontSize: TypeScale.body,
                                  fontWeight: FontWeight.w600,
                                  color: context.cq.textPrimary)),
                          const SizedBox(height: 1),
                          Text(variant.description,
                              style: TextStyle(
                                  fontSize: TypeScale.caption,
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
        borderRadius: BorderRadius.circular(Radii.md),
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
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 14,
            height: 4,
            decoration: BoxDecoration(
              color: palette.textMuted,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(Radii.md),
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
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: context.cq.beigeDark),
                    ),
                    child: Text(keys,
                        style: TextStyle(
                            fontSize: TypeScale.caption,
                            fontFamily: 'monospace',
                            color: context.cq.textPrimary)),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(description,
                        style: TextStyle(
                            fontSize: TypeScale.caption, color: context.cq.textMuted)),
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
          fontSize: TypeScale.body,
          fontWeight: FontWeight.w600,
          color: context.cq.textPrimary,
        ),
      );
}
