import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../legal/consent.dart';
import '../../reminders/reminder_service.dart';
import '../../pomodoro/providers/pomodoro_provider.dart';
import '../../pomodoro/widgets/pomodoro_settings_form.dart';
import '../domain/user_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/delete_account_button.dart';
import '../widgets/demo_data_button.dart';
import '../widgets/export_data_tile.dart';
import '../widgets/sign_out_button.dart';
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
      // Colonne de lecture confortable sur grand écran.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                Space.xl, Space.sm, Space.xl, Space.xxxl),
            children: [
              const _SectionLabel("Apparence de l'application"),
              const SizedBox(height: Space.md),
              _ThemePicker(
                selected: settings.themeVariant,
                onSelect: notifier.setTheme,
              ),
              const SizedBox(height: Space.xl),

              const _SectionLabel('Taille du texte'),
              const SizedBox(height: Space.xs),
              Text(
                'S\'applique à toute l\'application, y compris aux écrans déjà '
                'ouverts.',
                style: TextStyle(
                    fontSize: TypeScale.caption, color: context.cq.textMuted),
              ),
              const SizedBox(height: Space.md),
              _TextScaleSelector(
                selected: settings.textScale,
                onSelect: notifier.setTextScale,
              ),
              const SizedBox(height: Space.xl),

              // Ambiance sonore : retirée de l'interface en attendant une
              // intégration externe (le moteur reste en place, inactif).
              const _SectionLabel('Paramètres de concentration'),
              const SizedBox(height: Space.xs),
              Text(
                'Durées, nombre de sessions (la dernière est suivie de la '
                'pause longue) et sonnerie de fin.',
                style: TextStyle(
                    fontSize: TypeScale.caption,
                    color: context.cq.textMuted,
                    height: 1.4),
              ),
              const SizedBox(height: Space.md),
              _PomodoroSettings(
                config: settings.pomodoro,
                onChanged: notifier.setPomodoro,
                onPreview: (ringtone) =>
                    ref.read(pomodoroChimeProvider).play(ringtone),
              ),
              const SizedBox(height: Space.xl),

              const _SectionLabel('Rappels'),
              const SizedBox(height: Space.md),
              const _RemindersPanel(),
              const SizedBox(height: Space.xl),

              const _SectionLabel('Confort et accessibilité'),
              const SizedBox(height: Space.md),
              _Panel(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: Space.lg),
                    value: settings.reduceMotion,
                    onChanged: (_) => notifier.toggleReduceMotion(),
                    title: const Text('Réduire les animations',
                        style: TextStyle(fontSize: TypeScale.body)),
                    subtitle: Text(
                      'Transitions plus courtes, moins de mouvement à l\'écran',
                      style: TextStyle(
                          fontSize: TypeScale.caption,
                          color: context.cq.textMuted),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: Space.lg),
                    value: settings.keyboardShortcutsEnabled,
                    onChanged: (_) => notifier.toggleKeyboardShortcuts(),
                    title: const Text('Raccourcis clavier',
                        style: TextStyle(fontSize: TypeScale.body)),
                    subtitle: Text(
                      'Navigation rapide au clavier sur web et bureau',
                      style: TextStyle(
                          fontSize: TypeScale.caption,
                          color: context.cq.textMuted),
                    ),
                  ),
                ],
              ),
              if (settings.keyboardShortcutsEnabled) ...[
                const SizedBox(height: Space.xl),
                const _SectionLabel('Raccourcis clavier essentiels'),
                const SizedBox(height: Space.md),
                const _ShortcutList(),
              ],
              const SizedBox(height: Space.xl),

              const _SectionLabel('Confidentialité'),
              const SizedBox(height: Space.md),
              const _PrivacyPanel(),
              const SizedBox(height: Space.xl),

              const _SectionLabel('Gestion des données'),
              const SizedBox(height: Space.md),
              const DemoDataButton(),
              const SizedBox(height: Space.md),
              // Action réversible : filet écorce discret, sans alarme.
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.cq.terre,
                  backgroundColor: context.cq.cardColor,
                  side: BorderSide(color: context.cq.terre),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.sm)),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    animationStyle: Motion.style(context),
                    builder: (context) => AlertDialog(
                      scrollable: true,
                      title: const Text('Rétablir les réglages ?'),
                      content: const Text(
                        'Thème, taille de texte et Pomodoro reviendront à leurs '
                        'valeurs d\'origine, et les encadrés d\'aide fermés '
                        'réapparaîtront. Tes données ne sont pas touchées.',
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
                icon: const Icon(Icons.settings_backup_restore,
                    size: Sizes.iconMd),
                label: const Text('Rétablir les réglages par défaut'),
              ),

              // Absent en mode démo : il n'y a pas de compte à supprimer.
              if (ref.watch(currentUserProvider) != null) ...[
                const SizedBox(height: Space.xl),
                const _SectionLabel('Compte'),
                const SizedBox(height: Space.md),
                const SignOutButton(),
                const SizedBox(height: Space.xl),
                const _SensitiveZone(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Largeur maximale de la colonne des réglages.
  static const double _maxWidth = 720;
}

/// Groupe de réglages : carte blanche à filet, lignes séparées par un
/// filet d'un pixel.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    // Un `Material` (pas une décoration) : les interrupteurs y gardent leur
    // effet d'appui.
    return Material(
      color: cq.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: cq.beigeDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(
                  height: Borders.thin,
                  thickness: Borders.thin,
                  color: cq.beigeDark),
            child,
          ],
        ],
      ),
    );
  }
}

/// Rappel quotidien de révision et notifications du Pomodoro. Activer l'un
/// ou l'autre demande l'autorisation du système (geste de l'utilisateur,
/// exigé par les navigateurs).
class _RemindersPanel extends ConsumerWidget {
  const _RemindersPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final service = ref.read(reminderServiceProvider);
    TextStyle caption() =>
        TextStyle(fontSize: TypeScale.caption, color: cq.textMuted);

    Future<void> pickTime() async {
      final minutes = settings.dailyReminderMinutes;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        helpText: 'Heure du rappel',
        cancelText: 'Annuler',
        confirmText: 'Valider',
      );
      if (picked != null) {
        notifier.setDailyReminderMinutes(picked.hour * 60 + picked.minute);
      }
    }

    return _Panel(
      children: [
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
          value: settings.dailyReminder,
          onChanged: (enabled) async {
            if (enabled) await service.requestPermission();
            notifier.setDailyReminder(enabled);
          },
          title: const Text('Rappel quotidien de révision',
              style: TextStyle(fontSize: TypeScale.body)),
          subtitle: Text(
            kIsWeb
                ? 'Notification à heure fixe, tant que l’app est ouverte'
                : 'Notification à heure fixe, même app fermée',
            style: caption(),
          ),
        ),
        if (settings.dailyReminder)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
            title: const Text('Heure du rappel',
                style: TextStyle(fontSize: TypeScale.body)),
            trailing: Text(
              reminderTimeLabel(settings.dailyReminderMinutes),
              style: TextStyle(
                fontSize: TypeScale.body,
                fontWeight: FontWeight.w600,
                color: cq.textPrimary,
                fontFeatures: TypeScale.tabular,
              ),
            ),
            onTap: pickTime,
          ),
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
          value: settings.pomodoroNotifications,
          onChanged: (enabled) async {
            if (enabled) await service.requestPermission();
            notifier.setPomodoroNotifications(enabled);
          },
          title: const Text('Notification de fin de Pomodoro',
              style: TextStyle(fontSize: TypeScale.body)),
          subtitle: Text('À la fin de chaque session et de chaque pause',
              style: caption()),
        ),
      ],
    );
  }
}

/// Textes légaux, consentement aux données de bien-être (facultatif) et
/// export des données.
class _PrivacyPanel extends ConsumerWidget {
  const _PrivacyPanel();

  /// Le retrait efface des données : confirmation d'abord.
  Future<void> _setWellbeing(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Retirer ton accord ?'),
          content: const Text(
            'Ton journal, tes recadrages et tes chaînes des 5 pourquoi seront '
            'effacés de cet appareil et du serveur. Le journal et le '
            'recadrage seront désactivés.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retirer et effacer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(consentProvider.notifier).setWellbeing(enabled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cq = context.cq;
    final wellbeing = ref.watch(wellbeingConsentProvider);
    Widget link(String title, String route) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
          title: Text(title, style: const TextStyle(fontSize: TypeScale.body)),
          trailing: Icon(Icons.chevron_right,
              size: Sizes.iconMd, color: cq.vertSauge),
          onTap: () => context.push(route),
        );
    return _Panel(
      children: [
        link('Politique de confidentialité', LegalRoute.privacy),
        link('Mentions légales', LegalRoute.notice),
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
          value: wellbeing,
          onChanged: (enabled) => _setWellbeing(context, ref, enabled),
          title: const Text('Analyse de mon bien-être',
              style: TextStyle(fontSize: TypeScale.body)),
          subtitle: Text(
            wellbeing
                ? 'Humeur, fatigue, journal et recadrages servent aux conseils. '
                    'Le retrait les efface.'
                : 'Facultatif. Active-la pour utiliser le journal, le '
                    'recadrage et les conseils tirés de ton humeur.',
            style: TextStyle(fontSize: TypeScale.caption, color: cq.textMuted),
          ),
        ),
        const ExportDataTile(),
      ],
    );
  }
}

/// Zone sensible : un encadré sobre, filet écorce, pour l'action
/// irréversible.
class _SensitiveZone extends StatelessWidget {
  const _SensitiveZone();

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: cq.terre.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Zone sensible',
            style: TextStyle(
              fontSize: TypeScale.body,
              fontWeight: FontWeight.w600,
              color: cq.terre,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'La suppression du compte efface définitivement tes données.',
            style: TextStyle(fontSize: TypeScale.caption, color: cq.textMuted),
          ),
          const SizedBox(height: Space.md),
          const DeleteAccountButton(),
        ],
      ),
    );
  }
}

/// Taille du texte : piste pierre, segment actif blanc à filet.
class _TextScaleSelector extends StatelessWidget {
  const _TextScaleSelector({required this.selected, required this.onSelect});

  final TextScalePreset selected;
  final ValueChanged<TextScalePreset> onSelect;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      padding: const EdgeInsets.all(Space.xs / 2),
      decoration: BoxDecoration(
        color: cq.sauge,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Row(
        children: [
          for (final preset in TextScalePreset.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: preset == selected,
                child: Material(
                  color: preset == selected ? cq.cardColor : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.xs),
                    side: preset == selected
                        ? BorderSide(color: cq.beigeDark)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.xs),
                    onTap: () => onSelect(preset),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(minHeight: Sizes.touchTarget - Space.sm),
                      child: Center(
                        // À 200 % de texte, le libellé rétrécit au lieu de
                        // déborder.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Space.xs),
                            child: Text(
                              preset.label,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: TypeScale.caption,
                                fontWeight: preset == selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: preset == selected
                                    ? cq.textPrimary
                                    : cq.terre,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Durées et cycles du Pomodoro, chacun avec – / + (bornes de
/// [PomodoroSettings]), puis la sonnerie de fin de phase.
class _PomodoroSettings extends StatelessWidget {
  const _PomodoroSettings({
    required this.config,
    required this.onChanged,
    required this.onPreview,
  });

  final PomodoroSettings config;
  final ValueChanged<PomodoroSettings> onChanged;

  /// Fait entendre une sonnerie au moment où on la choisit.
  final ValueChanged<PomodoroRingtone> onPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Panel(children: [
          PomodoroDurationsForm(config: config, onChanged: onChanged),
        ]),
        const SizedBox(height: Space.lg),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text('Sonnerie de fin',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: Space.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final ringtone in PomodoroRingtone.values)
                ChoiceChip(
                  label: Text(ringtone.label),
                  selected: ringtone == config.ringtone,
                  showCheckmark: false,
                  onSelected: (_) {
                    onChanged(config.copyWith(ringtone: ringtone));
                    onPreview(ringtone);
                  },
                ),
            ],
          ),
        ),
      ],
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
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: InkWell(
              onTap: () => onSelect(variant),
              borderRadius: BorderRadius.circular(Radii.card),
              child: AnimatedContainer(
                duration:
                    Motion.duration(context, const Duration(milliseconds: 150)),
                padding: const EdgeInsets.all(14),
                // Carte radio épurée : blanche, la carte active cerclée de
                // sauge.
                decoration: BoxDecoration(
                  color: context.cq.cardColor,
                  borderRadius: BorderRadius.circular(Radii.card),
                  border: Border.all(
                    color: variant == selected
                        ? context.cq.vertSauge
                        : context.cq.beigeDark,
                    width: variant == selected ? Borders.focus : Borders.thin,
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
                                  color: context.cq.terre)),
                        ],
                      ),
                    ),
                    Icon(
                      variant == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 19,
                      color: variant == selected
                          ? context.cq.vertSauge
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
    final cq = context.cq;
    return _Panel(
      children: [
        for (final (keys, description) in _shortcuts)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.lg, vertical: Space.md),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(description,
                      style: TextStyle(
                          fontSize: TypeScale.body, color: cq.textPrimary)),
                ),
                const SizedBox(width: Space.md),
                // Touche physique stylisée, alignée à droite. Flexible : à
                // 200 %, elle passe à la ligne au lieu de déborder.
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.sm, vertical: Space.xs / 2),
                    decoration: BoxDecoration(
                      color: cq.parchemin,
                      borderRadius: BorderRadius.circular(Radii.xs),
                      border: Border.all(color: cq.beigeDark),
                      // Relief de touche : un filet plus marqué dessous.
                      boxShadow: [
                        BoxShadow(
                            color: cq.beigeDark,
                            offset: const Offset(0, Borders.thin)),
                      ],
                    ),
                    child: Text(keys,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: TypeScale.caption,
                          fontWeight: FontWeight.w700,
                          color: cq.terre,
                          fontFeatures: TypeScale.tabular,
                        )),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}
