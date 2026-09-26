import 'package:flutter/material.dart';

import '../features/planning/presentation/planner_controller.dart';
import 'home_shell.dart';
import 'localization/app_localizations.dart';
import 'theme/app_theme.dart';

class RotaApp extends StatelessWidget {
  const RotaApp({required this.controller, super.key});

  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    return PlannerScope(
      controller: controller,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeShell(),
      ),
    );
  }
}
