import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/debt_notice.dart';
import '../../../shared/widgets/progress_line.dart';
import '../domain/capacity.dart';
import 'planner_controller.dart';
import 'redistribution_sheet.dart';

/// The whole week: daily capacity, each goal's plan per day, and what is
/// left unplanned.
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final week = controller.currentWeek;
    final goals = controller.activeGoals();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.weekTitle),
            Text(
              l.weekRange(
                formatDayMonth(context, week.start),
                formatDayMonth(context, week.endInclusive),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.xl * 3,
          ),
          children: [
            const _CapacityCard(),
            const SizedBox(height: AppSpacing.m),
            if (goals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(l.weekNoGoals, textAlign: TextAlign.center),
              ),
            for (final goal in goals) ...[
              _WeekGoalCard(view: goal),
              const SizedBox(height: AppSpacing.m),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.capacityTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            for (final day in controller.currentWeek.days)
              _CapacityRow(
                label: formatDayShort(context, day),
                check: controller.capacityOn(day),
                isToday: day == controller.today,
              ),
          ],
        ),
      ),
    );
  }
}

class _CapacityRow extends StatelessWidget {
  const _CapacityRow({
    required this.label,
    required this.check,
    required this.isToday,
  });

  final String label;
  final CapacityCheck check;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final CapacityCheck(:planned, :capacity, :overBy) = check;

    final labelStyle = isToday
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;

    // Two lines instead of one: survives narrow phones and large text sizes.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: labelStyle)),
              Flexible(
                child: Text(
                  l.capacityOfDay(l.minutes(planned), l.minutes(capacity)),
                  textAlign: TextAlign.end,
                ),
              ),
              if (overBy > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                  semanticLabel: l.capacityDayOver(l.minutes(overBy)),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: capacity == 0 ? 0 : (planned / capacity).clamp(0, 1),
          ),
        ],
      ),
    );
  }
}

class _WeekGoalCard extends StatelessWidget {
  const _WeekGoalCard({required this.view});

  final GoalProgressView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plannedDays = view.days.where((d) => d.status != DayStatus.unplanned);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(view.goal.title, style: theme.textTheme.titleMedium),
            Text(view.category.name, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.m),
            ProgressLine(
              label: l.weekLabel,
              done: view.periodDone,
              target: view.period.targetValue,
            ),
            if (view.unallocated != 0) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                view.unallocated > 0
                    ? l.unallocated(l.minutes(view.unallocated))
                    : l.overAllocated(l.minutes(-view.unallocated)),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.s),
            for (final day in plannedDays) _DayRow(day: day),
            if (view.debt > 0) ...[
              const SizedBox(height: AppSpacing.s),
              DebtNotice(
                amount: view.debt,
                onRedistribute: () =>
                    showRedistributionSheet(context, view.period.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final DayProgress day;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Icon + text for every status: colour is never the only signal.
    final (icon, color, statusText) = switch (day.status) {
      DayStatus.done => (Icons.check_circle, scheme.primary, l.dayStatusDone),
      DayStatus.missed => (
        Icons.remove_circle_outline,
        scheme.tertiary,
        l.dayStatusMissed(l.minutes(day.shortfall)),
      ),
      DayStatus.today => (
        Icons.play_circle_outline,
        scheme.primary,
        l.dayStatusToday,
      ),
      DayStatus.upcoming || DayStatus.unplanned => (
        Icons.circle_outlined,
        scheme.outline,
        l.dayStatusUpcoming,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(formatDayShort(context, day.date))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l.progressOf(l.minutes(day.done), l.minutes(day.allocated))),
              Text(statusText, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
