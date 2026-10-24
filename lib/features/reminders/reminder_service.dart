import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../settings/providers/settings_provider.dart';

/// Notifications locales : fin de phase Pomodoro et rappel quotidien de
/// révision.
///
/// - Android, iOS, Windows, Linux : notification système, rappel planifié
///   par le système (il arrive même app fermée).
/// - Web : API Notification ; le rappel quotidien n'est déclenché que si
///   l'app est ouverte (dans un onglet), faute de serveur de notifications
///   push.
///
/// Chaque appel est sans effet si la plateforme refuse (permission, plugin
/// absent en test) : un rappel manqué ne doit jamais casser l'app.
class ReminderService {
  ReminderService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<bool>? _ready;
  Timer? _webDaily;

  static const int _phaseId = 1;
  static const int _dailyId = 2;

  static const AndroidNotificationDetails _androidPhase =
      AndroidNotificationDetails(
    'pomodoro',
    'Pomodoro',
    channelDescription: 'Fin des sessions de concentration et des pauses',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
  );

  static const AndroidNotificationDetails _androidDaily =
      AndroidNotificationDetails(
    'daily_review',
    'Rappel de révision',
    channelDescription: 'Rappel quotidien de révision',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    category: AndroidNotificationCategory.reminder,
  );

  Future<bool> _init() => _ready ??= () async {
        try {
          if (!kIsWeb) {
            tz_data.initializeTimeZones();
            final zone = await FlutterTimezone.getLocalTimezone();
            tz.setLocalLocation(tz.getLocation(zone.identifier));
          }
          return await _plugin.initialize(
                settings: const InitializationSettings(
                  android: AndroidInitializationSettings('@mipmap/ic_launcher'),
                  iOS: DarwinInitializationSettings(
                    requestAlertPermission: false,
                    requestBadgePermission: false,
                    requestSoundPermission: false,
                  ),
                  macOS: DarwinInitializationSettings(
                    requestAlertPermission: false,
                    requestBadgePermission: false,
                    requestSoundPermission: false,
                  ),
                  linux: LinuxInitializationSettings(defaultActionName: 'Ouvrir'),
                  windows: WindowsInitializationSettings(
                    appName: 'CognicQuest',
                    appUserModelId: 'io.cognicquest.app',
                    guid: '6f6a3c52-8b1e-4c3e-9a57-1f0c7d2b9e41',
                  ),
                  web: WebInitializationSettings(),
                ),
              ) ??
              false;
        } catch (_) {
          return false;
        }
      }();

  /// Demande l'autorisation d'afficher des notifications. À appeler suite à
  /// un geste de l'utilisateur (activation d'un réglage) : le web refuse
  /// sinon.
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    try {
      if (kIsWeb) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    WebFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      }
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false,
        TargetPlatform.iOS => await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false,
        _ => true,
      };
    } catch (_) {
      return false;
    }
  }

  /// Fin de phase du Pomodoro.
  Future<void> notifyPhaseEnd({
    required String title,
    required String body,
  }) async {
    if (!await _init()) return;
    try {
      await _plugin.show(
        id: _phaseId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _androidPhase,
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
      );
    } catch (_) {}
  }

  /// Planifie (ou annule, si [enabled] est faux) le rappel quotidien à
  /// [minutes] après minuit, heure locale.
  Future<void> setDailyReview({
    required bool enabled,
    required int minutes,
  }) async {
    _webDaily?.cancel();
    _webDaily = null;
    if (!await _init()) return;
    try {
      await _plugin.cancel(id: _dailyId);
      if (!enabled) return;

      if (kIsWeb) {
        _scheduleWebDaily(minutes);
        return;
      }
      await _plugin.zonedSchedule(
        id: _dailyId,
        title: dailyTitle,
        body: dailyBody,
        scheduledDate: nextOccurrence(tz.TZDateTime.now(tz.local), minutes),
        notificationDetails: const NotificationDetails(
          android: _androidDaily,
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact : pas de permission « alarmes exactes » à demander, à
        // quelques minutes près le rappel reste utile.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static const String dailyTitle = 'C’est l’heure de ta révision';
  static const String dailyBody =
      'Quelques cartes aujourd’hui valent mieux qu’un marathon demain.';

  void _scheduleWebDaily(int minutes) {
    final now = DateTime.now();
    final next = nextOccurrence(now, minutes);
    _webDaily = Timer(next.difference(now), () async {
      try {
        await _plugin.show(id: _dailyId, title: dailyTitle, body: dailyBody);
      } catch (_) {}
      _scheduleWebDaily(minutes);
    });
  }

  /// Prochaine occurrence de [minutes] après minuit, strictement après
  /// [now] (aujourd'hui si l'heure n'est pas passée, sinon demain).
  static T nextOccurrence<T extends DateTime>(T now, int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    DateTime at(DateTime day) => now is tz.TZDateTime
        ? tz.TZDateTime(now.location, day.year, day.month, day.day, hour, minute)
        : DateTime(day.year, day.month, day.day, hour, minute);
    var candidate = at(now);
    if (!candidate.isAfter(now)) {
      candidate = at(DateTime(now.year, now.month, now.day + 1));
    }
    return candidate as T;
  }

  void dispose() => _webDaily?.cancel();
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = ReminderService();
  ref.onDispose(service.dispose);
  return service;
});

/// Garde le rappel quotidien aligné sur les réglages (y compris ceux
/// synchronisés depuis un autre appareil).
final dailyReminderSyncProvider = Provider<void>((ref) {
  final enabled = ref.watch(settingsProvider.select((s) => s.dailyReminder));
  final minutes =
      ref.watch(settingsProvider.select((s) => s.dailyReminderMinutes));
  unawaited(ref
      .read(reminderServiceProvider)
      .setDailyReview(enabled: enabled, minutes: minutes));
});

/// Libellé « 18 h 00 » d'une heure en minutes depuis minuit.
String reminderTimeLabel(int minutes) =>
    '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
