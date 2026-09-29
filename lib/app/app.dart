import 'dart:async';

import 'package:flutter/material.dart';

import '../features/planning/presentation/planner_controller.dart';
import '../features/reminders/data/reminder_scheduler.dart';
import '../features/reminders/presentation/reminder_sync.dart';
import '../features/sync/presentation/password_reset_sheet.dart';
import '../features/sync/presentation/sign_in_screen.dart';
import '../features/sync/presentation/sync_service.dart';
import 'home_shell.dart';
import 'localization/app_localizations.dart';
import 'theme/app_theme.dart';

class RotaApp extends StatefulWidget {
  const RotaApp({
    required this.controller,
    this.reminderScheduler = const NoopReminderScheduler(),
    this.syncService,
    super.key,
  });

  final PlannerController controller;
  final ReminderScheduler reminderScheduler;

  /// Null in tests and local-only builds: sync is shown as turned off.
  final SyncService? syncService;

  @override
  State<RotaApp> createState() => _RotaAppState();
}

/// Rechecks the date whenever the app comes back to the foreground, so a
/// phone left open overnight still starts the new day (and week) correctly.
class _RotaAppState extends State<RotaApp> with WidgetsBindingObserver {
  late final SyncService _sync =
      widget.syncService ?? SyncService.disabled(controller: widget.controller);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sync.appInForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshDay();
      // Another device may have changed something while we were away.
      unawaited(_sync.sync());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SyncScope(
      service: _sync,
      child: ReminderScope(
        scheduler: widget.reminderScheduler,
        child: PlannerScope(
          controller: widget.controller,
          child: MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _StartupGate(),
          ),
        ),
      ),
    );
  }
}

/// Shows the app only once saved data is loaded (otherwise a spinner or a
/// recoverable error) and, when the build has a server, someone is signed in.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final controller = PlannerScope.of(context);
    final sync = SyncScope.of(context);
    final needsSignIn = sync.status != SyncStatus.disabled && !sync.isSignedIn;
    return switch (controller.loadStatus) {
      LoadStatus.ready when needsSignIn => const SignInScreen(),
      LoadStatus.ready when sync.needsNewPassword => const NewPasswordScreen(),
      LoadStatus.ready => const HomeShell(),
      LoadStatus.loading => const _LoadingScreen(),
      LoadStatus.failed => _LoadFailedScreen(onRetry: controller.load),
    };
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          semanticsLabel: AppLocalizations.of(context).loadingLabel,
        ),
      ),
    );
  }
}

class _LoadFailedScreen extends StatelessWidget {
  const _LoadFailedScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: AppSpacing.xl * 2,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  l.loadFailedTitle,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(l.loadFailedBody, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.l),
                FilledButton(onPressed: onRetry, child: Text(l.retry)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
