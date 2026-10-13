import 'package:flutter/foundation.dart';

import '../../../core/theme/app_theme.dart';

/// Ambiances sonores — « Playlist de bruits ambiants (pluie, café, vent,
/// silence, 440 Hz, bruit rose) » (CdC).
///
/// Celles marquées [isSynthesised] sont générées à la volée : elles ne
/// dépendent d'aucun fichier audio et fonctionnent immédiatement. Les autres
/// attendent un enregistrement dans `assets/sounds/` — impossible à
/// synthétiser de façon convaincante.
enum AmbientSound {
  none('none', 'Silence', null, true),
  pinkNoise('pink_noise', 'Bruit rose', null, true),
  whiteNoise('white_noise', 'Bruit blanc', null, true),
  brownNoise('brown_noise', 'Bruit brun', null, true),
  tone440('tone_440', '440 Hz', null, true),
  rain('rain', 'Pluie', 'sounds/rain.mp3', false),
  cafe('cafe', 'Café', 'sounds/cafe.mp3', false),
  wind('wind', 'Vent', 'sounds/wind.mp3', false);

  const AmbientSound(this.value, this.label, this.assetPath, this.isSynthesised);

  final String value;
  final String label;

  /// Chemin de l'asset, pour les ambiances non synthétisables.
  final String? assetPath;

  final bool isSynthesised;

  bool get isSilent => this == AmbientSound.none;

  static AmbientSound fromValue(String? value) {
    for (final sound in values) {
      if (sound.value == value) return sound;
    }
    return AmbientSound.none;
  }

  static List<AmbientSound> get available =>
      values.where((s) => s.isSynthesised).toList();

  static List<AmbientSound> get needingAssets =>
      values.where((s) => !s.isSynthesised).toList();
}

/// Taille de texte — « taille et typographie du texte modulables » (CdC).
enum TextScalePreset {
  compact('compact', 'Compact', 0.9),
  standard('standard', 'Standard', 1.0),
  large('large', 'Grand', 1.15),
  xlarge('xlarge', 'Très grand', 1.3);

  const TextScalePreset(this.value, this.label, this.scale);

  final String value;
  final String label;
  final double scale;

  static TextScalePreset fromValue(String? value) {
    for (final preset in values) {
      if (preset.value == value) return preset;
    }
    return TextScalePreset.standard;
  }
}

/// Une routine quotidienne — « Instaurer des routines : Matin et Soir » (CdC).
class Routine {
  const Routine({
    required this.isEnabled,
    required this.hour,
    required this.minute,
    required this.steps,
  });

  final bool isEnabled;
  final int hour;
  final int minute;

  /// Les gestes de la routine, dans l'ordre.
  final List<String> steps;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Routine copyWith({
    bool? isEnabled,
    int? hour,
    int? minute,
    List<String>? steps,
  }) =>
      Routine(
        isEnabled: isEnabled ?? this.isEnabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        steps: steps ?? this.steps,
      );

  Map<String, dynamic> toJson() => {
        'enabled': isEnabled,
        'hour': hour,
        'minute': minute,
        'steps': steps,
      };

  factory Routine.fromJson(Map<String, dynamic> json, Routine fallback) {
    final rawSteps = json['steps'];
    return Routine(
      // `is` plutôt qu'un transtypage : une valeur du mauvais type ferait
      // échouer tout le chargement des préférences, alors qu'on veut
      // simplement retomber sur le modèle.
      isEnabled: json['enabled'] is bool
          ? json['enabled'] as bool
          : fallback.isEnabled,
      hour: _readInt(json['hour'], fallback.hour, 0, 23),
      minute: _readInt(json['minute'], fallback.minute, 0, 59),
      steps: rawSteps is List
          ? rawSteps.whereType<String>().toList()
          : fallback.steps,
    );
  }

  static int _readInt(Object? raw, int fallback, int min, int max) {
    if (raw is num) return raw.toInt().clamp(min, max);
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed.clamp(min, max);
    }
    return fallback;
  }

  /// Routine du matin par défaut : orienter la journée avant de la subir.
  static const Routine morningDefault = Routine(
    isEnabled: false,
    hour: 8,
    minute: 0,
    steps: [
      'Relire mes trois priorités du jour',
      'Choisir mon non-négociable',
      'Lancer une première session de focus',
    ],
  );

  /// Routine du soir : fermer la journée, pas l'abandonner.
  static const Routine eveningDefault = Routine(
    isEnabled: false,
    hour: 21,
    minute: 0,
    steps: [
      'Faire le bilan de ma session',
      'Noter humeur et effort ressenti',
      'Préparer la première tâche de demain',
    ],
  );
}

/// Réglages du Pomodoro : durées et nombre de sessions avant la pause
/// longue, librement choisis (bornés pour rester raisonnables).
@immutable
class PomodoroSettings {
  const PomodoroSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
  });

  static const PomodoroSettings defaults = PomodoroSettings();

  static const (int, int) workRange = (5, 120);
  static const (int, int) shortBreakRange = (1, 30);
  static const (int, int) longBreakRange = (5, 60);
  static const (int, int) sessionsRange = (1, 12);

  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  /// Sessions de travail avant la pause longue (n'est plus figé à 4).
  final int sessionsBeforeLongBreak;

  PomodoroSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
  }) =>
      PomodoroSettings(
        workMinutes: _clamp(workMinutes ?? this.workMinutes, workRange),
        shortBreakMinutes:
            _clamp(shortBreakMinutes ?? this.shortBreakMinutes, shortBreakRange),
        longBreakMinutes:
            _clamp(longBreakMinutes ?? this.longBreakMinutes, longBreakRange),
        sessionsBeforeLongBreak: _clamp(
            sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
            sessionsRange),
      );

  Map<String, dynamic> toJson() => {
        'work_minutes': workMinutes,
        'short_break_minutes': shortBreakMinutes,
        'long_break_minutes': longBreakMinutes,
        'sessions_before_long_break': sessionsBeforeLongBreak,
      };

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    int read(String key, int fallback, (int, int) range) {
      final value = json[key];
      return value is num ? _clamp(value.round(), range) : fallback;
    }

    return PomodoroSettings(
      workMinutes: read('work_minutes', 25, workRange),
      shortBreakMinutes: read('short_break_minutes', 5, shortBreakRange),
      longBreakMinutes: read('long_break_minutes', 15, longBreakRange),
      sessionsBeforeLongBreak:
          read('sessions_before_long_break', 4, sessionsRange),
    );
  }

  static int _clamp(int value, (int, int) range) =>
      value.clamp(range.$1, range.$2);

  @override
  bool operator ==(Object other) =>
      other is PomodoroSettings &&
      other.workMinutes == workMinutes &&
      other.shortBreakMinutes == shortBreakMinutes &&
      other.longBreakMinutes == longBreakMinutes &&
      other.sessionsBeforeLongBreak == sessionsBeforeLongBreak;

  @override
  int get hashCode => Object.hash(workMinutes, shortBreakMinutes,
      longBreakMinutes, sessionsBeforeLongBreak);
}

/// Préférences d'ambiance et d'accessibilité.
class UserSettings {
  const UserSettings({
    this.themeVariant = AppThemeVariant.light,
    this.textScale = TextScalePreset.standard,
    this.ambientSound = AmbientSound.none,
    this.ambientVolume = 0.5,
    this.keyboardShortcutsEnabled = true,
    this.reduceMotion = false,
    this.morningRoutine = Routine.morningDefault,
    this.eveningRoutine = Routine.eveningDefault,
    this.manualNoteOrder = false,
    this.pomodoro = PomodoroSettings.defaults,
  });

  static const UserSettings defaults = UserSettings();

  final AppThemeVariant themeVariant;
  final TextScalePreset textScale;
  final AmbientSound ambientSound;

  /// Volume de 0 à 1.
  final double ambientVolume;

  final bool keyboardShortcutsEnabled;

  /// Réduit les animations — confort visuel et accessibilité vestibulaire.
  final bool reduceMotion;

  final Routine morningRoutine;
  final Routine eveningRoutine;

  /// Liste des fiches en tri « Manuel » (glisser-déposer) plutôt que
  /// « Récentes ». Mémorisé et synchronisé avec les autres préférences.
  final bool manualNoteOrder;

  final PomodoroSettings pomodoro;

  UserSettings copyWith({
    AppThemeVariant? themeVariant,
    TextScalePreset? textScale,
    AmbientSound? ambientSound,
    double? ambientVolume,
    bool? keyboardShortcutsEnabled,
    bool? reduceMotion,
    Routine? morningRoutine,
    Routine? eveningRoutine,
    bool? manualNoteOrder,
    PomodoroSettings? pomodoro,
  }) =>
      UserSettings(
        themeVariant: themeVariant ?? this.themeVariant,
        textScale: textScale ?? this.textScale,
        ambientSound: ambientSound ?? this.ambientSound,
        ambientVolume: ambientVolume ?? this.ambientVolume,
        keyboardShortcutsEnabled:
            keyboardShortcutsEnabled ?? this.keyboardShortcutsEnabled,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        morningRoutine: morningRoutine ?? this.morningRoutine,
        eveningRoutine: eveningRoutine ?? this.eveningRoutine,
        manualNoteOrder: manualNoteOrder ?? this.manualNoteOrder,
        pomodoro: pomodoro ?? this.pomodoro,
      );

  Map<String, dynamic> toJson() => {
        'theme': themeVariant.value,
        'text_scale': textScale.value,
        'ambient_sound': ambientSound.value,
        'ambient_volume': ambientVolume,
        'keyboard_shortcuts': keyboardShortcutsEnabled,
        'reduce_motion': reduceMotion,
        'morning_routine': morningRoutine.toJson(),
        'evening_routine': eveningRoutine.toJson(),
        'notes_manual_order': manualNoteOrder,
        'pomodoro': pomodoro.toJson(),
      };

  /// Tolérant par construction : une préférence inconnue ou absente retombe
  /// sur sa valeur par défaut plutôt que de faire échouer tout le chargement.
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    Routine routine(String key, Routine fallback) {
      final raw = json[key];
      return raw is Map
          ? Routine.fromJson(Map<String, dynamic>.from(raw), fallback)
          : fallback;
    }

    return UserSettings(
      themeVariant: AppThemeVariant.fromValue(json['theme'] as String?),
      textScale: TextScalePreset.fromValue(json['text_scale'] as String?),
      ambientSound: AmbientSound.fromValue(json['ambient_sound'] as String?),
      ambientVolume: json['ambient_volume'] is num
          ? (json['ambient_volume'] as num).toDouble().clamp(0.0, 1.0)
          : 0.5,
      keyboardShortcutsEnabled: json['keyboard_shortcuts'] is bool
          ? json['keyboard_shortcuts'] as bool
          : true,
      reduceMotion:
          json['reduce_motion'] is bool ? json['reduce_motion'] as bool : false,
      morningRoutine: routine('morning_routine', Routine.morningDefault),
      eveningRoutine: routine('evening_routine', Routine.eveningDefault),
      manualNoteOrder: json['notes_manual_order'] is bool
          ? json['notes_manual_order'] as bool
          : false,
      pomodoro: json['pomodoro'] is Map
          ? PomodoroSettings.fromJson(
              Map<String, dynamic>.from(json['pomodoro'] as Map))
          : PomodoroSettings.defaults,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.themeVariant == themeVariant &&
      other.textScale == textScale &&
      other.ambientSound == ambientSound &&
      other.ambientVolume == ambientVolume &&
      other.keyboardShortcutsEnabled == keyboardShortcutsEnabled &&
      other.reduceMotion == reduceMotion &&
      other.manualNoteOrder == manualNoteOrder &&
      other.pomodoro == pomodoro;

  @override
  int get hashCode => Object.hash(
        themeVariant,
        textScale,
        ambientSound,
        ambientVolume,
        keyboardShortcutsEnabled,
        reduceMotion,
        manualNoteOrder,
        pomodoro,
      );
}
