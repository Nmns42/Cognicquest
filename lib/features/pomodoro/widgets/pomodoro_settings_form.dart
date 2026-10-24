import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../settings/domain/user_settings.dart';

/// Nombre entier saisi librement : « 42 », « 1,2 » ou « 1.6 » (arrondi à
/// l'entier le plus proche). `null` si la saisie n'est pas un nombre.
int? parseWholeNumber(String raw) {
  final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || !value.isFinite) return null;
  return value.round();
}

/// Durées et nombre de sessions du Pomodoro en saisie libre, partagé par
/// les Réglages et l'écran Pomodoro.
class PomodoroDurationsForm extends StatelessWidget {
  const PomodoroDurationsForm({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final PomodoroSettings config;
  final ValueChanged<PomodoroSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final divider = Divider(
        height: Borders.thin, thickness: Borders.thin, color: cq.beigeDark);
    return Column(
      children: [
        WholeNumberField(
          label: 'Nombre de sessions',
          value: config.sessionsBeforeLongBreak,
          unit: config.sessionsBeforeLongBreak > 1 ? 'sessions' : 'session',
          range: PomodoroSettings.sessionsRange,
          onChanged: (v) =>
              onChanged(config.copyWith(sessionsBeforeLongBreak: v)),
        ),
        divider,
        WholeNumberField(
          label: 'Durée Focus',
          value: config.workMinutes,
          unit: 'min',
          range: PomodoroSettings.workRange,
          onChanged: (v) => onChanged(config.copyWith(workMinutes: v)),
        ),
        divider,
        WholeNumberField(
          label: 'Pause courte',
          value: config.shortBreakMinutes,
          unit: 'min',
          range: PomodoroSettings.shortBreakRange,
          onChanged: (v) => onChanged(config.copyWith(shortBreakMinutes: v)),
        ),
        divider,
        WholeNumberField(
          label: 'Pause longue',
          value: config.longBreakMinutes,
          unit: 'min',
          range: PomodoroSettings.longBreakRange,
          onChanged: (v) => onChanged(config.copyWith(longBreakMinutes: v)),
        ),
      ],
    );
  }
}

/// Ligne « libellé — champ numérique — unité ». La valeur est validée à la
/// sortie du champ ou à la touche Entrée : décimale arrondie, puis bornée à
/// [range] (la valeur retenue s'affiche aussitôt, avec la plage en aide).
class WholeNumberField extends StatefulWidget {
  const WholeNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.range,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final (int, int) range;
  final ValueChanged<int> onChanged;

  @override
  State<WholeNumberField> createState() => _WholeNumberFieldState();
}

class _WholeNumberFieldState extends State<WholeNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');
  final FocusNode _focus = FocusNode();
  String? _hint;

  /// Dernier texte validé : Entrée puis la perte du focus qui la suit ne
  /// valident qu'une fois (la seconde effaçait l'explication affichée).
  late String _committed = '${widget.value}';

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(WholeNumberField old) {
    super.didUpdateWidget(old);
    // Valeur changée ailleurs (autre écran, autre appareil) : affichée, sauf
    // pendant la saisie.
    if (old.value != widget.value && !_focus.hasFocus) {
      _controller.text = _committed = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    if (_controller.text == _committed) return;
    final (min, max) = widget.range;
    final parsed = parseWholeNumber(_controller.text);
    if (parsed == null) {
      _controller.text = '${widget.value}';
      setState(() => _hint = 'Saisis un nombre entre $min et $max.');
      return;
    }
    final value = parsed.clamp(min, max);
    _controller.text = _committed = '$value';
    setState(() => _hint = value != parsed
        ? 'Ramené à $value (de $min à $max ${widget.unit}).'
        : null);
    if (value != widget.value) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final cq = context.cq;
    final hint = _hint;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.label,
                    style: TextStyle(
                        fontSize: TypeScale.body, color: cq.textPrimary)),
              ),
              SizedBox(
                width: Space.xxxl + Space.xl,
                child: Semantics(
                  label: '${widget.label}, en ${widget.unit}',
                  textField: true,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) => _commit(),
                    style: TextStyle(
                      fontSize: TypeScale.body,
                      fontWeight: FontWeight.w700,
                      color: cq.textPrimary,
                      fontFeatures: TypeScale.tabular,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: cq.parchemin,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: Space.sm, vertical: Space.sm),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        borderSide: BorderSide(color: cq.beigeDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        borderSide: BorderSide(color: cq.beigeDark),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              SizedBox(
                width: Space.xxxl + Space.lg,
                child: Text(widget.unit,
                    style: TextStyle(
                        fontSize: TypeScale.caption, color: cq.textMuted)),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: Space.xs),
            Text(hint,
                style: TextStyle(fontSize: TypeScale.caption, color: cq.terre)),
          ],
        ],
      ),
    );
  }
}
