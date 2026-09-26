/// A user-owned grouping for goals (e.g. "Proje geliştirme").
class GoalCategory {
  GoalCategory({
    required this.id,
    required String name,
    required this.iconKey,
    this.preset,
    this.isSensitive = false,
    this.isArchived = false,
  }) : name = name.trim() {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty');
    }
  }

  final String id;
  final String name;
  final String iconKey;

  /// Set when the category was created from a ready-made one; lets the UI
  /// avoid creating the same preset twice.
  final PresetCategory? preset;

  /// Health and worship data: hidden from lock-screen notification texts.
  final bool isSensitive;

  /// Archived categories stay in history and reports; they are never deleted.
  final bool isArchived;
}

/// Ready-made categories offered during goal creation (CLAUDE.md §9.2).
///
/// Display names live in the localization layer; the user gets their own
/// editable copy when they pick one.
enum PresetCategory {
  work,
  jobApplication,
  interview,
  projectDevelopment,
  graduateStudy,
  language,
  reading,
  sport,
  healthMedication,
  brainTraining,
  worship,
  personal;

  bool get isSensitive => this == healthMedication || this == worship;
}
