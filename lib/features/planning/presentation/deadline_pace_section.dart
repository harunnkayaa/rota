import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/progress_line.dart';
import '../domain/deadline_pace.dart';
import 'catch_up_sheet.dart';
import 'planner_controller.dart';

/// Pace of a goal with a due date: this week's share, the total, the date,
/// and — when behind — what can be done about it.
class DeadlinePaceSection extends StatelessWidget {
  const DeadlinePaceSection({required this.view, super.key});

  final GoalProgressView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pace = view.pace!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgressLine(
          label: l.weekPaceLabel,
          done: pace.doneThisWeek,
          target: pace.requiredThisWeek,
        ),
        const SizedBox(height: AppSpacing.m),
        ProgressLine(label: l.totalLabel, done: pace.done, target: pace.total),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DeadlineStatusChip(pace: pace),
            Text(
              l.dueDateValue(
                formatDayMonth(context, pace.dueDate),
                '${pace.daysLeft}',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (pace.status != DeadlineStatus.completed)
              Text(
                '· ${l.pacePerWeek(l.minutes(pace.requiredPerWeek))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (_notice(context, pace) case final text?) ...[
          const SizedBox(height: AppSpacing.m),
          _PaceNotice(
            text: text,
            onOptions: () => showCatchUpSheet(context, view.period.id),
          ),
        ],
      ],
    );
  }

  String? _notice(BuildContext context, DeadlinePace pace) {
    final l = AppLocalizations.of(context);
    return switch (pace.status) {
      DeadlineStatus.notFeasible => l.paceNotFeasibleNotice(
        formatDayMonth(context, pace.dueDate),
        l.minutes(pace.shortfall),
      ),
      DeadlineStatus.behindThisWeek => l.paceBehindNotice(
        l.minutes(pace.thisWeekGap),
      ),
      _ => null,
    };
  }
}

/// Status in words and an icon; colour is never the only signal.
class DeadlineStatusChip extends StatelessWidget {
  const DeadlineStatusChip({required this.pace, super.key});

  final DeadlinePace pace;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (
      IconData icon,
      Color background,
      Color foreground,
      String text,
    ) = switch (pace.status) {
      DeadlineStatus.completed => (
        Icons.emoji_events_outlined,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        l.deadlineStatusCompleted,
      ),
      DeadlineStatus.onTrack => (
        Icons.check_circle_outline,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        l.deadlineStatusOnTrack,
      ),
      DeadlineStatus.behindThisWeek => (
        Icons.schedule,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        l.deadlineStatusBehind(l.minutes(pace.thisWeekGap)),
      ),
      DeadlineStatus.notFeasible => (
        Icons.trending_down,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        l.deadlineStatusNotFeasible(l.minutes(pace.shortfall)),
      ),
      DeadlineStatus.overdue => (
        Icons.event_busy_outlined,
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        l.deadlineStatusOverdue,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s + AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppLayout.controlRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaceNotice extends StatelessWidget {
  const _PaceNotice({required this.text, required this.onOptions});

  final String text;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.s),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.xs,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_outlined, color: scheme.onTertiaryContainer),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOptions,
                child: Text(l.paceOptions),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
