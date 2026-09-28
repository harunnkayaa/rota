import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/local_date.dart';
import '../../../shared/widgets/duration_stepper.dart';

/// One row per day with its own amount. Past days are shown read-only.
///
/// Used by goal creation, the week plan editor and "today's plan".
class DayPlanEditor extends StatelessWidget {
  const DayPlanEditor({
    required this.days,
    required this.plan,
    required this.today,
    required this.onChanged,
    required this.capacityOn,
    required this.otherPlannedOn,
    this.doneOn,
    super.key,
  });

  final List<LocalDate> days;
  final Map<LocalDate, int> plan;
  final LocalDate today;
  final void Function(LocalDate day, int minutes) onChanged;

  /// The user's capacity on a day.
  final int Function(LocalDate day) capacityOn;

  /// Minutes other goals already plan on a day.
  final int Function(LocalDate day) otherPlannedOn;

  /// Work already done on a day (for past days); null for new goals.
  final int Function(LocalDate day)? doneOn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, day) in days.indexed) ...[
          if (index > 0) const Divider(height: 1),
          _DayRow(
            day: day,
            minutes: plan[day] ?? 0,
            isToday: day == today,
            isPast: day.isBefore(today),
            done: doneOn?.call(day) ?? 0,
            overBy: otherPlannedOn(day) + (plan[day] ?? 0) - capacityOn(day),
            onChanged: (m) => onChanged(day, m),
          ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.minutes,
    required this.isToday,
    required this.isPast,
    required this.done,
    required this.overBy,
    required this.onChanged,
  });

  final LocalDate day;
  final int minutes;
  final bool isToday;
  final bool isPast;
  final int done;
  final int overBy;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = formatDayShort(context, day);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap: on narrow screens or with large text the control moves
          // under the day name instead of overflowing.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isPast ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  if (isToday)
                    Text(
                      l.weekdayToday,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (isPast)
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: AppSpacing.xs,
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: l.pastDayLocked(
                          l.minutes(done),
                          l.minutes(minutes),
                        ),
                      ),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                DurationStepper(
                  label: label,
                  value: minutes,
                  onChanged: onChanged,
                ),
            ],
          ),
          if (!isPast && overBy > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: scheme.tertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l.capacityRowOver(l.minutes(overBy)),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What a [PlanSummary] compares.
enum PlanSummaryMode {
  /// A new weekly goal: the whole plan against the weekly target.
  weeklyTarget,

  /// Editing a weekly goal: plan from today on against what is left. Past
  /// days are settled, so making up a short Monday counts as covered.
  remaining,

  /// A deadline goal: this week's plan against this week's pace share.
  weekPace,
}

/// Planned vs. target with a bar and a plain-language status line.
class PlanSummary extends StatelessWidget {
  const PlanSummary({
    required this.planned,
    required this.target,
    this.mode = PlanSummaryMode.weeklyTarget,
    super.key,
  });

  final int planned;
  final int target;
  final PlanSummaryMode mode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gap = target - planned;
    final plannedText = l.minutes(planned);
    final targetText = l.minutes(target);
    final gapText = l.minutes(gap.abs());

    final title = switch (mode) {
      PlanSummaryMode.weeklyTarget => l.planDistributed(
        plannedText,
        targetText,
      ),
      PlanSummaryMode.remaining => l.planRemainingOf(plannedText, targetText),
      PlanSummaryMode.weekPace => l.planWeekPaceOf(plannedText, targetText),
    };
    final (IconData icon, Color color, String message) = switch (gap) {
      > 0 => (
        Icons.info_outline,
        scheme.tertiary,
        switch (mode) {
          PlanSummaryMode.weeklyTarget => l.planUnallocated(gapText),
          PlanSummaryMode.remaining => l.planDebt(gapText),
          PlanSummaryMode.weekPace => l.planWeekPaceMissing(gapText),
        },
      ),
      < 0 => (
        Icons.trending_up,
        scheme.primary,
        switch (mode) {
          PlanSummaryMode.weeklyTarget => l.planOverTarget(gapText),
          PlanSummaryMode.remaining => l.planOverRemaining(gapText),
          PlanSummaryMode.weekPace => l.planWeekPaceOver(gapText),
        },
      ),
      _ => (
        Icons.check_circle,
        scheme.primary,
        switch (mode) {
          PlanSummaryMode.weeklyTarget => l.planCovers,
          PlanSummaryMode.remaining => l.planCoversRemaining,
          PlanSummaryMode.weekPace => l.planWeekPaceCovers,
        },
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.s),
        LinearProgressIndicator(
          value: target == 0 ? 0 : (planned / target).clamp(0, 1),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ],
    );
  }
}
