import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/localization/formatters.dart';
import '../../app/theme/app_theme.dart';

/// Neutral note about uncovered target minutes, with a way to re-plan.
/// Informative, not punitive: no red, no "failed".
class DebtNotice extends StatelessWidget {
  const DebtNotice({
    required this.amount,
    required this.onRedistribute,
    super.key,
  });

  final int amount;
  final VoidCallback onRedistribute;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.s),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.s,
                right: AppSpacing.s,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      l.goalDebt(l.minutes(amount)),
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRedistribute,
                child: Text(l.redistribute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
