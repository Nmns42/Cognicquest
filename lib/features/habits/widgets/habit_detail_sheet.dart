import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/reduce_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/habit_model.dart';
import '../providers/habit_provider.dart';

/// Vue du calendrier de la fiche : la semaine en cours ou le mois.
enum HabitCalendarView { week, month }

/// Fiche récapitulative d'une habitude : statistiques, série, calendrier
/// interactif (semaine ou mois), validation du jour et modification.
///
/// Suit l'habitude en direct : cocher un jour met tout à jour sans fermer.
class HabitDetailSheet extends ConsumerStatefulWidget {
  const HabitDetailSheet(
      {super.key, required this.habitId, required this.onEdit});

  final String habitId;

  /// Ouvre l'éditeur (la fiche se ferme d'abord).
  final VoidCallback onEdit;

  static Future<void> show(
    BuildContext context, {
    required String habitId,
    required VoidCallback onEdit,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        sheetAnimationStyle: Motion.style(context),
        builder: (_) => HabitDetailSheet(habitId: habitId, onEdit: onEdit),
      );

  @override
  ConsumerState<HabitDetailSheet> createState() => _HabitDetailSheetState();
}

class _HabitDetailSheetState extends ConsumerState<HabitDetailSheet> {
  HabitCalendarView _view = HabitCalendarView.month;

  /// Premier jour de la période affichée (lundi, ou 1er du mois).
  late DateTime _anchor = _startOf(DateTime.now(), _view);

  static DateTime _startOf(DateTime day, HabitCalendarView view) {
    final d = DateTime(day.year, day.month, day.day);
    return switch (view) {
      HabitCalendarView.week => d.subtract(Duration(days: d.weekday - 1)),
      HabitCalendarView.month => DateTime(d.year, d.month),
    };
  }

  void _setView(HabitCalendarView view) => setState(() {
        _view = view;
        _anchor = _startOf(DateTime.now(), view);
      });

  void _shift(int delta) => setState(() {
        _anchor = switch (_view) {
          HabitCalendarView.week =>
            DateTime(_anchor.year, _anchor.month, _anchor.day + 7 * delta),
          HabitCalendarView.month =>
            DateTime(_anchor.year, _anchor.month + delta),
        };
      });

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitProvider).valueOrNull ?? const <Habit>[];
    final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
    if (habit == null) return const SizedBox.shrink();

    final cq = context.cq;
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(habitProvider.notifier);
    final doneToday = habit.completedToday;
    final unit = habit.frequency.shortUnit;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(habit.name, style: text.headlineSmall),
            const SizedBox(height: Space.xs),
            Text(habit.frequency.label,
                style: TextStyle(fontSize: TypeScale.caption, color: cq.terre)),
            const SizedBox(height: Space.lg),

            // ── Statistiques ────────────────────────────────────────────
            LayoutBuilder(builder: (context, box) {
              final stats = [
                _Stat(label: 'Série actuelle', value: '${habit.streak} $unit'),
                _Stat(
                    label: 'Meilleure série',
                    value: '${habit.bestStreak} $unit'),
                _Stat(
                    label: 'Régularité',
                    value: '${(habit.consistency * 100).round()} %'),
                _Stat(
                    label: 'Validations', value: '${habit.totalCompletions}'),
              ];
              Widget row(List<Widget> tiles) => IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, tile) in tiles.indexed) ...[
                          if (i > 0) const SizedBox(width: Space.sm),
                          Expanded(child: tile),
                        ],
                      ],
                    ),
                  );
              // Quatre de front sur grand écran, deux par deux sinon : les
              // tuiles occupent toute la largeur.
              return box.maxWidth >= 560
                  ? row(stats)
                  : Column(children: [
                      row(stats.sublist(0, 2)),
                      const SizedBox(height: Space.sm),
                      row(stats.sublist(2)),
                    ]);
            }),
            const SizedBox(height: Space.xl),

            // ── Calendrier ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(_periodTitle(),
                      style: text.titleMedium
                          ?.copyWith(fontFeatures: TypeScale.tabular)),
                ),
                IconButton(
                  tooltip: _view == HabitCalendarView.week
                      ? 'Semaine précédente'
                      : 'Mois précédent',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shift(-1),
                ),
                IconButton(
                  tooltip: _view == HabitCalendarView.week
                      ? 'Semaine suivante'
                      : 'Mois suivant',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shift(1),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            SegmentedButton<HabitCalendarView>(
              segments: const [
                ButtonSegment(
                    value: HabitCalendarView.week, label: Text('Semaine')),
                ButtonSegment(
                    value: HabitCalendarView.month, label: Text('Mois')),
              ],
              selected: {_view},
              showSelectedIcon: false,
              onSelectionChanged: (v) => _setView(v.first),
            ),
            const SizedBox(height: Space.md),
            _Calendar(
              habit: habit,
              days: _days(),
              month: _view == HabitCalendarView.month ? _anchor.month : null,
              onToggle: (day) => notifier.toggleOn(habit, day),
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Touche un jour passé pour le cocher ou le décocher.',
              style:
                  TextStyle(fontSize: TypeScale.caption, color: cq.textMuted),
            ),
            const SizedBox(height: Space.xl),

            // ── Actions ─────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: () => notifier.toggleToday(habit),
              icon: Icon(doneToday ? Icons.undo : Icons.check),
              label: Text(doneToday
                  ? 'Annuler la validation (${habit.frequency.currentPeriodLabel})'
                  : 'Valider ${habit.frequency.currentPeriodLabel}'),
            ),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onEdit();
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier l’habitude'),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _days() => switch (_view) {
        HabitCalendarView.week => [
            for (var i = 0; i < 7; i++)
              DateTime(_anchor.year, _anchor.month, _anchor.day + i),
          ],
        // Grille du lundi précédant le 1er au dimanche suivant la fin.
        HabitCalendarView.month => () {
            final first = _anchor;
            final start = first.subtract(Duration(days: first.weekday - 1));
            final last = DateTime(first.year, first.month + 1, 0);
            final end = last.add(Duration(days: 7 - last.weekday));
            return [
              for (var d = start;
                  !d.isAfter(end);
                  d = DateTime(d.year, d.month, d.day + 1))
                d,
            ];
          }(),
      };

  static const List<String> _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  String _periodTitle() {
    switch (_view) {
      case HabitCalendarView.month:
        final name = _months[_anchor.month - 1];
        return '${name[0].toUpperCase()}${name.substring(1)} ${_anchor.year}';
      case HabitCalendarView.week:
        final end = _anchor.add(const Duration(days: 6));
        return 'Du ${_anchor.day} ${_months[_anchor.month - 1]} '
            'au ${end.day} ${_months[end.month - 1]}';
    }
  }
}

extension on HabitFrequency {
  /// « aujourd'hui », « cette semaine », « ce mois ».
  String get currentPeriodLabel => switch (this) {
        HabitFrequency.daily => 'aujourd’hui',
        HabitFrequency.weekly => 'cette semaine',
        HabitFrequency.monthly => 'ce mois',
      };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
      decoration: BoxDecoration(
        color: cq.parchemin,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: cq.beigeDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: TypeScale.caption, color: cq.terre)),
          Text(
            value,
            style: TextStyle(
              fontSize: TypeScale.bodyLarge,
              fontWeight: FontWeight.w700,
              color: cq.textPrimary,
              fontFeatures: TypeScale.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grille de jours (lignes de 7, du lundi au dimanche). Jour coché : plein
/// sauge ; période validée par un autre jour (semaine, mois) : teinte
/// légère ; jour à venir : inactif ; hors du mois affiché : estompé.
class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.habit,
    required this.days,
    required this.month,
    required this.onToggle,
  });

  final Habit habit;
  final List<DateTime> days;

  /// Mois affiché (vue mois), pour estomper les jours voisins.
  final int? month;
  final ValueChanged<DateTime> onToggle;

  static const List<String> _initials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const List<String> _names = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = [
      for (var i = 0; i < days.length; i += 7) days.sublist(i, i + 7),
    ];

    Widget cell(DateTime day) {
      final logged = habit.isCompletedOn(day);
      final periodDone = habit.isDoneInPeriodOf(day);
      final future = day.isAfter(today);
      final outside = month != null && day.month != month;
      final isToday = day == today;
      final background = logged
          ? cq.vertSauge
          : periodDone
              ? cq.vertSauge.withValues(alpha: 0.16)
              : cq.cardColor;
      final foreground = logged
          ? cq.beige
          : future || outside
              ? cq.textHint
              : cq.textPrimary;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(Space.xs / 2),
          child: Semantics(
            button: !future,
            selected: logged,
            label: '${_names[day.weekday - 1]} ${day.day}'
                '${logged ? ', validé' : ''}',
            excludeSemantics: true,
            child: Material(
              color: background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.sm),
                side: BorderSide(
                  color: isToday ? cq.vertSauge : cq.beigeDark,
                  width: isToday ? Borders.focus : Borders.thin,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.sm),
                onTap: future ? null : () => onToggle(day),
                child: SizedBox(
                  height: Sizes.touchTarget,
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: TypeScale.body,
                        fontWeight: logged || isToday
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: foreground,
                        fontFeatures: TypeScale.tabular,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (final initial in _initials)
              Expanded(
                child: Center(
                  child: Text(initial,
                      style: TextStyle(
                          fontSize: TypeScale.caption,
                          color: cq.textMuted,
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.xs),
        for (final row in rows) Row(children: [for (final d in row) cell(d)]),
      ],
    );
  }
}
