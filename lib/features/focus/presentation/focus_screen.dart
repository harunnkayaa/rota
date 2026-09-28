import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../categories/presentation/category_style.dart';
import '../../planning/domain/progress_calculator.dart';
import '../../planning/presentation/planner_controller.dart';

/// Starts a focus session for [periodId] (if none is running) and opens the
/// timer. Another goal's running session is reported instead of replaced.
Future<void> openFocus(BuildContext context, String periodId) async {
  final l = AppLocalizations.of(context);
  final controller = PlannerScope.of(context);
  final running = controller.activeFocus;
  if (running != null && running.goalPeriodId != periodId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.focusAnotherRunning)));
    return;
  }
  if (running == null) controller.startFocus(periodId);
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const FocusScreen()));
}

/// The running timer. The time shown is recomputed from timestamps every
/// second; closing the app does not stop or lose the session.
class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late final Timer _ticker;
  String? _error;

  /// The ring completes once per hour, like a clock face.
  static const _ringPeriod = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _finish() {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final int minutes;
    try {
      minutes = controller.finishFocus();
    } on ProgressRejectedException {
      setState(() => _error = l.focusPeriodEnded);
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          minutes == 0 ? l.focusTooShort : l.focusRecorded(l.minutes(minutes)),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.focusCancelConfirmTitle),
        content: Text(l.focusCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.focusCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    controller.cancelFocus();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final session = controller.activeFocus;
    if (session == null) {
      // Finished or cancelled elsewhere (another tab, a restore).
      return Scaffold(appBar: AppBar(title: Text(l.focusTitle)));
    }
    final view = controller.goalView(session.goalPeriodId);
    final elapsed = session.elapsed(controller.clock.nowUtc());
    final timeText = formatTimer(elapsed);
    final category = view.category;

    return Scaffold(
      appBar: AppBar(title: Text(l.focusTitle)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            Row(
              children: [
                CategoryAvatar(style: CategoryStyle.of(category)),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(view.goal.title, style: theme.textTheme.titleLarge),
                      Text(category.name, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Semantics(
                label: l.focusTimerSemantics(timeText),
                liveRegion: false,
                excludeSemantics: true,
                child: ProgressRing(
                  size: 240,
                  strokeWidth: 14,
                  value:
                      (elapsed.inSeconds % _ringPeriod.inSeconds) /
                      _ringPeriod.inSeconds,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeText,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (session.isPaused)
                        Text(
                          l.focusPaused,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              '${l.todayLabel}: ${l.progressOf(l.minutes(view.todayDone + session.workedMinutes(controller.clock.nowUtc())), l.minutes(view.todayAllocated ?? 0))}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (_error case final error?) ...[
              const SizedBox(height: AppSpacing.m),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
              onPressed: session.isPaused
                  ? controller.resumeFocus
                  : controller.pauseFocus,
              icon: Icon(session.isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(session.isPaused ? l.focusResume : l.focusPause),
            ),
            const SizedBox(height: AppSpacing.m),
            FilledButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.check),
              label: Text(l.focusFinish),
            ),
            const SizedBox(height: AppSpacing.s),
            TextButton(onPressed: _cancel, child: Text(l.focusCancel)),
          ],
        ),
      ),
    );
  }
}

/// A slim bar on Today while a session runs, so it is never forgotten.
class FocusRunningBanner extends StatefulWidget {
  const FocusRunningBanner({super.key});

  @override
  State<FocusRunningBanner> createState() => _FocusRunningBannerState();
}

class _FocusRunningBannerState extends State<FocusRunningBanner> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final controller = PlannerScope.of(context);
    final session = controller.activeFocus!;
    final view = controller.goalView(session.goalPeriodId);
    return Card(
      color: scheme.primary,
      child: ListTile(
        leading: Icon(
          session.isPaused ? Icons.pause_circle : Icons.timer,
          color: scheme.onPrimary,
        ),
        title: Text(
          '${l.focusRunning} · ${view.goal.title}',
          style: TextStyle(color: scheme.onPrimary),
        ),
        subtitle: Text(
          formatTimer(session.elapsed(controller.clock.nowUtc())),
          style: TextStyle(
            color: scheme.onPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        trailing: TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.onPrimary),
          onPressed: () => openFocus(context, session.goalPeriodId),
          child: Text(l.focusOpen),
        ),
      ),
    );
  }
}
