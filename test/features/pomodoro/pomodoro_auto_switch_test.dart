import 'package:cognicquest/features/pomodoro/data/pomodoro_repository.dart';
import 'package:cognicquest/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:cognicquest/features/settings/data/preferences_repository.dart';
import 'package:cognicquest/features/settings/domain/user_settings.dart';
import 'package:cognicquest/features/settings/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sonnerie factice : retient ce qui a été joué.
class _RecordingChime extends PomodoroChime {
  final played = <PomodoroRingtone>[];

  @override
  Future<void> play(PomodoroRingtone ringtone) async => played.add(ringtone);
}

/// Enchaînement automatique travail ↔ pauses, sonnerie à chaque fin de
/// phase, arrêt après la pause longue qui clôt le cycle.
void main() {
  late ProviderContainer container;
  late _RecordingChime chime;

  setUp(() {
    chime = _RecordingChime();
    container = ProviderContainer(overrides: [
      pomodoroChimeProvider.overrideWithValue(chime),
      pomodoroRepositoryProvider.overrideWithValue(null),
      preferencesRepositoryProvider.overrideWithValue(null),
    ]);
  });
  tearDown(() => container.dispose());

  PomodoroState read() => container.read(pomodoroProvider);
  PomodoroNotifier pomodoro() => container.read(pomodoroProvider.notifier);

  test('par défaut : pause longue de 10 min, sonnerie Cloche', () {
    expect(PomodoroSettings.defaults.longBreakMinutes, 10);
    expect(PomodoroSettings.defaults.ringtone, PomodoroRingtone.bell);
    expect(PomodoroSettings.fromJson(const {}).longBreakMinutes, 10);
  });

  test('la sonnerie choisie est enregistrée et relue', () {
    final config =
        PomodoroSettings.defaults.copyWith(ringtone: PomodoroRingtone.gong);
    expect(PomodoroSettings.fromJson(config.toJson()), config);
    expect(PomodoroSettings.fromJson(const {'ringtone': 'inconnue'}).ringtone,
        PomodoroRingtone.bell);
  });

  test('chaque sonnerie pointe vers un fichier de assets/sounds/', () {
    for (final ringtone in PomodoroRingtone.values) {
      expect(ringtone.assetPath, startsWith('sounds/'));
    }
  });

  test(
      'cycle de 2 sessions : travail → pause → travail → pause longue → fin, '
      'avec relance et sonnerie à chaque étape', () async {
    container.read(settingsProvider.notifier).setPomodoro(
          PomodoroSettings.defaults.copyWith(
            sessionsBeforeLongBreak: 2,
            ringtone: PomodoroRingtone.twinBell,
          ),
        );
    pomodoro().start();

    await pomodoro().finishPhase();
    expect(read().phase, PomodoroPhase.shortBreak);
    expect(read().status, PomodoroStatus.running);
    expect(read().totalSeconds, 5 * 60);

    await pomodoro().finishPhase();
    expect(read().phase, PomodoroPhase.work);
    expect(read().status, PomodoroStatus.running);

    await pomodoro().finishPhase();
    expect(read().phase, PomodoroPhase.longBreak);
    expect(read().status, PomodoroStatus.running);
    expect(read().totalSeconds, 10 * 60);

    // La pause longue clôt le cycle : le minuteur attend un nouveau départ.
    await pomodoro().finishPhase();
    expect(read().phase, PomodoroPhase.work);
    expect(read().status, PomodoroStatus.idle);
    expect(read().completedSessions, 2);

    expect(chime.played, List.filled(4, PomodoroRingtone.twinBell));
    pomodoro().reset();
  });

  test('« Passer » ne sonne pas et ne relance pas', () {
    pomodoro().skip();
    expect(read().phase, PomodoroPhase.shortBreak);
    expect(read().status, PomodoroStatus.idle);
    expect(chime.played, isEmpty);
  });
}
