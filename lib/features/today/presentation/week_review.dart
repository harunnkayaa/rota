import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../categories/presentation/category_style.dart';
import '../../planning/domain/period_closing.dart';
import '../../planning/presentation/planner_controller.dart';

/// Shown on Today after a week (or a dated goal) closes: the result is
/// ready, and nothing moves to the new week unless the user says so.
class WeekReviewBanner extends StatelessWidget {
  const WeekReviewBanner({required this.pending, super.key});

  final List<PeriodSnapshot> pending;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insights, color: scheme.onSecondaryContainer),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.reviewTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onSecondaryContainer),
                      ),
                      Text(
                        l.reviewBody('${pending.length}'),
                        style: TextStyle(color: scheme.onSecondaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => showWeekReviewSheet(context),
                child: Text(l.reviewOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showWeekReviewSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const WeekReviewSheet(),
  );
}

class WeekReviewSheet extends StatelessWidget {
  const WeekReviewSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final pending = controller.pendingReviews;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.reviewSheetTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.m),
          for (final snapshot in pending) _ReviewRow(snapshot: snapshot),
          const SizedBox(height: AppSpacing.m),
          FilledButton(
            onPressed: () {
              controller.markReviewed();
              Navigator.of(context).pop();
            },
            child: Text(l.reviewAcknowledge),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.snapshot});

  final PeriodSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final category = controller.categoryById(snapshot.categoryId);
    final carried =
        snapshot.shortfall > 0 &&
        !controller.canCarryOver(snapshot) &&
        controller.currentPeriodOf(snapshot.goalId)?.carryoverFromPeriodId ==
            snapshot.periodId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null)
            CategoryAvatar(style: CategoryStyle.of(category), size: 36),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snapshot.goalTitle, style: theme.textTheme.titleSmall),
                Text(
                  '${formatDayMonth(context, snapshot.range.start)} – '
                  '${formatDayMonth(context, snapshot.range.endExclusive.addDays(-1))}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.progressOf(
                    l.minutes(snapshot.achieved),
                    l.minutes(snapshot.target),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  snapshot.shortfall == 0
                      ? l.deadlineStatusCompleted
                      : l.reviewShortfall(l.minutes(snapshot.shortfall)),
                ),
                if (controller.canCarryOver(snapshot))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: OutlinedButton.icon(
                      onPressed: () => controller.carryOver(snapshot),
                      icon: const Icon(Icons.redo),
                      label: Text(
                        l.carryOverAction(l.minutes(snapshot.shortfall)),
                      ),
                    ),
                  )
                else if (carried)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(l.carryOverDone),
                      ],
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
