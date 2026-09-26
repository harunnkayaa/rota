import 'package:flutter/material.dart';

import '../domain/category.dart';

/// Icon and accent colour for a category. The colour is decoration only:
/// the category name is always shown next to it (CLAUDE.md §18).
@immutable
class CategoryStyle {
  const CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static CategoryStyle of(GoalCategory category) {
    final preset = category.preset;
    if (preset != null) return forPreset(preset);
    return _custom[category.id.hashCode.abs() % _custom.length];
  }

  static CategoryStyle forPreset(PresetCategory preset) => switch (preset) {
    PresetCategory.work => const CategoryStyle(
      Icons.work_outline,
      Color(0xFF6366F1),
    ),
    PresetCategory.jobApplication => const CategoryStyle(
      Icons.send_outlined,
      Color(0xFF0EA5E9),
    ),
    PresetCategory.interview => const CategoryStyle(
      Icons.record_voice_over_outlined,
      Color(0xFFF59E0B),
    ),
    PresetCategory.projectDevelopment => const CategoryStyle(
      Icons.code,
      Color(0xFF14B8A6),
    ),
    PresetCategory.graduateStudy => const CategoryStyle(
      Icons.school_outlined,
      Color(0xFF8B5CF6),
    ),
    PresetCategory.language => const CategoryStyle(
      Icons.translate,
      Color(0xFF3B82F6),
    ),
    PresetCategory.reading => const CategoryStyle(
      Icons.menu_book_outlined,
      Color(0xFFD97706),
    ),
    PresetCategory.sport => const CategoryStyle(
      Icons.fitness_center,
      Color(0xFF22C55E),
    ),
    PresetCategory.healthMedication => const CategoryStyle(
      Icons.medication_outlined,
      Color(0xFFEC4899),
    ),
    PresetCategory.brainTraining => const CategoryStyle(
      Icons.psychology_outlined,
      Color(0xFFF97316),
    ),
    PresetCategory.worship => const CategoryStyle(
      Icons.self_improvement,
      Color(0xFF10B981),
    ),
    PresetCategory.personal => const CategoryStyle(
      Icons.person_outline,
      Color(0xFF64748B),
    ),
  };

  static const _custom = [
    CategoryStyle(Icons.label_outline, Color(0xFF06B6D4)),
    CategoryStyle(Icons.label_outline, Color(0xFFA855F7)),
    CategoryStyle(Icons.label_outline, Color(0xFFEAB308)),
    CategoryStyle(Icons.label_outline, Color(0xFFF43F5E)),
  ];
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({required this.style, this.size = 44, super.key});

  final CategoryStyle style;
  final double size;

  static const _iconRatio = 0.55;
  static const _backgroundAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: _backgroundAlpha),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(style.icon, color: style.color, size: size * _iconRatio),
      ),
    );
  }
}
