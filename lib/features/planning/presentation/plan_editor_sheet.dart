import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/local_date.dart';
import '../domain/plan_editing.dart';
import 'day_plan_editor.dart';
import 'planner_controller.dart';

/// Edits how much of a goal is planned per day. With [onlyDate] it edits
/// just that day ("Bugünün planı"); otherwise the whole week.
Future<void> showPlanEditorSheet(
  BuildContext context, {
  required String periodId,
  LocalDate? onlyDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PlanEditorSheet(periodId: periodId, onlyDate: onlyDate),
  );
}

class PlanEditorSheet extends StatefulWidget {
  const PlanEditorSheet({required this.periodId, this.onlyDate, super.key});

  final String periodId;
  final LocalDate? onlyDate;

  @override
  State<PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<PlanEditorSheet> {
  /// Only the days the user touched; everything else stays as saved.
  final _changes = <LocalDate, int>{};
  String? _error;

  void _save() {
    final l = AppLocalizations.of(context);
    try {
      PlannerScope.of(context).updatePlan(widget.periodId, _changes);
    } on PlanEditRejectedException catch (e) {
      setState(
        () => _error = e.reason == PlanEditRejection.dateInPast
            ? l.errorPlanPast
            : l.errorPlanGeneric,
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l.planApplied)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final view = controller.goalView(widget.periodId);
    final preview = controller.previewPlan(widget.periodId, _changes);
    final saved = {for (final d in view.days) d.date: d.allocated};
    final plan = {...saved, ..._changes};
    final days = widget.onlyDate == null
        ? view.period.range.days.toList()
        : [widget.onlyDate!];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(switch (widget.onlyDate) {
              null => l.editWeekPlan,
              final day when day == controller.today => l.editTodayPlan,
              final day => l.dayPlanTitle(formatDayShort(context, day)),
            }, style: theme.textTheme.titleLarge),
            Text(view.goal.title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.m),
            PlanSummary(
              planned: preview.remainingPlanned,
              target: preview.remainingTarget,
              editing: true,
            ),
            const SizedBox(height: AppSpacing.m),
            DayPlanEditor(
              days: days,
              plan: plan,
              today: controller.today,
              capacityOn: controller.capacity.capacityOn,
              otherPlannedOn: (d) => controller.plannedOnExcluding(
                d,
                excludePeriodId: widget.periodId,
              ),
              doneOn: (d) => view.days.firstWhere((p) => p.date == d).done,
              onChanged: (day, minutes) => setState(() {
                _error = null;
                if (saved[day] == minutes) {
                  _changes.remove(day);
                } else {
                  _changes[day] = minutes;
                }
              }),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 52),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: FilledButton(
                    onPressed: _changes.isEmpty ? null : _save,
                    child: Text(l.save),
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
