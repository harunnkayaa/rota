import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/progress_line.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../categories/presentation/category_style.dart';
import '../../planning/domain/period_closing.dart';
import '../../planning/presentation/planner_controller.dart';
import '../domain/weekly_report.dart';

/// Planned vs. done: this week, by life area, and week by week
/// (CLAUDE.md §13.6).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final thisWeek = controller.currentWeekSummary();
    final history = weeklyHistory(controller.snapshots);
    final deadlines = finishedDeadlines(controller.snapshots);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l.reportsTitle)),
          SliverToBoxAdapter(
            child: ContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  0,
                  AppSpacing.m,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WeekCard(
                      title: l.reportsThisWeek,
                      week: thisWeek,
                      previous: history.isEmpty ? null : history.first,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _CategoryCard(week: thisWeek),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      l.reportsHistory,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    if (history.isEmpty)
                      Text(l.reportsEmptyHistory)
                    else
                      for (final (i, week) in history.indexed) ...[
                        _WeekCard(
                          title: l.weekRange(
                            formatDayMonth(context, week.range.start),
                            formatDayMonth(context, week.range.endInclusive),
                          ),
                          week: week,
                          previous: i + 1 < history.length
                              ? history[i + 1]
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.m),
                      ],
                    if (deadlines.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        l.reportsDeadlines,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      for (final s in deadlines) _DeadlineResult(snapshot: s),
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

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.title, required this.week, this.previous});

  final String title;
  final WeekSummary week;
  final WeekSummary? previous;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final previous = this.previous;
    final change = previous == null ? null : week.done - previous.done;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProgressRing(
                  size: 72,
                  strokeWidth: 8,
                  value: week.completionPercent / 100,
                  child: Text(
                    l.reportsPercent('${week.completionPercent}'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        l.progressOf(
                          l.minutes(week.done),
                          l.minutes(week.target),
                        ),
                        style: theme.textTheme.titleLarge,
                      ),
                      if (change != null)
                        Text(switch (change) {
                          > 0 => l.reportsChangeUp(l.minutes(change)),
                          < 0 => l.reportsChangeDown(l.minutes(-change)),
                          _ => l.reportsChangeSame,
                        }, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (week.lines.isNotEmpty) const SizedBox(height: AppSpacing.m),
            for (final line in week.lines) ...[
              ProgressLine(
                label: line.title,
                done: line.done,
                target: line.target,
              ),
              const SizedBox(height: AppSpacing.s),
            ],
          ],
        ),
      ),
    );
  }
}

/// Where this week's time actually went — the balance between life areas.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.week});

  final WeekSummary week;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final byCategory = week.doneByCategory;
    final total = byCategory.fold(0, (sum, e) => sum + e.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.reportsByCategory, style: theme.textTheme.titleMedium),
            Text(
              l.reportsByCategoryHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            if (byCategory.isEmpty) Text(l.reportsNoWorkYet),
            for (final MapEntry(key: categoryId, value: minutes) in byCategory)
              _CategoryBar(
                categoryId: categoryId,
                name: controller.categoryName(categoryId),
                minutes: minutes,
                share: total == 0 ? 0 : minutes / total,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categoryId,
    required this.name,
    required this.minutes,
    required this.share,
  });

  final String categoryId;
  final String name;
  final int minutes;
  final double share;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final category = PlannerScope.of(context).categoryById(categoryId);
    final style = category == null ? null : CategoryStyle.of(category);
    final percent = (share * 100).round();

    return Semantics(
      label: '$name: ${l.minutes(minutes)}, ${l.reportsPercent('$percent')}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (style != null) ...[
                  Icon(style.icon, size: 18, color: style.color),
                  const SizedBox(width: AppSpacing.s),
                ],
                Expanded(child: Text(name)),
                Text(
                  '${l.minutes(minutes)} · ${l.reportsPercent('$percent')}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(value: share, color: style?.color),
          ],
        ),
      ),
    );
  }
}

class _DeadlineResult extends StatelessWidget {
  const _DeadlineResult({required this.snapshot});

  final PeriodSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        leading: Icon(
          snapshot.shortfall == 0 ? Icons.emoji_events_outlined : Icons.flag,
        ),
        title: Text(snapshot.goalTitle),
        subtitle: Text(formatDayLong(context, snapshot.range.endExclusive)),
        trailing: Text(
          l.progressOf(
            l.minutes(snapshot.achieved),
            l.minutes(snapshot.target),
          ),
        ),
      ),
    );
  }
}
