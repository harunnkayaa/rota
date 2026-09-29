import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import 'create_goal_screen.dart';

/// "Hedef ekle" in the title bar of the planning screens. Adding a goal is
/// a weekly action, so it sits at the top and leaves the thumb area to the
/// daily ones (progress, focus).
class AddGoalButton extends StatelessWidget {
  const AddGoalButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: () => openCreateGoal(context),
      icon: const Icon(Icons.add),
      label: Text(AppLocalizations.of(context).addGoal),
    );
  }
}
