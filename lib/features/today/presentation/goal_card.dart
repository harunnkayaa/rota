import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/debt_notice.dart';
import '../../../shared/widgets/progress_line.dart';
import '../../planning/presentation/planner_controller.dart';
import '../../planning/presentation/redistribution_sheet.dart';
import 'add_progress_sheet.dart';

/// One goal on the Today screen: today's part and the week it feeds.
class GoalCard extends StatelessWidget {
  const GoalCard({required this.view, super.key});

  final GoalProgressView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(view.goal.title, style: theme.textTheme.titleMedium),
                      Text(
                        view.category.name,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(l.flexibleChip),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            ProgressLine(
              label: l.todayLabel,
              done: view.todayDone,
              target: view.todayAllocated,
              emptyText: l.todayNoPlan,
            ),
            const SizedBox(height: AppSpacing.m),
            ProgressLine(
              label: l.weekLabel,
              done: view.periodDone,
              target: view.period.targetValue,
            ),
            if (view.debt > 0) ...[
              const SizedBox(height: AppSpacing.m),
              DebtNotice(
                amount: view.debt,
                onRedistribute: () =>
                    showRedistributionSheet(context, view.period.id),
              ),
            ],
            const SizedBox(height: AppSpacing.s),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => showAddProgressSheet(context, view),
                icon: const Icon(Icons.add),
                label: Text(l.addProgress),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
