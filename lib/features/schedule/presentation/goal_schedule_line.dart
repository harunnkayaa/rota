import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../planning/presentation/planner_controller.dart';

/// Under a goal's "Bugün" line: when today's plan happens ("Saatte:
/// 09:00–11:00") and how much of it has no time yet. Nothing when the goal
/// has no blocks today.
class GoalScheduleLine extends StatelessWidget {
  const GoalScheduleLine({required this.view, super.key});

  final GoalProgressView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final blocks = [
      for (final b in controller.blocksOn(controller.today))
        if (b.goalPeriodId == view.period.id) b,
    ];
    if (blocks.isEmpty) return const SizedBox.shrink();
    final ranges = blocks
        .map(
          (b) =>
              '${formatMinuteOfDay(b.startMinute)}–'
              '${formatMinuteOfDay(b.endMinute)}',
        )
        .join(', ');
    final scheduled = blocks.fold(0, (sum, b) => sum + b.minutes);
    final unscheduled = (view.todayAllocated ?? 0) - scheduled;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule,
            size: AppSpacing.m,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              [
                l.goalScheduledToday(ranges),
                if (unscheduled > 0) l.goalUnscheduled(l.minutes(unscheduled)),
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
