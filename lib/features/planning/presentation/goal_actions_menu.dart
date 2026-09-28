import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import 'planner_controller.dart';

enum _GoalAction { archive }

/// The "⋮" menu on a goal card. Archiving asks for confirmation because
/// the goal leaves every daily screen.
class GoalActionsMenu extends StatelessWidget {
  const GoalActionsMenu({required this.view, super.key});

  final GoalProgressView view;

  Future<void> _archive(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.archiveConfirmTitle),
        content: Text(l.archiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.archiveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    controller.archiveGoal(view.goal.id);
    messenger.showSnackBar(SnackBar(content: Text(l.goalArchived)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopupMenuButton<_GoalAction>(
      tooltip: l.moreActions,
      onSelected: (action) => switch (action) {
        _GoalAction.archive => _archive(context),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _GoalAction.archive,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.archive_outlined),
            title: Text(l.archiveGoal),
          ),
        ),
      ],
    );
  }
}
