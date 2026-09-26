import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../planning/domain/progress_calculator.dart';
import '../../planning/presentation/planner_controller.dart';

Future<void> showAddProgressSheet(BuildContext context, GoalProgressView view) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AddProgressSheet(view: view),
  );
}

/// Quick progress entry: one tap on a preset, or type minutes.
/// Target: under 10 seconds (CLAUDE.md §28).
class AddProgressSheet extends StatefulWidget {
  const AddProgressSheet({required this.view, super.key});

  final GoalProgressView view;

  static const quickMinutes = [15, 30, 45, 60];

  @override
  State<AddProgressSheet> createState() => _AddProgressSheetState();
}

class _AddProgressSheetState extends State<AddProgressSheet> {
  final _minutes = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final minutes = int.tryParse(_minutes.text);
    if (minutes == null || minutes < 1 || minutes > Duration.minutesPerDay) {
      setState(() => _error = l.errorMinutesInvalid);
      return;
    }
    try {
      PlannerScope.of(context).addProgress(widget.view.period.id, minutes);
    } on ProgressRejectedException catch (e) {
      setState(
        () => _error = switch (e.reason) {
          ProgressRejection.periodClosed => l.errorPeriodClosed,
          ProgressRejection.dateOutsidePeriod => l.errorDateOutside,
          _ => l.errorProgressGeneric,
        },
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(l.progressAdded(l.minutes(minutes)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          Text(
            l.addProgressTitle(widget.view.goal.title),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final m in AddProgressSheet.quickMinutes)
                ChoiceChip(
                  label: Text(l.addition(l.minutes(m))),
                  selected: _minutes.text == '$m',
                  onSelected: (_) => setState(() {
                    _minutes.text = '$m';
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l.customMinutesLabel,
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}
