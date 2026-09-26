import 'package:flutter/material.dart';

import '../features/goals/presentation/create_goal_screen.dart';
import '../features/planning/presentation/week_screen.dart';
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

  static const _pages = [TodayScreen(), WeekScreen()];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= AppLayout.wideBreakpoint;
    final page = _pages[_index];

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
                NavigationRailDestination(
                  icon: const Icon(Icons.today_outlined),
                  selectedIcon: const Icon(Icons.today),
                  label: Text(l.navToday),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.view_week_outlined),
                  selectedIcon: const Icon(Icons.view_week),
                  label: Text(l.navWeek),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openCreateGoal(context),
        icon: const Icon(Icons.add),
        label: Text(l.addGoal),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_week_outlined),
            selectedIcon: const Icon(Icons.view_week),
            label: l.navWeek,
          ),
        ],
      ),
    );
  }
}
