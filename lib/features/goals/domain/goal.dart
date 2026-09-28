/// How a goal behaves when things don't go to plan (CLAUDE.md §6).
enum GoalType {
  flexibleQuota,
  recurringRoutine,
  fixedTimeCritical,
  deadline;

  /// Only a flexible quota may have its shortfall moved to other days.
  /// Medication or prayer must never be "made up" by shifting it.
  bool get isRedistributable => this == flexibleQuota;
}

/// What a goal's numbers mean (CLAUDE.md §7). All values are integers;
/// durations are stored as whole minutes.
enum MeasurementType {
  durationMinutes,
  count,
  pages,
  boolean,
  sessions,
  dose,
  customNumeric;

  /// Only time-based goals use up the user's daily minute capacity.
  bool get consumesCapacity => this == durationMinutes;
}

/// The reusable definition of a goal ("Proje geliştirme, dakika, esnek").
/// Concrete targets live in [GoalPeriod]s.
class Goal {
  Goal({
    required this.id,
    required this.categoryId,
    required String title,
    required this.goalType,
    required this.measurementType,
    this.defaultTargetValue,
    this.isSensitive = false,
    this.isActive = true,
  }) : title = title.trim() {
    if (this.title.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Must not be empty');
    }
    if (measurementType == MeasurementType.dose &&
        goalType != GoalType.fixedTimeCritical) {
      throw ArgumentError('Dose goals must be fixed-time critical routines.');
    }
    if (defaultTargetValue case final value? when value <= 0) {
      throw ArgumentError.value(value, 'defaultTargetValue', 'Must be > 0');
    }
  }

  final String id;
  final String categoryId;
  final String title;
  final GoalType goalType;
  final MeasurementType measurementType;

  /// Target each new week starts with ("10 sa per week"). A carry-over adds
  /// to one week only and never changes this value.
  final int? defaultTargetValue;
  final bool isSensitive;

  /// False once archived: no new weeks are opened, history stays.
  final bool isActive;

  Goal withDefaultTarget(int value) => _copy(defaultTargetValue: value);

  Goal archived() => _copy(isActive: false);

  Goal _copy({int? defaultTargetValue, bool? isActive}) => Goal(
    id: id,
    categoryId: categoryId,
    title: title,
    goalType: goalType,
    measurementType: measurementType,
    defaultTargetValue: defaultTargetValue ?? this.defaultTargetValue,
    isSensitive: isSensitive,
    isActive: isActive ?? this.isActive,
  );
}
