import 'package:flutter/material.dart';

import '../features/goals/presentation/create_goal_screen.dart';
import '../features/planning/presentation/planner_controller.dart';
import '../features/planning/presentation/week_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/today/presentation/today_screen.dart';
import 'localization/app_localizations.dart';
import 'theme/app_theme.dart';

/// Bottom navigation on phones, a side rail on wide screens (web/tablet).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _pages = [
    TodayScreen(),
    WeekScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  /// "Add goal" belongs to the planning screens only.
  bool get _showAddGoal => _index <= 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= AppLayout.wideBreakpoint;
    final saveFailed = PlannerScope.of(context).saveStatus == SaveStatus.failed;
    final page = Column(
      children: [
        if (saveFailed) const _SaveFailedBanner(),
        Expanded(child: _pages[_index]),
      ],
    );
    final destinations = [
      (Icons.today_outlined, Icons.today, l.navToday),
      (Icons.view_week_outlined, Icons.view_week, l.navWeek),
      (Icons.insights_outlined, Icons.insights, l.navReports),
      (Icons.tune_outlined, Icons.tune, l.navSettings),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: FloatingActionButton(
                  tooltip: l.addGoal,
                  onPressed: () => openCreateGoal(context),
                  child: const Icon(Icons.add),
                ),
              ),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: page),
          ],
        ),
      );
    }

    return Scaffold(
      body: page,
      floatingActionButton: _showAddGoal
          ? FloatingActionButton.extended(
              onPressed: () => openCreateGoal(context),
              icon: const Icon(Icons.add),
              label: Text(l.addGoal),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(
              icon: Icon(icon),
              selectedIcon: Icon(selected),
              label: label,
            ),
        ],
      ),
    );
  }
}

/// Data the user just entered is still on screen but not on disk; say so
/// and offer a retry instead of failing silently.
class _SaveFailedBanner extends StatelessWidget {
  const _SaveFailedBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Material(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Row(
            children: [
              Icon(Icons.sync_problem, color: scheme.onErrorContainer),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  l.saveFailed,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
              TextButton(
                onPressed: PlannerScope.of(context).retrySave,
                child: Text(l.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
