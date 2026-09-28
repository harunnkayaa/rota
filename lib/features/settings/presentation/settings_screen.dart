import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/duration_stepper.dart';
import '../../planning/presentation/planner_controller.dart';

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
                    card(l.settingsDataTitle, null, [Text(l.settingsDataBody)]),
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
