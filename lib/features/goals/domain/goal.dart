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
  }

  final String id;
  final String categoryId;
  final String title;
  final GoalType goalType;
  final MeasurementType measurementType;
  final bool isSensitive;
  final bool isActive;
}
