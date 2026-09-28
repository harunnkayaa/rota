import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/duration_stepper.dart';
import '../../planning/presentation/planner_controller.dart';
import '../../reminders/domain/reminder_planner.dart';
import '../../reminders/presentation/reminder_sync.dart';
import '../../sync/presentation/account_section.dart';

/// Capacity and calendar preferences (CLAUDE.md §13.7). Every change is
/// saved immediately; there is no separate "save" step.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _weekdays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final settings = controller.settings;

    Widget card(String title, String? hint, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.m),
              ...children,
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l.settingsTitle)),
          SliverToBoxAdapter(
            child: ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  0,
                  AppSpacing.m,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    card(l.settingsAccount, l.accountHint, [
                      const AccountSection(),
                    ]),
                    card(l.settingsCapacity, l.settingsCapacityHint, [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l.settingsDefaultCapacity,
                            style: theme.textTheme.titleSmall,
                          ),
                          DurationStepper(
                            label: l.settingsDefaultCapacity,
                            value: settings.dailyCapacityMinutes,
                            onChanged: (v) => controller.updateSettings(
                              settings.copyWith(dailyCapacityMinutes: v),
                            ),
                          ),
                        ],
                      ),
                    ]),
                    card(l.settingsWeekdayCapacity, l.settingsWeekdayHint, [
                      for (final day in _weekdays)
                        _WeekdayRow(
                          weekday: day,
                          minutes: settings.capacityForWeekday(day),
                          isCustom: settings.weekdayCapacityMinutes.containsKey(
                            day,
                          ),
                          onChanged: (v) => controller.updateSettings(
                            settings.copyWith(
                              weekdayCapacityMinutes: {
                                ...settings.weekdayCapacityMinutes,
                                day: v,
                              },
                            ),
                          ),
                          onReset: () => controller.updateSettings(
                            settings.copyWith(
                              weekdayCapacityMinutes: {
                                for (final e
                                    in settings.weekdayCapacityMinutes.entries)
                                  if (e.key != day) e.key: e.value,
                              },
                            ),
                          ),
                        ),
                    ]),
                    card(l.settingsWeekStart, l.settingsWeekStartHint, [
                      DropdownButtonFormField<int>(
                        initialValue: settings.weekStartDay,
                        items: [
                          for (final day in _weekdays)
                            DropdownMenuItem(
                              value: day,
                              child: Text(formatWeekdayName(context, day)),
                            ),
                        ],
                        onChanged: (day) {
                          if (day == null) return;
                          controller.updateSettings(
                            settings.copyWith(weekStartDay: day),
                          );
                        },
                      ),
                    ]),
                    card(l.settingsReminders, l.settingsRemindersHint, [
                      const _ReminderSection(),
                    ]),
                    card(l.settingsDataTitle, null, [
                      Text(l.settingsDataBody),
                      const SizedBox(height: AppSpacing.m),
                      const _DataActions(),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reminder switches. Permission is requested only when the user turns
/// reminders on, with the reason already on screen (CLAUDE.md §13.1).
class _ReminderSection extends StatelessWidget {
  const _ReminderSection();

  static const _budgetChoices = [1, 2, 3, 4, 5];

  Future<void> _toggle(BuildContext context, bool on) async {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final scheduler = ReminderScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final settings = controller.settings;
    if (on && !await scheduler.requestPermission()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.settingsPermissionDenied)),
      );
      return;
    }
    controller.updateSettings(
      settings.copyWith(reminders: settings.reminders.copyWith(enabled: on)),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    int current,
    ReminderSettings Function(ReminderSettings r, int minute) apply,
  ) async {
    final controller = PlannerScope.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current ~/ Duration.minutesPerHour,
        minute: current % Duration.minutesPerHour,
      ),
    );
    if (picked == null) return;
    final settings = controller.settings;
    controller.updateSettings(
      settings.copyWith(
        reminders: apply(
          settings.reminders,
          picked.hour * Duration.minutesPerHour + picked.minute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final scheduler = ReminderScope.of(context);
    final settings = controller.settings;
    final r = settings.reminders;

    if (!scheduler.isSupported) return Text(l.settingsRemindersWebNote);

    String time(int minute) =>
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay(
            hour: minute ~/ Duration.minutesPerHour,
            minute: minute % Duration.minutesPerHour,
          ),
          alwaysUse24HourFormat: true,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.settingsRemindersEnable),
          value: r.enabled,
          onChanged: (on) => _toggle(context, on),
        ),
        if (r.enabled) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.settingsReminderTime),
            trailing: Text(
              time(r.dailyTimeMinutes),
              style: theme.textTheme.titleMedium,
            ),
            onTap: () => _pickTime(
              context,
              r.dailyTimeMinutes,
              (r, m) => r.copyWith(dailyTimeMinutes: m),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.settingsQuietFrom),
            trailing: Text(
              time(r.quietStartMinutes),
              style: theme.textTheme.titleMedium,
            ),
            onTap: () => _pickTime(
              context,
              r.quietStartMinutes,
              (r, m) => r.copyWith(quietStartMinutes: m),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.settingsQuietTo),
            trailing: Text(
              time(r.quietEndMinutes),
              style: theme.textTheme.titleMedium,
            ),
            onTap: () => _pickTime(
              context,
              r.quietEndMinutes,
              (r, m) => r.copyWith(quietEndMinutes: m),
            ),
          ),
          if (r.isQuiet(r.dailyTimeMinutes))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Text(
                l.settingsReminderInQuiet,
                style: TextStyle(color: theme.colorScheme.tertiary),
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.settingsDailyBudget),
            trailing: DropdownButton<int>(
              value: _budgetChoices.contains(r.dailyBudget)
                  ? r.dailyBudget
                  : _budgetChoices.last,
              underline: const SizedBox.shrink(),
              items: [
                for (final n in _budgetChoices)
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (n) {
                if (n == null) return;
                controller.updateSettings(
                  settings.copyWith(reminders: r.copyWith(dailyBudget: n)),
                );
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.settingsShowSensitive),
            subtitle: Text(l.settingsShowSensitiveHint),
            value: r.showSensitiveDetails,
            onChanged: (on) => controller.updateSettings(
              settings.copyWith(
                reminders: r.copyWith(showSensitiveDetails: on),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Export and delete: the data belongs to the user (CLAUDE.md §4.6).
class _DataActions extends StatelessWidget {
  const _DataActions();

  Future<void> _export(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final json = PlannerScope.of(context).exportJson();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.exportTitle),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
          FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: json));
              messenger.showSnackBar(SnackBar(content: Text(l.exportCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(l.exportCopy),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.deleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    controller.deleteAllData();
    messenger.showSnackBar(SnackBar(content: Text(l.dataDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.download_outlined),
          title: Text(l.settingsExport),
          subtitle: Text(l.settingsExportHint),
          onTap: () => _export(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
          title: Text(l.settingsDelete, style: TextStyle(color: scheme.error)),
          onTap: () => _delete(context),
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({
    required this.weekday,
    required this.minutes,
    required this.isCustom,
    required this.onChanged,
    required this.onReset,
  });

  final int weekday;
  final int minutes;
  final bool isCustom;
  final ValueChanged<int> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = formatWeekdayName(context, weekday);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isCustom ? FontWeight.w700 : null,
              color: isCustom ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DurationStepper(
                label: name,
                value: minutes,
                onChanged: onChanged,
              ),
              IconButton(
                tooltip: l.settingsResetDay(name),
                onPressed: isCustom ? onReset : null,
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
