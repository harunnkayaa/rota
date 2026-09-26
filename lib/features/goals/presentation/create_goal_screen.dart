import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/localization/formatters.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/local_date.dart';
import '../../../shared/widgets/content_width.dart';
import '../../../shared/widgets/duration_stepper.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_style.dart';
import '../../planning/domain/distribution.dart';
import '../../planning/presentation/day_plan_editor.dart';
import '../../planning/presentation/planner_controller.dart';

Future<void> openCreateGoal(BuildContext context) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const CreateGoalScreen()));
}

/// Longest weekly target the form accepts: the whole week.
const _maxWeeklyMinutes = Duration.minutesPerDay * DateTime.daysPerWeek;

/// The weekly target moves in whole hours; days move in half hours.
const _weeklyStep = Duration.minutesPerHour;

const double _chipRowHeight = 48;

/// A flexible, minute-based weekly goal with a separate amount for every
/// day. Other goal and measurement types come with the full creation
/// wizard (CLAUDE.md §13.4).
class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  static const categoryRowKey = Key('createGoal.categoryRow');
  static const titleFieldKey = Key('createGoal.title');

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
  final _plan = <LocalDate, int>{};
  _CategoryChoice? _category;
  int _weeklyTarget = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  int get _planned => _plan.values.fold(0, (a, b) => a + b);

  bool get _targetValid =>
      _weeklyTarget > 0 && _weeklyTarget <= _maxWeeklyMinutes;

  List<LocalDate> _futureDays(PlannerController controller) => [
    for (final d in controller.currentWeek.days)
      if (!d.isBefore(controller.today)) d,
  ];

  void _distributeEvenly(PlannerController controller) {
    setState(() {
      _plan
        ..clear()
        ..addAll(distributeEvenly(_weeklyTarget, _futureDays(controller)));
    });
  }

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
    if (choice == null || _title.text.trim().isEmpty || !_targetValid) return;

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
      targetMinutes: _weeklyTarget,
      dailyPlan: Map.of(_plan),
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

    Widget errorText(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Text(text, style: TextStyle(color: theme.colorScheme.error)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.createGoalTitle)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.xl,
          ),
          children: [
            _Section(
              title: l.sectionCategory,
              children: [
                // One swipeable row keeps the form short on a phone.
                SizedBox(
                  height: _chipRowHeight,
                  // ~13 chips: build them all (no lazy list) so every chip
                  // can be scrolled to directly.
                  child: SingleChildScrollView(
                    key: CreateGoalScreen.categoryRowKey,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final chip in [
                          for (final c in existing)
                            _categoryChip(
                              c.name,
                              CategoryStyle.of(c),
                              _ExistingChoice(c),
                            ),
                          for (final p in PresetCategory.values)
                            if (!usedPresets.contains(p))
                              _categoryChip(
                                l.presetName(p),
                                CategoryStyle.forPreset(p),
                                _PresetChoice(p),
                              ),
                          ActionChip(
                            avatar: const Icon(Icons.add),
                            label: Text(l.newCategory),
                            onPressed: _addCustomCategory,
                          ),
                        ])
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: AppSpacing.s,
                            ),
                            child: chip,
                          ),
                      ],
                    ),
                  ),
                ),
                if (_submitted && _category == null)
                  errorText(l.errorPickCategory),
              ],
            ),
            _Section(
              title: l.sectionTitle,
              children: [
                TextField(
                  key: CreateGoalScreen.titleFieldKey,
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l.titleHint,
                    errorText: _submitted && _title.text.trim().isEmpty
                        ? l.errorTitleRequired
                        : null,
                  ),
                ),
              ],
            ),
            _Section(
              title: l.sectionWeeklyTarget,
              subtitle: l.weekTargetHint,
              children: [
                Center(
                  child: DurationStepper(
                    label: l.sectionWeeklyTarget,
                    value: _weeklyTarget,
                    step: _weeklyStep,
                    max: _maxWeeklyMinutes,
                    emphasized: true,
                    onChanged: (v) => setState(() => _weeklyTarget = v),
                  ),
                ),
                if (_submitted && !_targetValid)
                  errorText(l.errorTargetRequired),
              ],
            ),
            _Section(
              title: l.sectionDailyPlan,
              subtitle: l.dailyPlanHint,
              children: [
                // Nothing to compare until a target or a day is set.
                if (_weeklyTarget > 0 || _planned > 0) ...[
                  PlanSummary(planned: _planned, target: _weeklyTarget),
                  const SizedBox(height: AppSpacing.s),
                ],
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.auto_awesome_outlined),
                      label: Text(l.distributeEvenlyAction),
                      onPressed: _weeklyTarget == 0
                          ? null
                          : () => _distributeEvenly(controller),
                    ),
                    if (_planned > 0 && _planned != _weeklyTarget)
                      ActionChip(
                        avatar: const Icon(Icons.sync_alt),
                        label: Text(l.matchTargetToPlan),
                        onPressed: () =>
                            setState(() => _weeklyTarget = _planned),
                      ),
                    if (_planned > 0)
                      ActionChip(
                        avatar: const Icon(Icons.clear_all),
                        label: Text(l.clearPlan),
                        onPressed: () => setState(_plan.clear),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                DayPlanEditor(
                  // A new goal can't be planned into the past.
                  days: _futureDays(controller),
                  plan: _plan,
                  today: controller.today,
                  capacityOn: controller.capacity.capacityOn,
                  otherPlannedOn: controller.plannedOnExcluding,
                  onChanged: (day, minutes) =>
                      setState(() => _plan[day] = minutes),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.m,
          ),
          // heightFactor 1: the bar hugs the button instead of filling the
          // screen (a bare Align would hide the whole form).
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l.createGoalSubmit),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(
    String label,
    CategoryStyle style,
    _CategoryChoice choice,
  ) => ChoiceChip(
    avatar: Icon(style.icon, color: style.color),
    label: Text(label),
    selected: _category == choice,
    onSelected: (_) => setState(() => _category = choice),
  );
}

/// A titled card that groups one step of the form.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle case final subtitle?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.m),
              ...children,
            ],
          ),
        ),
      ),
    );
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
