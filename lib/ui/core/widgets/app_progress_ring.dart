import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A circular progress ring drawn with a [CustomPainter] — no dependency.
///
/// The swept value is animated in on first paint. [progress] is a 0..1
/// fraction; anything above 1 fills the ring completely.
class AppProgressRing extends StatelessWidget {
  const AppProgressRing({
    super.key,
    required this.progress,
    this.label,
    this.color = AppColors.mint,
    this.trackColor = AppColors.heroPill,
    this.size = AppSizes.progressRing,
    this.strokeWidth = AppSizes.progressRingStroke,
    this.labelStyle,
    this.labelColor,
  });

  /// How much of the ring is filled, as a 0..1 fraction.
  final double progress;

  /// Optional text centred inside the ring.
  final String? label;

  /// Colour of the filled arc.
  final Color color;

  /// Colour of the unfilled track.
  final Color trackColor;

  /// Diameter of the ring.
  final double size;

  /// Width of the painted arc.
  final double strokeWidth;

  /// Base label style; defaults to the theme label.
  final TextStyle? labelStyle;

  /// Label colour; defaults to [AppColors.onHero].
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    final labelStyle = this.labelStyle ?? AppTextStyles.label(context.colors);
    return Semantics(
      label: label,
      value: '${(progress.clamp(0.0, 1.0) * 100).round()}%',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: AppMotion.large,
            curve: AppMotion.easing,
            builder: (context, value, _) => Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _RingPainter(
                    value: value,
                    color: color,
                    trackColor: trackColor,
                    strokeWidth: strokeWidth,
                  ),
                ),
                if (label != null)
                  Text(
                    label,
                    style: labelStyle.copyWith(
                      color: labelColor ?? AppColors.onHero,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);
    if (value <= 0) {
      return;
    }
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
