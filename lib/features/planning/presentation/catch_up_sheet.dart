import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/duration_stepper.dart';
import '../domain/deadline_pace.dart';
import 'planner_controller.dart';

Future<void> showCatchUpSheet(BuildContext context, String periodId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CatchUpSheet(periodId: periodId),
  );
}

/// "Tempoyu yakala": fill this week's gap from free time, and — only for
/// goals the user switches on — from other goals' plans. The user can also
/// lower the total target. Nothing changes until "Planı uygula".
class CatchUpSheet extends StatefulWidget {
  const CatchUpSheet({required this.periodId, super.key});

  final String periodId;

  @override
  State<CatchUpSheet> createState() => _CatchUpSheetState();
}

class _CatchUpSheetState extends State<CatchUpSheet> {
  final _donors = <String>{};

  /// Upper bound for the total-target editor: 1000 hours.
  static const _maxTotal = 1000 * Duration.minutesPerHour;

  void _apply(CatchUpProposal proposal) {
    final l = AppLocalizations.of(context);
    PlannerScope.of(context).applyCatchUp(widget.periodId, proposal);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l.planApplied)));
  }

  Future<void> _changeTotal(DeadlinePace pace) async {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDurationInputSheet(
      context,
      title: l.changeTotalTarget,
      initial: pace.total,
      max: _maxTotal,
    );
    if (picked == null || picked <= 0 || !mounted) return;
    controller.updateTarget(widget.periodId, picked);
    messenger.showSnackBar(SnackBar(content: Text(l.targetUpdated)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final view = controller.goalView(widget.periodId);
    final pace = view.pace!;
    final donors = controller.catchUpDonors(widget.periodId);
    final proposal = controller.proposeCatchUpFor(
      widget.periodId,
      donorPeriodIds: _donors,
    );
    final titleOf = {for (final d in donors) d.period.id: d.goal.title};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.catchUpTitle, style: theme.textTheme.titleLarge),
          Text(view.goal.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.m),
          Text(
            pace.thisWeekGap == 0
                ? l.catchUpNothingNeeded
                : l.catchUpGap(l.minutes(pace.thisWeekGap)),
            style: theme.textTheme.titleMedium,
          ),
          if (pace.thisWeekGap > 0 && proposal.isEmpty && donors.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Text(l.catchUpNoDays),
            ),
          if (!proposal.isEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            _SourceRow(
              icon: Icons.event_available_outlined,
              label: l.catchUpFromFree,
              value: l.minutes(proposal.fromFreeCapacity),
            ),
            if (proposal.fromOtherGoals > 0)
              _SourceRow(
                icon: Icons.swap_horiz,
                label: l.catchUpFromOthers,
                value: l.minutes(proposal.fromOtherGoals),
              ),
            const Divider(height: AppSpacing.l),
            for (final MapEntry(key: day, value: extra)
                in (proposal.additions.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key))))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(formatDayLong(context, day)),
                subtitle: Text(
                  [
                    for (final MapEntry(key: donorId, value: byDay)
                        in proposal.reductions.entries)
                      if (byDay[day] case final taken?)
                        l.catchUpReduction(
                          titleOf[donorId] ?? '',
                          l.minutes(taken),
                        ),
                  ].join(' · '),
                ),
                trailing: Text(
                  l.addition(l.minutes(extra)),
                  style: theme.textTheme.titleMedium,
                ),
              ),
          ],
          if (proposal.shortfall > 0) ...[
            const SizedBox(height: AppSpacing.s),
            Text(l.catchUpShortfall(l.minutes(proposal.shortfall))),
          ],
          if (donors.isNotEmpty && pace.thisWeekGap > 0) ...[
            const SizedBox(height: AppSpacing.m),
            Text(l.catchUpDonorsTitle, style: theme.textTheme.titleSmall),
            Text(
              l.catchUpDonorsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final donor in donors)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(donor.goal.title),
                subtitle: Text(
                  l.catchUpDonorPlanned(
                    l.minutes(
                      donor.days
                          .where((d) => !d.date.isBefore(controller.today))
                          .fold(0, (sum, d) => sum + d.shortfall),
                    ),
                  ),
                ),
                value: _donors.contains(donor.period.id),
                onChanged: (on) => setState(
                  () => on
                      ? _donors.add(donor.period.id)
                      : _donors.remove(donor.period.id),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.s),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _changeTotal(pace),
              icon: const Icon(Icons.tune),
              label: Text(l.changeTotalTarget),
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
                  onPressed: proposal.isEmpty ? null : () => _apply(proposal),
                  child: Text(l.applyPlan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.s),
          Expanded(child: Text(label)),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
