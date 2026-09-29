import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/debt_notice.dart';
import '../../../shared/widgets/progress_line.dart';
import '../../categories/presentation/category_style.dart';
import '../../focus/presentation/focus_screen.dart';
import '../../planning/presentation/deadline_pace_section.dart';
import '../../planning/presentation/goal_actions_menu.dart';
import '../../planning/presentation/plan_editor_sheet.dart';
import '../../planning/presentation/planner_controller.dart';
import '../../planning/presentation/redistribution_sheet.dart';
import 'add_progress_sheet.dart';

/// One goal on the Today screen: today's part and the week it feeds.
class GoalCard extends StatelessWidget {
  const GoalCard({required this.view, super.key});

  final GoalProgressView view;

  static final _actionStyle = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = PlannerScope.of(context).today;

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
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (view.todayRemaining > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _RemainingBadge(
                          text: l.remainingToday(
                            l.minutes(view.todayRemaining),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l.editTodayPlan,
                  onPressed: () => showPlanEditorSheet(
                    context,
                    periodId: view.period.id,
                    onlyDate: today,
                  ),
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
                GoalActionsMenu(view: view),
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
            if (view.isDeadline)
              DeadlinePaceSection(view: view)
            else
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
            const SizedBox(height: AppSpacing.m),
            // The two daily actions, side by side and easy to reach.
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: _actionStyle,
                    onPressed: () => showAddProgressSheet(context, view),
                    icon: const Icon(Icons.add),
                    label: Text(l.addProgress, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: FilledButton.icon(
                    style: _actionStyle,
                    onPressed: () => openFocus(context, view.period.id),
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(l.focusStart, overflow: TextOverflow.ellipsis),
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

class _RemainingBadge extends StatelessWidget {
  const _RemainingBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s + AppSpacing.xs,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppLayout.controlRadius),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
