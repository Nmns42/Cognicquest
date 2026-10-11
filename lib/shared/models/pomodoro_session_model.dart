/// Session Pomodoro terminée, archivée pour les statistiques.
///
/// Répond à l'exigence CdC « Intégrer un système de suivi des progrès (sessions
/// terminées, temps total d'étude) » : sans cet enregistrement, le compteur
/// repartait de zéro à chaque lancement de l'app.
class PomodoroSession {
  const PomodoroSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    required this.durationSeconds,
    this.taskId,
  });

  final String id;
  final String userId;
  final DateTime startedAt;
  final int durationSeconds;

  /// Tâche associée, si la session a été lancée depuis une carte du Kanban.
  /// Prépare le lien « session d'étude ↔ tâche » demandé par le CdC.
  final String? taskId;

  Duration get duration => Duration(seconds: durationSeconds);

  factory PomodoroSession.fromJson(Map<String, dynamic> json) =>
      PomodoroSession(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
        durationSeconds: (json['duration_seconds'] as num).toInt(),
        taskId: json['task_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'started_at': startedAt.toUtc().toIso8601String(),
        'duration_seconds': durationSeconds,
        'task_id': taskId,
      };
}

/// Agrégats affichés par le Pomodoro et le Dashboard.
class PomodoroStats {
  const PomodoroStats({
    required this.sessionsToday,
    required this.sessionsThisWeek,
    required this.sessionsAllTime,
    required this.focusToday,
    required this.focusThisWeek,
    required this.focusAllTime,
  });

  const PomodoroStats.empty()
      : sessionsToday = 0,
        sessionsThisWeek = 0,
        sessionsAllTime = 0,
        focusToday = Duration.zero,
        focusThisWeek = Duration.zero,
        focusAllTime = Duration.zero;

  final int sessionsToday;
  final int sessionsThisWeek;
  final int sessionsAllTime;
  final Duration focusToday;
  final Duration focusThisWeek;
  final Duration focusAllTime;

  /// Récompenses du CdC (« gagne des pièces »). Les pièces sont *dérivées* des
  /// sessions archivées plutôt que stockées dans un compteur en mémoire :
  /// elles survivent donc au redémarrage de l'application.
  int coins(int coinsPerSession) => sessionsAllTime * coinsPerSession;

  factory PomodoroStats.fromSessions(List<PomodoroSession> sessions) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Semaine ISO : démarre le lundi.
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    var sessionsToday = 0;
    var sessionsThisWeek = 0;
    var focusToday = 0;
    var focusThisWeek = 0;
    var focusAllTime = 0;

    for (final session in sessions) {
      focusAllTime += session.durationSeconds;

      if (!session.startedAt.isBefore(startOfWeek)) {
        sessionsThisWeek++;
        focusThisWeek += session.durationSeconds;
      }
      if (!session.startedAt.isBefore(startOfToday)) {
        sessionsToday++;
        focusToday += session.durationSeconds;
      }
    }

    return PomodoroStats(
      sessionsToday: sessionsToday,
      sessionsThisWeek: sessionsThisWeek,
      sessionsAllTime: sessions.length,
      focusToday: Duration(seconds: focusToday),
      focusThisWeek: Duration(seconds: focusThisWeek),
      focusAllTime: Duration(seconds: focusAllTime),
    );
  }
}

/// Formate une durée pour l'affichage des statistiques : « 25 min », « 2 h »,
/// « 1 h 25 ».
String formatFocusDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return minutes == 0 ? '$hours h' : '$hours h $minutes';
}
