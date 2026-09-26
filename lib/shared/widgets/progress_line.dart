import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/localization/formatters.dart';
import '../../app/theme/app_theme.dart';

/// "Bugün   1 sa 30 dk / 2 sa" with a bar underneath.
///
/// The numbers are always shown as text, so the bar colour is never the only
/// signal (CLAUDE.md §18).
class ProgressLine extends StatelessWidget {
  const ProgressLine({
    required this.label,
    required this.done,
    required this.target,
    this.emptyText,
    super.key,
  });

  final String label;
  final int done;

  /// Null means nothing is planned; [emptyText] is shown instead.
  final int? target;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final target = this.target;
    final valueText = target == null
        ? (emptyText ?? '')
        : l.progressOf(l.minutes(done), l.minutes(target));

    return Semantics(
      label: '$label: $valueText',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.labelLarge),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  valueText,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: target == null || target == 0
                ? 0
                : (done / target).clamp(0, 1).toDouble(),
          ),
        ],
      ),
    );
  }
}
