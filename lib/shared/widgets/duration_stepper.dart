import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/localization/formatters.dart';
import '../../app/theme/app_theme.dart';

/// "− 2 sa 30 dk +" : quick steps with the buttons, exact value by tapping
/// the number. Built for one-handed use on a phone.
class DurationStepper extends StatelessWidget {
  const DurationStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 30,
    this.max = Duration.minutesPerDay,
    this.emphasized = false,
    super.key,
  });

  /// What is being edited ("Pzt 28 Eyl"); used by screen readers and as the
  /// title of the exact-value sheet.
  final String label;
  final int value;

  /// Null disables the control.
  final ValueChanged<int>? onChanged;
  final int step;
  final int max;

  /// Bigger number, for the one main value on a screen.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onChanged = this.onChanged;
    final stepText = l.minutes(step);
    final valueText = l.minutes(value);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: l.decreaseBy(stepText),
          onPressed: onChanged == null || value == 0
              ? null
              : () => onChanged((value - step).clamp(0, max)),
          icon: const Icon(Icons.remove),
        ),
        Flexible(
          child: Semantics(
            button: true,
            label: l.durationFieldSemantics(label, valueText),
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppLayout.controlRadius),
              onTap: onChanged == null
                  ? null
                  : () async {
                      final picked = await showDurationInputSheet(
                        context,
                        title: l.durationSheetTitle(label),
                        initial: value,
                        max: max,
                      );
                      if (picked != null) onChanged(picked);
                    },
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: emphasized ? 140 : 92),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.s,
                  ),
                  child: Text(
                    valueText,
                    textAlign: TextAlign.center,
                    style:
                        (emphasized
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.titleMedium)
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: value == 0
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: l.increaseBy(stepText),
          onPressed: onChanged == null || value >= max
              ? null
              : () => onChanged((value + step).clamp(0, max)),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Exact hours + minutes entry. Returns null when dismissed.
Future<int?> showDurationInputSheet(
  BuildContext context, {
  required String title,
  required int initial,
  required int max,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _DurationInputSheet(title: title, initial: initial, max: max),
  );
}

class _DurationInputSheet extends StatefulWidget {
  const _DurationInputSheet({
    required this.title,
    required this.initial,
    required this.max,
  });

  final String title;
  final int initial;
  final int max;

  @override
  State<_DurationInputSheet> createState() => _DurationInputSheetState();
}

class _DurationInputSheetState extends State<_DurationInputSheet> {
  late final _hours = TextEditingController(
    text: '${widget.initial ~/ Duration.minutesPerHour}',
  );
  late final _minutes = TextEditingController(
    text: '${widget.initial % Duration.minutesPerHour}',
  );
  String? _error;

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _save() {
    final l = AppLocalizations.of(context);
    final total =
        (int.tryParse(_hours.text) ?? 0) * Duration.minutesPerHour +
        (int.tryParse(_minutes.text) ?? 0);
    if (total > widget.max) {
      setState(() => _error = l.errorDurationMax(l.minutes(widget.max)));
      return;
    }
    Navigator.of(context).pop(total);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget field(
      TextEditingController c,
      String label, {
      bool autofocus = false,
    }) => TextField(
      controller: c,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      onSubmitted: (_) => _save(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(child: field(_hours, l.hoursLabel, autofocus: true)),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: field(_minutes, l.minutesLabel)),
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
    );
  }
}
