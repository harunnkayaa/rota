import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Keeps page content readable on wide browser windows.
class ContentWidth extends StatelessWidget {
  const ContentWidth({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        // Full available width (up to the max), so content is left-aligned
        // instead of shrink-wrapped in the middle.
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
