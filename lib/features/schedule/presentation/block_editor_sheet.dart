import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/local_date.dart';
import '../../../core/utils/uuid.dart';
import '../../planning/presentation/planner_controller.dart';
import '../../reminders/presentation/reminder_sync.dart';
import '../domain/schedule_rules.dart';
import '../domain/time_block.dart';

/// Adds a block on [date], or edits [block].
Future<void> showBlockEditor(
  BuildContext context, {
  required LocalDate date,
  TimeBlock? block,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlockEditorSheet(date: date, block: block),
  );
}

class BlockEditorSheet extends StatefulWidget {
  const BlockEditorSheet({required this.date, this.block, super.key});

  final LocalDate date;
  final TimeBlock? block;

  static const titleFieldKey = Key('block.title');
  static const startKey = Key('block.start');
  static const endKey = Key('block.end');
  static const quickDurations = [15, 30, 60, 90, 120];

  @override
  State<BlockEditorSheet> createState() => _BlockEditorSheetState();
}

class _BlockEditorSheetState extends State<BlockEditorSheet> {
  static const _defaultMinutes = 60;

  late TimeBlockKind _kind = widget.block?.kind ?? TimeBlockKind.goal;
  late String? _periodId = widget.block?.goalPeriodId;
  late final _title = TextEditingController(text: widget.block?.title);
  late int _start;
  late int _end;
  late bool _remind = widget.block?.remind ?? false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs again whenever the planner changes; only the first time sets
    // the starting values, so the user's choices are never reset.
    if (_initialized) return;
    _initialized = true;
    if (widget.block case final block?) {
      _start = block.startMinute;
      _end = block.endMinute;
      return;
    }
    final controller = PlannerScope.of(context);
    final isToday = widget.date == controller.today;
    _start = suggestedStart(
      controller.blocksOn(widget.date),
      nowMinute: isToday ? controller.clock.minuteOfDay() : null,
    );
    _end = (_start + _defaultMinutes).clamp(_start + 1, Duration.minutesPerDay);
    _periodId ??= switch (controller.goalsOn(widget.date)) {
      [final first, ...] => first.period.id,
      _ => null,
    };
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (current ~/ Duration.minutesPerHour) % 24,
        minute: current % Duration.minutesPerHour,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final minute = picked.hour * Duration.minutesPerHour + picked.minute;
    setState(() {
      _error = null;
      if (start) {
        // Moving the start keeps the length, like dragging the block.
        final length = _end - _start;
        _start = minute;
        _end = (minute + length).clamp(minute + 1, Duration.minutesPerDay);
      } else {
        // 00:00 as an end means midnight at the end of the day.
        _end = minute == 0 ? Duration.minutesPerDay : minute;
      }
    });
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    if (_end <= _start) {
      setState(() => _error = l.blockErrorTime);
      return;
    }
    if (_kind == TimeBlockKind.goal && _periodId == null) {
      setState(() => _error = l.blockErrorGoal);
      return;
    }
    if (_kind == TimeBlockKind.other && _title.text.trim().isEmpty) {
      setState(() => _error = l.blockErrorTitle);
      return;
    }
    final block = TimeBlock(
      id: widget.block?.id ?? generateUuidV4(),
      date: widget.date,
      startMinute: _start,
      endMinute: _end,
      kind: _kind,
      goalPeriodId: _kind == TimeBlockKind.goal ? _periodId : null,
      title: _kind == TimeBlockKind.other ? _title.text : null,
      remind: _remind,
    );
    try {
      controller.saveBlock(block);
    } on BlockRejectedException catch (e) {
      setState(
        () => _error = switch (e.reason) {
          BlockRejection.overlaps => l.blockErrorOverlap(
            formatMinuteOfDay(e.other!.startMinute),
            formatMinuteOfDay(e.other!.endMinute),
          ),
          BlockRejection.pastDay => l.blockErrorPast,
          BlockRejection.outsidePeriod => l.blockErrorOutside,
        },
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (block.goalPeriodId case final periodId?) {
      _offerToRaisePlan(messenger, l, controller, periodId);
    }
  }

  /// Plan and blocks stay separate but in step: when the day's blocks give
  /// a goal more time than its plan, offer (never force) to raise the plan.
  void _offerToRaisePlan(
    ScaffoldMessengerState messenger,
    AppLocalizations l,
    PlannerController controller,
    String periodId,
  ) {
    final planned = controller.allocatedOn(periodId, widget.date);
    final scheduled = controller.scheduledFor(periodId, widget.date);
    if (scheduled <= planned) return;
    final goal = controller.goalView(periodId).goal.title;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            l.blockRaisePlan(goal, l.minutes(planned), l.minutes(scheduled)),
          ),
          action: SnackBarAction(
            label: l.blockRaisePlanAction,
            onPressed: () {
              controller.updatePlan(periodId, {widget.date: scheduled});
              messenger.showSnackBar(
                SnackBar(content: Text(l.blockPlanRaised)),
              );
            },
          ),
        ),
      );
  }

  void _delete() {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final block = widget.block!;
    controller.deleteBlock(block.id);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.blockDeleted),
          action: SnackBarAction(
            label: l.undo,
            onPressed: () {
              try {
                controller.saveBlock(block);
              } on BlockRejectedException {
                // Its time was taken meanwhile: nothing to restore into.
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final goals = controller.goalsOn(widget.date);
    final remindersOn = controller.settings.reminders.enabled;
    final canRemind = ReminderScope.of(context).isSupported;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.block == null
                  ? l.blockEditorNewTitle
                  : l.blockEditorEditTitle,
              style: theme.textTheme.titleLarge,
            ),
            Text(
              formatDayLong(context, widget.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            SegmentedButton<TimeBlockKind>(
              segments: [
                ButtonSegment(
                  value: TimeBlockKind.goal,
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(l.blockKindGoal),
                ),
                ButtonSegment(
                  value: TimeBlockKind.rest,
                  icon: const Icon(Icons.coffee_outlined),
                  label: Text(l.blockKindRest),
                ),
                ButtonSegment(
                  value: TimeBlockKind.other,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(l.blockKindOther),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.single;
                _error = null;
              }),
            ),
            const SizedBox(height: AppSpacing.m),
            if (_kind == TimeBlockKind.goal)
              if (goals.isEmpty)
                Text(l.blockNoGoals)
              else
                DropdownButtonFormField<String>(
                  initialValue: goals.any((g) => g.period.id == _periodId)
                      ? _periodId
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.blockGoalLabel),
                  items: [
                    for (final g in goals)
                      DropdownMenuItem(
                        value: g.period.id,
                        child: Text(
                          g.goal.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _periodId = v;
                    _error = null;
                  }),
                ),
            if (_kind == TimeBlockKind.other)
              TextField(
                key: BlockEditorSheet.titleFieldKey,
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l.blockTitleLabel,
                  hintText: l.blockTitleHint,
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    key: BlockEditorSheet.startKey,
                    label: l.blockStartLabel,
                    minute: _start,
                    onTap: () => _pick(start: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _TimeButton(
                    key: BlockEditorSheet.endKey,
                    label: l.blockEndLabel,
                    minute: _end,
                    onTap: () => _pick(start: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final m in BlockEditorSheet.quickDurations)
                  ChoiceChip(
                    label: Text(l.minutes(m)),
                    selected: _end - _start == m,
                    onSelected: _start + m > Duration.minutesPerDay
                        ? null
                        : (_) => setState(() {
                            _end = _start + m;
                            _error = null;
                          }),
                  ),
              ],
            ),
            if (canRemind) ...[
              const SizedBox(height: AppSpacing.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.blockRemind),
                subtitle: Text(
                  remindersOn ? l.blockRemindBudget : l.blockRemindOff,
                ),
                value: _remind,
                onChanged: (v) => setState(() => _remind = v),
              ),
            ],
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s),
                child: Text(
                  error,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.m),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
              onPressed: _save,
              child: Text(l.save),
            ),
            if (widget.block != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(l.blockDelete),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.minute,
    required this.onTap,
    super.key,
  });

  final String label;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = formatMinuteOfDay(minute);
    return Semantics(
      button: true,
      label: '$label $time',
      excludeSemantics: true,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 60),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(time, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
