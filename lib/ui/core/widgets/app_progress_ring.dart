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
  });

  /// How much of the ring is filled, as a 0..1 fraction.
  final double progress;

  /// Optional text centred inside the ring.
  final String? label;

  /// Colour of the filled arc.
  final Color color;

  /// Colour of the unfilled track.
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.progressRing,
      height: AppSizes.progressRing,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: AppMotion.large,
        curve: AppMotion.easing,
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(AppSizes.progressRing),
              painter: _RingPainter(
                value: value,
                color: color,
                trackColor: trackColor,
              ),
            ),
            if (label != null)
              Text(
                label!,
                style: AppTextStyles.label(
                  context.colors,
                ).copyWith(color: AppColors.onHero),
              ),
          ],
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
  });

  final double value;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppSizes.progressRingStroke;
    final rect =
        const Offset(stroke / 2, stroke / 2) &
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
      oldDelegate.trackColor != trackColor;
}
