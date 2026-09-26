import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/content_width.dart';
import '../../categories/domain/category.dart';
import '../../goals/presentation/create_goal_screen.dart';
import '../../planning/presentation/planner_controller.dart';
import 'goal_card.dart';

/// The first screen: what to do today and how it feeds the week.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final goals = controller.activeGoals();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.navToday),
            Text(
              formatDayLong(context, controller.today),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: goals.isEmpty
          ? const _EmptyState()
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.s,
                  AppSpacing.m,
                  // Leaves room above the floating "Hedef ekle" button.
                  AppSpacing.xl * 3,
                ),
                children: [
                  _SummaryCard(summary: controller.todaySummary()),
                  for (final goal in goals) ...[
                    const SizedBox(height: AppSpacing.m),
                    GoalCard(view: goal),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final capacity = summary.capacity;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final metrics = [
                  (l.summaryPlanned, l.minutes(summary.plannedMinutes)),
                  (l.summaryDone, l.minutes(summary.doneMinutes)),
                  (l.summaryCapacityLeft, l.minutes(capacity.free)),
                ];
                // Three columns when there is room; stacked rows on narrow
                // screens or with large accessibility text.
                final stacked =
                    constraints.maxWidth <
                    _Metric.minColumnWidth *
                        metrics.length *
                        MediaQuery.textScalerOf(context).scale(1);
                if (stacked) {
                  return Column(
                    children: [
                      for (final (label, value) in metrics)
                        _MetricRow(label: label, value: value),
                    ],
                  );
                }
                return Row(
                  children: [
                    for (final (label, value) in metrics)
                      Expanded(
                        child: _Metric(label: label, value: value),
                      ),
                  ],
                );
              },
            ),
            if (capacity.isOver) ...[
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: scheme.tertiary),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(l.capacityOver(l.minutes(capacity.overBy))),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  /// Below this width per column (at normal text size) labels would break
  /// mid-word, so the card switches to stacked rows.
  static const double minColumnWidth = 110;

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.s),
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(l.emptyTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.s),
              Text(l.emptyBody, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.l),
              FilledButton.icon(
                onPressed: () => openCreateGoal(context),
                icon: const Icon(Icons.add),
                label: Text(l.createGoalCta),
              ),
              const SizedBox(height: AppSpacing.s),
              OutlinedButton(
                onPressed: () => PlannerScope.of(context).loadSampleWeek(
                  SampleWeekTexts(
                    projectCategory: l.presetName(
                      PresetCategory.projectDevelopment,
                    ),
                    languageCategory: l.presetName(PresetCategory.language),
                    projectGoal: l.sampleProjectGoal,
                    languageGoal: l.sampleLanguageGoal,
                  ),
                ),
                child: Text(l.loadSampleCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
