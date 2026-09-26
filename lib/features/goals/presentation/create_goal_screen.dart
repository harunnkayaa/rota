import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/local_date.dart';
import '../../../shared/widgets/content_width.dart';
import '../../categories/domain/category.dart';
import '../../planning/domain/distribution.dart';
import '../../planning/presentation/planner_controller.dart';

Future<void> openCreateGoal(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CreateGoalScreen()));
}

/// Longest weekly target the form accepts: the whole week.
const _maxWeeklyMinutes = Duration.minutesPerDay * DateTime.daysPerWeek;

/// Phase 1 slice: a flexible, minute-based weekly goal for the current week,
/// split evenly over the chosen days. Other goal and measurement types come
/// with the full creation wizard (CLAUDE.md §13.4).
class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

/// Either a ready-made category or one the user already has.
sealed class _CategoryChoice {
  const _CategoryChoice();
}

final class _PresetChoice extends _CategoryChoice {
  const _PresetChoice(this.preset);
  final PresetCategory preset;

  @override
  bool operator ==(Object other) =>
      other is _PresetChoice && other.preset == preset;

  @override
  int get hashCode => preset.hashCode;
}

final class _ExistingChoice extends _CategoryChoice {
  const _ExistingChoice(this.category);
  final GoalCategory category;

  @override
  bool operator ==(Object other) =>
      other is _ExistingChoice && other.category.id == category.id;

  @override
  int get hashCode => category.id.hashCode;
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _title = TextEditingController();
  final _hours = TextEditingController();
  final _minutes = TextEditingController();
  _CategoryChoice? _category;
  Set<LocalDate>? _initialDays;
  Set<LocalDate> get _days => _initialDays!;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refresh);
    _hours.addListener(_refresh);
    _minutes.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs again whenever the controller notifies; keep the user's choice.
    if (_initialDays != null) return;
    // Past days of the week cannot receive new work; preselect the rest.
    final controller = PlannerScope.of(context);
    _initialDays = {
      for (final d in controller.currentWeek.days)
        if (!d.isBefore(controller.today)) d,
    };
  }

  @override
  void dispose() {
    _title.dispose();
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  int get _targetMinutes =>
      (int.tryParse(_hours.text) ?? 0) * Duration.minutesPerHour +
      (int.tryParse(_minutes.text) ?? 0);

  bool get _targetValid =>
      _targetMinutes > 0 && _targetMinutes <= _maxWeeklyMinutes;

  List<LocalDate> get _sortedDays => _days.toList()..sort();

  Future<void> _addCustomCategory() async {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NewCategoryDialog(title: l.newCategory),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final category = controller.addCategory(name);
    setState(() => _category = _ExistingChoice(category));
  }

  void _submit() {
    final l = AppLocalizations.of(context);
    setState(() => _submitted = true);
    final choice = _category;
    if (choice == null ||
        _title.text.trim().isEmpty ||
        !_targetValid ||
        _days.isEmpty) {
      return;
    }
    final controller = PlannerScope.of(context);
    final category = switch (choice) {
      _PresetChoice(:final preset) => controller.addCategory(
        l.presetName(preset),
        preset: preset,
      ),
      _ExistingChoice(:final category) => category,
    };
    controller.createWeeklyDurationGoal(
      categoryId: category.id,
      title: _title.text,
      targetMinutes: _targetMinutes,
      dailyPlan: distributeEvenly(_targetMinutes, _sortedDays),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l.goalCreated)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = PlannerScope.of(context);
    final existing = controller.categories;
    final usedPresets = {for (final c in existing) c.preset};

    Widget section(String title, {String? error}) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.l, bottom: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (_submitted && error != null)
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.createGoalTitle)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.xl,
          ),
          children: [
            section(
              l.sectionCategory,
              error: _category == null ? l.errorPickCategory : null,
            ),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final c in existing)
                  _categoryChip(c.name, _ExistingChoice(c)),
                for (final p in PresetCategory.values)
                  if (!usedPresets.contains(p))
                    _categoryChip(l.presetName(p), _PresetChoice(p)),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: Text(l.newCategory),
                  onPressed: _addCustomCategory,
                ),
              ],
            ),
            section(l.sectionTitle),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l.titleHint,
                border: const OutlineInputBorder(),
                errorText: _submitted && _title.text.trim().isEmpty
                    ? l.errorTitleRequired
                    : null,
              ),
            ),
            section(
              l.sectionTarget,
              error: _targetValid ? null : l.errorTargetRequired,
            ),
            Row(
              children: [
                Expanded(child: _numberField(_hours, l.hoursLabel)),
                const SizedBox(width: AppSpacing.m),
                Expanded(child: _numberField(_minutes, l.minutesLabel)),
              ],
            ),
            section(
              l.sectionDays,
              error: _days.isEmpty ? l.errorPickDays : null,
            ),
            Text(l.daysHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final d in controller.currentWeek.days)
                  FilterChip(
                    label: Text(formatDayShort(context, d)),
                    selected: _days.contains(d),
                    onSelected: d.isBefore(controller.today)
                        ? null
                        : (on) => setState(
                            () => on ? _days.add(d) : _days.remove(d),
                          ),
                  ),
              ],
            ),
            if (_targetValid && _days.isNotEmpty) ...[
              section(l.sectionPreview),
              _PlanPreview(plan: distributeEvenly(_targetMinutes, _sortedDays)),
            ],
            const SizedBox(height: AppSpacing.l),
            FilledButton(onPressed: _submit, child: Text(l.createGoalSubmit)),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, _CategoryChoice choice) => ChoiceChip(
    label: Text(label),
    selected: _category == choice,
    onSelected: (_) => setState(() => _category = choice),
  );

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
}

/// Per-day share, with a warning where the day's capacity would be exceeded.
class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.plan});

  final Map<LocalDate, int> plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = PlannerScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            for (final MapEntry(key: day, value: minutes) in plan.entries) ...[
              Row(
                children: [
                  Expanded(child: Text(formatDayShort(context, day))),
                  Text(l.minutes(minutes)),
                ],
              ),
              if (_overBy(controller, day, minutes) case final over
                  when over > 0)
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l.capacityWarningDay(
                          formatDayShort(context, day),
                          l.minutes(over),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  int _overBy(PlannerController controller, LocalDate day, int minutes) {
    final check = controller.capacityOn(day);
    return check.planned + minutes - check.capacity;
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog({required this.title});

  final String title;

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(labelText: l.newCategoryName),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_name.text),
          child: Text(l.save),
        ),
      ],
    );
  }
}
