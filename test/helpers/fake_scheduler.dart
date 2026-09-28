import 'package:rota/features/reminders/data/reminder_scheduler.dart';

/// Records what would be scheduled; permission answer is configurable.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.grant = true});

  bool grant;
  int permissionRequests = 0;
  List<ScheduledNotification> pending = const [];
  int replaceCalls = 0;

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    replaceCalls++;
    pending = List.of(notifications);
  }
}
