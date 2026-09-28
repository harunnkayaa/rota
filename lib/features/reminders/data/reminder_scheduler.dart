import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A notification ready for the platform: text and the exact moment.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.atUtc,
  });

  final int id;
  final String title;
  final String body;
  final DateTime atUtc;
}

/// Talks to the operating system. Two implementations: iOS local
/// notifications, and a no-op for web and tests.
abstract interface class ReminderScheduler {
  /// Whether this platform can deliver scheduled reminders at all.
  bool get isSupported;

  /// Asks the OS for permission; true when granted.
  Future<bool> requestPermission();

  /// Replaces every pending Rota reminder with [notifications].
  Future<void> replaceAll(List<ScheduledNotification> notifications);
}

class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  bool get isSupported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {}
}

/// iOS local notifications via `flutter_local_notifications`.
///
/// Times are handed over as UTC instants: the local wall-clock time is
/// converted with the device's own rules (DST included) before it gets
/// here, so no timezone database lookup by name is needed.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _details = NotificationDetails(iOS: DarwinNotificationDetails());

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        // Permission is asked later, in context, never at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  bool get isSupported => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    for (final n in notifications) {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.from(n.atUtc, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
