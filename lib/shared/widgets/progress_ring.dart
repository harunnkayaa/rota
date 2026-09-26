import 'dart:math';

import 'package:flutter/material.dart';

/// Circular progress with content in the middle. Animates value changes,
/// unless the user asked the system to reduce motion.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    required this.child,
    this.size = 120,
    this.strokeWidth = 12,
    super.key,
  });

  /// 0..1; larger values are drawn as a full ring.
  final double value;
  final Widget child;
  final double size;
  final double strokeWidth;

  static const _animation = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: reduceMotion ? Duration.zero : _animation,
        curve: Curves.easeOutCubic,
        builder: (context, animated, child) => CustomPaint(
          painter: _RingPainter(
            value: animated,
            strokeWidth: strokeWidth,
            color: scheme.primary,
            trackColor: scheme.surfaceContainerHighest,
          ),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, 0, 2 * pi, false, paint..color = trackColor);
    if (value > 0) {
      canvas.drawArc(
        arcRect,
        -pi / 2,
        2 * pi * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
