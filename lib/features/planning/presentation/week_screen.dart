import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/local_date.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/debt_notice.dart';
import '../../../shared/widgets/progress_line.dart';
import '../../categories/presentation/category_style.dart';
import '../domain/capacity.dart';
import 'plan_editor_sheet.dart';
import 'planner_controller.dart';
import 'redistribution_sheet.dart';

/// The whole week: daily capacity, each goal's plan per day, and what is
/// left unplanned. Every goal's plan can be edited from here.
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final week = controller.currentWeek;
    final goals = controller.activeGoals();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l.weekTitle)),
          SliverToBoxAdapter(
            child: ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  0,
                  AppSpacing.m,
                  AppLayout.fabClearance,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.weekRange(
                        formatDayMonth(context, week.start),
                        formatDayMonth(context, week.endInclusive),
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    const _CapacityCard(),
                    if (goals.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Text(l.weekNoGoals, textAlign: TextAlign.center),
                      ),
                    for (final goal in goals) ...[
                      const SizedBox(height: AppSpacing.m),
                      _WeekGoalCard(view: goal),
                    ],
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

/// Seven vertical bars: planned minutes against each day's capacity.
class _CapacityCard extends StatelessWidget {
  const _CapacityCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.capacityTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in controller.currentWeek.days)
                  Expanded(
                    child: _CapacityBar(
                      day: day,
                      check: controller.capacityOn(day),
                      isToday: day == controller.today,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({
    required this.day,
    required this.check,
    required this.isToday,
  });

  final LocalDate day;
  final CapacityCheck check;
  final bool isToday;

  static const double _barHeight = 72;
  static const double _barWidth = 14;
  static const double _iconSlot = 16;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final CapacityCheck(:planned, :capacity, :overBy) = check;
    final fill = capacity == 0 ? 0.0 : (planned / capacity).clamp(0.0, 1.0);
    final overText = overBy > 0
        ? ', ${l.capacityDayOver(l.minutes(overBy))}'
        : '';

    return Semantics(
      label:
          '${formatDayShort(context, day)}: '
          '${l.capacityOfDay(l.minutes(planned), l.minutes(capacity))}'
          '$overText',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: _barHeight,
            width: _barWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(_barWidth / 2),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fill,
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: overBy > 0 ? scheme.tertiary : scheme.primary,
                      borderRadius: BorderRadius.circular(_barWidth / 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: _iconSlot,
            child: overBy > 0
                ? Icon(
                    Icons.warning_amber_rounded,
                    size: _iconSlot,
                    color: scheme.tertiary,
                  )
                : null,
          ),
          Text(
            formatWeekdayShort(context, day),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isToday ? FontWeight.w800 : null,
              color: isToday ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatCompactMinutes(context, planned),
              style: theme.textTheme.labelSmall,
            ),
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
    final controller = PlannerScope.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CategoryAvatar(style: CategoryStyle.of(view.category)),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(view.goal.title, style: theme.textTheme.titleMedium),
                      Text(
                        view.category.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l.editPlanTooltip,
                  onPressed: () =>
                      showPlanEditorSheet(context, periodId: view.period.id),
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            ProgressLine(
              label: l.weekLabel,
              done: view.periodDone,
              target: view.period.targetValue,
            ),
            if (view.surplus > 0) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                l.overAllocated(l.minutes(view.surplus)),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                for (final day in view.days)
                  Expanded(
                    child: _DayCell(
                      day: day,
                      isToday: day.date == controller.today,
                      onTap: day.date.isBefore(controller.today)
                          ? null
                          : () => showPlanEditorSheet(
                              context,
                              periodId: view.period.id,
                              onlyDate: day.date,
                            ),
                    ),
                  ),
              ],
            ),
            if (view.debt > 0) ...[
              const SizedBox(height: AppSpacing.m),
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

/// One day of a goal: planned amount, how much of it is done, and status.
/// Tapping a day (today or later) edits that day's plan.
class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isToday, this.onTap});

  final DayProgress day;
  final bool isToday;
  final VoidCallback? onTap;

  static const double _cellHeight = 44;
  static const double _iconSlot = 16;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (
      IconData? icon,
      Color iconColor,
      String status,
    ) = switch (day.status) {
      DayStatus.done => (Icons.check_circle, scheme.primary, l.dayStatusDone),
      DayStatus.missed => (
        Icons.remove_circle_outline,
        scheme.tertiary,
        l.dayStatusMissed(l.minutes(day.shortfall)),
      ),
      DayStatus.today => (null, scheme.primary, l.dayStatusToday),
      DayStatus.upcoming => (null, scheme.outline, l.dayStatusUpcoming),
      DayStatus.unplanned => (null, scheme.outline, l.dayStatusNoPlan),
    };
    final fill = day.allocated == 0
        ? 0.0
        : (day.done / day.allocated).clamp(0.0, 1.0);

    return Semantics(
      button: onTap != null,
      label: l.dayCellSemantics(
        formatDayShort(context, day.date),
        l.progressOf(l.minutes(day.done), l.minutes(day.allocated)),
        status,
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.s),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              Text(
                formatWeekdayShort(context, day.date),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isToday ? FontWeight.w800 : null,
                  color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                height: _cellHeight,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.s),
                  border: isToday
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: fill,
                        widthFactor: 1,
                        child: ColoredBox(
                          color: scheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            day.allocated == 0
                                ? '–'
                                : formatCompactMinutes(context, day.allocated),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: _iconSlot,
                child: icon == null
                    ? null
                    : Icon(icon, size: _iconSlot, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
