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

/// Préférences d'ambiance et d'accessibilité.
class UserSettings {
  const UserSettings({
    this.themeVariant = AppThemeVariant.beige,
    this.textScale = TextScalePreset.standard,
    this.ambientSound = AmbientSound.none,
    this.ambientVolume = 0.5,
    this.keyboardShortcutsEnabled = true,
    this.reduceMotion = false,
    this.morningRoutine = Routine.morningDefault,
    this.eveningRoutine = Routine.eveningDefault,
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

  UserSettings copyWith({
    AppThemeVariant? themeVariant,
    TextScalePreset? textScale,
    AmbientSound? ambientSound,
    double? ambientVolume,
    bool? keyboardShortcutsEnabled,
    bool? reduceMotion,
    Routine? morningRoutine,
    Routine? eveningRoutine,
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
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(
        themeVariant,
        textScale,
        ambientSound,
        ambientVolume,
        keyboardShortcutsEnabled,
        reduceMotion,
      );
}
