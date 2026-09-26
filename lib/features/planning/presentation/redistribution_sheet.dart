import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/redistribution.dart';
import 'planner_controller.dart';

Future<void> showRedistributionSheet(BuildContext context, String periodId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RedistributionSheet(periodId: periodId),
  );
}

/// Shows the engine's proposal and its explanation. Nothing changes until
/// the user taps "Planı uygula" (CLAUDE.md §4.3).
class RedistributionSheet extends StatefulWidget {
  const RedistributionSheet({required this.periodId, super.key});

  final String periodId;

  @override
  State<RedistributionSheet> createState() => _RedistributionSheetState();
}

class _RedistributionSheetState extends State<RedistributionSheet> {
  var _strategy = RedistributionStrategy.even;
  var _includeToday = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final result = controller.proposeRedistributionFor(
      widget.periodId,
      strategy: _strategy,
      includeToday: _includeToday,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.redistributeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.m),
            SegmentedButton<RedistributionStrategy>(
              segments: [
                ButtonSegment(
                  value: RedistributionStrategy.even,
                  label: Text(l.strategyEven),
                ),
                ButtonSegment(
                  value: RedistributionStrategy.capacityWeighted,
                  label: Text(l.strategyCapacity),
                ),
              ],
              selected: {_strategy},
              onSelectionChanged: (s) => setState(() => _strategy = s.single),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.includeToday),
              value: _includeToday,
              onChanged: (v) => setState(() => _includeToday = v),
            ),
            const SizedBox(height: AppSpacing.s),
            ...switch (result) {
              RedistributionNotAllowed(:final reason) => [
                Text(switch (reason) {
                  NotAllowedReason.goalNotFlexible => l.notAllowedFixed,
                  NotAllowedReason.periodClosed => l.notAllowedClosed,
                  NotAllowedReason.nothingToRedistribute => l.notAllowedNothing,
                }),
              ],
              final RedistributionProposal p => _proposal(context, p),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _proposal(BuildContext context, RedistributionProposal p) {
    final l = AppLocalizations.of(context);
    final deficit = l.minutes(p.deficit);
    final explanation = switch (p) {
      _ when p.additions.isEmpty => l.redistributeNoDays(deficit),
      _ when p.isFeasible => l.redistributeFeasible(deficit),
      _ => l.redistributeInfeasible(
        deficit,
        l.minutes(p.totalFreeCapacity ?? 0),
        l.minutes(p.shortfall),
      ),
    };

    return [
      Text(explanation),
      const SizedBox(height: AppSpacing.s),
      for (final MapEntry(key: date, value: extra) in p.additions.entries)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_available_outlined),
          title: Text(formatDayLong(context, date)),
          trailing: Text(
            l.addition(l.minutes(extra)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      const SizedBox(height: AppSpacing.m),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          const SizedBox(width: AppSpacing.s),
          FilledButton(
            onPressed: p.additions.isEmpty ? null : () => _apply(p),
            child: Text(l.applyPlan),
          ),
        ],
      ),
    ];
  }

  void _apply(RedistributionProposal proposal) {
    final l = AppLocalizations.of(context);
    PlannerScope.of(context).applyProposal(widget.periodId, proposal);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l.planApplied)));
  }
}
