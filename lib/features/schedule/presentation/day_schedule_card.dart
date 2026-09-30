import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/local_date.dart';
import '../../categories/presentation/category_style.dart';
import '../../focus/presentation/focus_screen.dart';
import '../../planning/presentation/planner_controller.dart';
import '../domain/time_block.dart';
import 'block_editor_sheet.dart';

enum _CopyFrom { previousDay, sameDayLastWeek }

/// "Günün akışı" on Today: the day on the clock. Shows today by default and
/// can step through the next days to plan ahead.
class DayScheduleCard extends StatefulWidget {
  const DayScheduleCard({super.key});

  static const nextDayKey = Key('schedule.nextDay');

  /// Planning ahead goes as far as a week.
  static const maxDaysAhead = 6;

  @override
  State<DayScheduleCard> createState() => _DayScheduleCardState();
}

class _DayScheduleCardState extends State<DayScheduleCard> {
  int _offset = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps the "now" highlight moving while the screen stays open.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _copy(LocalDate date, _CopyFrom from) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final source = switch (from) {
      _CopyFrom.previousDay => date.addDays(-1),
      _CopyFrom.sameDayLastWeek => date.addDays(-DateTime.daysPerWeek),
    };
    final result = controller.copyBlocks(from: source, to: date);
    final text = switch ((result.added.length, result.skipped)) {
      (0, 0) => l.scheduleNothingToCopy,
      (final added, 0) => l.scheduleCopied('$added'),
      (final added, final skipped) => l.scheduleCopySkipped(
        '$added',
        '$skipped',
      ),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final today = controller.today;
    final date = today.addDays(_offset);
    final blocks = controller.blocksOn(date);
    final now = _offset == 0 ? controller.clock.minuteOfDay() : null;
    final dayLabel = switch (_offset) {
      0 => l.scheduleToday,
      1 => l.scheduleTomorrow,
      _ => formatDayShort(context, date),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          AppSpacing.xs,
          AppSpacing.m,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.scheduleTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.schedulePrevDay,
                  onPressed: _offset == 0
                      ? null
                      : () => setState(() => _offset--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(dayLabel, style: theme.textTheme.labelLarge),
                IconButton(
                  key: DayScheduleCard.nextDayKey,
                  tooltip: l.scheduleNextDay,
                  onPressed: _offset == DayScheduleCard.maxDaysAhead
                      ? null
                      : () => setState(() => _offset++),
                  icon: const Icon(Icons.chevron_right),
                ),
                PopupMenuButton<_CopyFrom>(
                  tooltip: l.scheduleMore,
                  onSelected: (from) => _copy(date, from),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _CopyFrom.previousDay,
                      child: Text(l.scheduleCopyPrevious),
                    ),
                    PopupMenuItem(
                      value: _CopyFrom.sameDayLastWeek,
                      child: Text(l.scheduleCopyLastWeek),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (blocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s,
                      ),
                      child: Text(
                        l.scheduleEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final block in blocks)
                    _BlockTile(
                      block: block,
                      isNow: now != null && block.containsMinute(now),
                      canFocus: _offset == 0,
                    ),
                  const SizedBox(height: AppSpacing.s),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => showBlockEditor(context, date: date),
                      icon: const Icon(Icons.add),
                      label: Text(l.scheduleAddBlock),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({
    required this.block,
    required this.isNow,
    required this.canFocus,
  });

  final TimeBlock block;
  final bool isNow;
  final bool canFocus;

  static const double _barWidth = 4;
  static const double _timeWidth = 48;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = PlannerScope.of(context);
    final goal = switch (block.goalPeriodId) {
      final id? => controller.goalView(id),
      null => null,
    };
    final (String label, String? detail, Color color) = switch (block.kind) {
      TimeBlockKind.goal => (
        goal!.goal.title,
        goal.category.name,
        CategoryStyle.of(goal.category).color,
      ),
      TimeBlockKind.rest => (l.blockRestTitle, null, scheme.outline),
      TimeBlockKind.other => (block.title!, null, scheme.secondary),
    };
    final start = formatMinuteOfDay(block.startMinute);
    final end = formatMinuteOfDay(block.endMinute);
    final duration = l.minutes(block.minutes);

    return Semantics(
      button: true,
      label: [
        l.blockSemantics('$start–$end', label, duration),
        if (isNow) l.scheduleNow,
      ].join(', '),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Material(
          color: isNow ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppLayout.controlRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppLayout.controlRadius),
            onTap: () =>
                showBlockEditor(context, date: block.date, block: block),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.s,
              ),
              child: Row(
                children: [
                  SizedBox(
                    // Grows with the user's text size, so "09:00" never
                    // breaks in two.
                    width: MediaQuery.textScalerOf(context).scale(_timeWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(start, style: theme.textTheme.labelLarge),
                        Text(
                          end,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: _barWidth,
                    height: AppSpacing.xl + AppSpacing.xs,
                    margin: const EdgeInsets.only(right: AppSpacing.s),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(_barWidth),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [?detail, duration].join(' · '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (block.remind)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: AppSpacing.m + AppSpacing.xs,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (goal != null && canFocus)
                    IconButton(
                      tooltip: l.focusStart,
                      onPressed: () => openFocus(context, goal.period.id),
                      icon: const Icon(Icons.timer_outlined),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
