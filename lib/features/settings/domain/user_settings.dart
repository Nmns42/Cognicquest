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

/// Sonnerie de fin de phase du Pomodoro, parmi les sons de `assets/sounds/`.
enum PomodoroRingtone {
  bell('bells', 'Cloche', 'sounds/bells.mp3'),
  twinBell('twin_bell', 'Double cloche', 'sounds/twin-bell.mp3'),
  gong('samurai', 'Gong', 'sounds/samurai.mp3'),
  ticToc('tic_toc', 'Tic-tac', 'sounds/tic-toc.mp3');

  const PomodoroRingtone(this.value, this.label, this.assetPath);

  /// Valeur enregistrée dans les préférences.
  final String value;
  final String label;

  /// Chemin relatif à `assets/`, comme l'attend `AssetSource`.
  final String assetPath;

  static PomodoroRingtone fromValue(Object? value) {
    for (final ringtone in values) {
      if (ringtone.value == value) return ringtone;
    }
    return PomodoroRingtone.bell;
  }
}

/// Réglages du Pomodoro : durées, nombre de sessions du cycle (la dernière
/// est suivie de la pause longue) et sonnerie, librement choisis (bornés
/// pour rester raisonnables).
@immutable
class PomodoroSettings {
  const PomodoroSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 10,
    this.sessionsBeforeLongBreak = 4,
    this.ringtone = PomodoroRingtone.bell,
  });

  static const PomodoroSettings defaults = PomodoroSettings();

  static const (int, int) workRange = (5, 120);
  static const (int, int) shortBreakRange = (1, 30);
  static const (int, int) longBreakRange = (5, 60);
  static const (int, int) sessionsRange = (1, 12);

  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  /// Nombre de sessions de travail du cycle : le minuteur enchaîne seul
  /// travail et pauses jusqu'à la dernière, suivie de la pause longue.
  final int sessionsBeforeLongBreak;

  /// Son joué à la fin de chaque session de travail et de chaque pause.
  final PomodoroRingtone ringtone;

  PomodoroSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    PomodoroRingtone? ringtone,
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
        ringtone: ringtone ?? this.ringtone,
      );

  Map<String, dynamic> toJson() => {
        'work_minutes': workMinutes,
        'short_break_minutes': shortBreakMinutes,
        'long_break_minutes': longBreakMinutes,
        'sessions_before_long_break': sessionsBeforeLongBreak,
        'ringtone': ringtone.value,
      };

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    int read(String key, int fallback, (int, int) range) {
      final value = json[key];
      return value is num ? _clamp(value.round(), range) : fallback;
    }

    return PomodoroSettings(
      workMinutes: read('work_minutes', 25, workRange),
      shortBreakMinutes: read('short_break_minutes', 5, shortBreakRange),
      longBreakMinutes: read('long_break_minutes', 10, longBreakRange),
      sessionsBeforeLongBreak:
          read('sessions_before_long_break', 4, sessionsRange),
      ringtone: PomodoroRingtone.fromValue(json['ringtone']),
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
      other.sessionsBeforeLongBreak == sessionsBeforeLongBreak &&
      other.ringtone == ringtone;

  @override
  int get hashCode => Object.hash(workMinutes, shortBreakMinutes,
      longBreakMinutes, sessionsBeforeLongBreak, ringtone);
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
    this.manualNoteOrder = false,
    this.pomodoro = PomodoroSettings.defaults,
    this.dismissedBanners = const {},
    this.dailyReminder = false,
    this.dailyReminderMinutes = defaultReminderMinutes,
    this.pomodoroNotifications = true,
  });

  static const UserSettings defaults = UserSettings();

  /// 18 h 00, en minutes depuis minuit.
  static const int defaultReminderMinutes = 18 * 60;

  final AppThemeVariant themeVariant;
  final TextScalePreset textScale;
  final AmbientSound ambientSound;

  /// Volume de 0 à 1.
  final double ambientVolume;

  final bool keyboardShortcutsEnabled;

  /// Réduit les animations — confort visuel et accessibilité vestibulaire.
  final bool reduceMotion;

  /// Liste des fiches en tri « Manuel » (glisser-déposer) plutôt que
  /// « Récentes ». Mémorisé et synchronisé avec les autres préférences.
  final bool manualNoteOrder;

  final PomodoroSettings pomodoro;

  /// Identifiants des encadrés d'aide que l'utilisateur a fermés : ils ne
  /// réapparaissent pas, sur cet appareil comme sur les autres.
  final Set<String> dismissedBanners;

  /// Rappel quotidien de révision (notification locale).
  final bool dailyReminder;

  /// Heure du rappel, en minutes depuis minuit (0 à 1439).
  final int dailyReminderMinutes;

  /// Notification à la fin de chaque phase du Pomodoro.
  final bool pomodoroNotifications;

  UserSettings copyWith({
    AppThemeVariant? themeVariant,
    TextScalePreset? textScale,
    AmbientSound? ambientSound,
    double? ambientVolume,
    bool? keyboardShortcutsEnabled,
    bool? reduceMotion,
    bool? manualNoteOrder,
    PomodoroSettings? pomodoro,
    Set<String>? dismissedBanners,
    bool? dailyReminder,
    int? dailyReminderMinutes,
    bool? pomodoroNotifications,
  }) =>
      UserSettings(
        themeVariant: themeVariant ?? this.themeVariant,
        textScale: textScale ?? this.textScale,
        ambientSound: ambientSound ?? this.ambientSound,
        ambientVolume: ambientVolume ?? this.ambientVolume,
        keyboardShortcutsEnabled:
            keyboardShortcutsEnabled ?? this.keyboardShortcutsEnabled,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        manualNoteOrder: manualNoteOrder ?? this.manualNoteOrder,
        pomodoro: pomodoro ?? this.pomodoro,
        dismissedBanners: dismissedBanners ?? this.dismissedBanners,
        dailyReminder: dailyReminder ?? this.dailyReminder,
        dailyReminderMinutes: dailyReminderMinutes ?? this.dailyReminderMinutes,
        pomodoroNotifications:
            pomodoroNotifications ?? this.pomodoroNotifications,
      );

  Map<String, dynamic> toJson() => {
        'theme': themeVariant.value,
        'text_scale': textScale.value,
        'ambient_sound': ambientSound.value,
        'ambient_volume': ambientVolume,
        'keyboard_shortcuts': keyboardShortcutsEnabled,
        'reduce_motion': reduceMotion,
        'notes_manual_order': manualNoteOrder,
        'pomodoro': pomodoro.toJson(),
        // Trié : deux appareils écrivent le même JSON pour le même ensemble.
        'dismissed_banners': dismissedBanners.toList()..sort(),
        'daily_reminder': dailyReminder,
        'daily_reminder_minutes': dailyReminderMinutes,
        'pomodoro_notifications': pomodoroNotifications,
      };

  /// Tolérant par construction : une préférence inconnue ou absente retombe
  /// sur sa valeur par défaut plutôt que de faire échouer tout le chargement.
  /// Les anciennes clés des routines (`morning_routine`, `evening_routine`),
  /// fonctionnalité retirée, sont ignorées.
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final banners = json['dismissed_banners'];

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
      manualNoteOrder: json['notes_manual_order'] is bool
          ? json['notes_manual_order'] as bool
          : false,
      pomodoro: json['pomodoro'] is Map
          ? PomodoroSettings.fromJson(
              Map<String, dynamic>.from(json['pomodoro'] as Map))
          : PomodoroSettings.defaults,
      dismissedBanners: banners is List
          ? banners.whereType<String>().toSet()
          : const {},
      dailyReminder: json['daily_reminder'] == true,
      dailyReminderMinutes: json['daily_reminder_minutes'] is int
          ? (json['daily_reminder_minutes'] as int).clamp(0, 24 * 60 - 1)
          : defaultReminderMinutes,
      pomodoroNotifications: json['pomodoro_notifications'] is bool
          ? json['pomodoro_notifications'] as bool
          : true,
    );
  }

  // Égalité complète : chaque champ y figure. Un champ oublié ici rendait
  // égaux deux réglages différents, et le changement n'était pas notifié.
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
      other.pomodoro == pomodoro &&
      setEquals(other.dismissedBanners, dismissedBanners) &&
      other.dailyReminder == dailyReminder &&
      other.dailyReminderMinutes == dailyReminderMinutes &&
      other.pomodoroNotifications == pomodoroNotifications;

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
        Object.hashAllUnordered(dismissedBanners),
        dailyReminder,
        dailyReminderMinutes,
        pomodoroNotifications,
      );
}
