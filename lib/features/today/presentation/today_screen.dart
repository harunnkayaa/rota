import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../categories/domain/category.dart';
import '../../focus/presentation/focus_screen.dart';
import '../../goals/presentation/create_goal_screen.dart';
import '../../planning/presentation/planner_controller.dart';
import '../../sync/presentation/account_section.dart';
import '../../sync/presentation/sync_service.dart';
import 'goal_card.dart';
import 'week_review.dart';

/// The first screen: what to do today and how it feeds the week.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final goals = controller.activeGoals();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l.navToday)),
          SliverToBoxAdapter(
            child: ContentWidth(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Text(
                  formatDayLong(context, controller.today),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          if (SyncScope.maybeOf(context)?.status == SyncStatus.conflict)
            const SliverToBoxAdapter(
              child: ContentWidth(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.m,
                    AppSpacing.m,
                    0,
                  ),
                  child: SyncConflictBanner(),
                ),
              ),
            ),
          if (controller.activeFocus != null ||
              controller.pendingReviews.isNotEmpty)
            SliverToBoxAdapter(
              child: ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.m,
                    AppSpacing.m,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.activeFocus != null)
                        const FocusRunningBanner(),
                      if (controller.pendingReviews case final pending
                          when pending.isNotEmpty) ...[
                        if (controller.activeFocus != null)
                          const SizedBox(height: AppSpacing.m),
                        WeekReviewBanner(pending: pending),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          if (goals.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverToBoxAdapter(
              child: ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    AppSpacing.m,
                    AppSpacing.m,
                    AppLayout.fabClearance,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TodayHero(summary: controller.todaySummary()),
                      for (final goal in goals) ...[
                        const SizedBox(height: AppSpacing.m),
                        GoalCard(view: goal),
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

/// Ring with today's done/planned, and the three numbers that matter.
class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final capacity = summary.capacity;
    final planned = summary.plannedMinutes;

    final ring = Semantics(
      label: l.todayRingSemantics(
        l.minutes(summary.doneMinutes),
        l.minutes(planned),
      ),
      excludeSemantics: true,
      child: ProgressRing(
        value: planned == 0 ? 0 : summary.doneMinutes / planned,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatCompactMinutes(context, summary.doneMinutes),
              style: theme.textTheme.titleLarge,
            ),
            Text(
              l.todayProgressOf(formatCompactMinutes(context, planned)),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    final stats = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Stat(
          label: l.summaryRemaining,
          value: l.minutes(summary.remainingMinutes),
        ),
        _Stat(label: l.summaryPlanned, value: l.minutes(planned)),
        _Stat(label: l.summaryCapacityLeft, value: l.minutes(capacity.free)),
      ],
    );

    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Side by side when there's room; stacked on narrow screens
                // and with large accessibility text.
                final sideBySide =
                    constraints.maxWidth >=
                    _Stat.minSideBySideWidth *
                        MediaQuery.textScalerOf(context).scale(1);
                if (!sideBySide) {
                  return Column(
                    children: [
                      ring,
                      const SizedBox(height: AppSpacing.m),
                      stats,
                    ],
                  );
                }
                return Row(
                  children: [
                    ring,
                    const SizedBox(width: AppSpacing.l),
                    Expanded(child: stats),
                  ],
                );
              },
            ),
            if (capacity.isOver) ...[
              const SizedBox(height: AppSpacing.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  /// Below this card width the ring and the numbers are stacked.
  static const double minSideBySideWidth = 300;

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
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(value, style: theme.textTheme.titleMedium),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.route_outlined,
                  size: AppSpacing.xl * 1.5,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                l.emptyTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(l.emptyBody, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.l),
              FilledButton.icon(
                onPressed: () => openCreateGoal(context),
                icon: const Icon(Icons.add),
                label: Text(l.createGoalCta),
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
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
