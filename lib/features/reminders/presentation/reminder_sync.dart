import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../planning/presentation/planner_controller.dart';
import '../data/reminder_scheduler.dart';
import '../domain/reminder_planner.dart';

/// Keeps the scheduled notifications in step with the planner.
///
/// Every change (progress logged, plan edited, settings changed) recomputes
/// the reminders from scratch and replaces the pending ones, so a reminder
/// always quotes the time still left — never minutes already worked.
class ReminderSync {
  ReminderSync({
    required this.controller,
    required this.scheduler,
    required this.texts,
    this.debounce = const Duration(milliseconds: 300),
  });

  final PlannerController controller;
  final ReminderScheduler scheduler;
  final AppLocalizations texts;
  final Duration debounce;

  Timer? _pending;
  String? _lastSignature;

  void start() {
    controller.addListener(_scheduleSoon);
    _scheduleSoon();
  }

  void dispose() {
    controller.removeListener(_scheduleSoon);
    _pending?.cancel();
  }

  void _scheduleSoon() {
    _pending?.cancel();
    _pending = Timer(debounce, () => unawaited(sync()));
  }

  /// Recomputes and, if anything changed, replaces pending notifications.
  Future<void> sync() async {
    if (!scheduler.isSupported || controller.loadStatus != LoadStatus.ready) {
      return;
    }
    final planned = planReminders(
      settings: controller.settings.reminders,
      candidates: controller.reminderCandidates(),
      today: controller.today,
      nowMinuteOfDay: controller.clock.minuteOfDay(),
    );
    final notifications = [for (final r in planned) _toNotification(r)];
    final signature = notifications
        .map((n) => '${n.id}|${n.atUtc}|${n.body}')
        .join(',');
    if (signature == _lastSignature) return;
    try {
      await scheduler.replaceAll(notifications);
      _lastSignature = signature;
    } on Object catch (e) {
      // Not fatal: the next change retries. Type only; bodies hold titles.
      debugPrint('Reminder scheduling failed: ${e.runtimeType}');
    }
  }

  ScheduledNotification _toNotification(PlannedReminder r) {
    final c = r.candidate;
    final amount = texts.minutes(c.minutes);
    final body = r.hideDetails
        ? texts.reminderHiddenBody
        : switch (c.kind) {
            ReminderKind.todayRemaining => texts.reminderTodayBody(
              c.goalTitle,
              amount,
            ),
            ReminderKind.paceBehind => texts.reminderPaceBody(
              c.goalTitle,
              amount,
            ),
          };
    final localTime = DateTime(
      r.date.year,
      r.date.month,
      r.date.day,
      r.minuteOfDay ~/ Duration.minutesPerHour,
      r.minuteOfDay % Duration.minutesPerHour,
    );
    return ScheduledNotification(
      id: r.id,
      title: texts.reminderTitle,
      body: body,
      atUtc: localTime.toUtc(),
    );
  }
}

/// Gives screens (Settings) access to the scheduler for permission prompts.
class ReminderScope extends InheritedWidget {
  const ReminderScope({
    required this.scheduler,
    required super.child,
    super.key,
  });

  final ReminderScheduler scheduler;

  static ReminderScheduler of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReminderScope>()?.scheduler ??
      const NoopReminderScheduler();

  @override
  bool updateShouldNotify(ReminderScope oldWidget) =>
      scheduler != oldWidget.scheduler;
}
