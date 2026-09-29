import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/duration_stepper.dart';
import '../../goals/domain/progress_entry.dart';
import '../../goals/presentation/create_goal_screen.dart';
import 'planner_controller.dart';

/// Rename a goal and change its target. Progress is never touched; every
/// derived number (remaining, pace, debt) follows the new target.
Future<void> showGoalEditSheet(BuildContext context, GoalProgressView view) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GoalEditSheet(view: view),
  );
}

class _GoalEditSheet extends StatefulWidget {
  const _GoalEditSheet({required this.view});

  final GoalProgressView view;

  @override
  State<_GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<_GoalEditSheet> {
  late final _title = TextEditingController(text: widget.view.goal.title);
  late int _target = widget.view.period.targetValue;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l.errorTitleRequired);
      return;
    }
    final view = widget.view;
    if (title != view.goal.title) controller.renameGoal(view.goal.id, title);
    if (_target != view.period.targetValue) {
      controller.updateTarget(view.period.id, _target);
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l.goalUpdated)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDeadline = widget.view.isDeadline;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.editGoal, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l.sectionTitle,
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            isDeadline ? l.sectionTotalTarget : l.sectionWeeklyTarget,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.s),
          Center(
            child: DurationStepper(
              label: isDeadline ? l.sectionTotalTarget : l.sectionWeeklyTarget,
              value: _target,
              step: targetStepMinutes,
              max: isDeadline
                  ? maxDeadlineTargetMinutes
                  : maxWeeklyTargetMinutes,
              emphasized: true,
              onChanged: (v) => setState(() => _target = v),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: _target > 0 ? _save : null,
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}

/// Today's entries of one goal, each of which can be taken back.
Future<void> showTodayEntriesSheet(
  BuildContext context,
  GoalProgressView view,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TodayEntriesSheet(view: view),
  );
}

class _TodayEntriesSheet extends StatelessWidget {
  const _TodayEntriesSheet({required this.view});

  final GoalProgressView view;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final entries = controller.undoableEntries(view.period.id);
    final time = MaterialLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.todayEntries, style: theme.textTheme.titleLarge),
          Text(
            view.goal.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          if (entries.isEmpty)
            Text(l.todayEntriesEmpty)
          else ...[
            Text(l.todayEntriesHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.s),
            for (final e in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  e.source == ProgressSource.focusTimer
                      ? Icons.timer_outlined
                      : Icons.edit_outlined,
                ),
                title: Text(
                  l.entryLine(
                    time.formatTimeOfDay(
                      TimeOfDay.fromDateTime(e.occurredAt.toLocal()),
                      alwaysUse24HourFormat: true,
                    ),
                    l.minutes(e.valueDelta),
                    e.source == ProgressSource.focusTimer
                        ? l.entrySourceFocus
                        : l.entrySourceManual,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    controller.undoProgress(e.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l.entryTakenBack(l.minutes(e.valueDelta)),
                        ),
                      ),
                    );
                  },
                  child: Text(l.undo),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
