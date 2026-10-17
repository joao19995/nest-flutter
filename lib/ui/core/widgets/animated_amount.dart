import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A currency amount that counts up from zero the first time it appears.
///
/// Mirrors the web hero figure: a short, single-shot tween that gives the
/// headline number a sense of arrival without any extra dependencies.
class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({super.key, required this.value, this.style});

  /// The target value, in euros.
  final double value;

  /// Applied to the rendered amount; typically `AppTextStyles.statDisplay`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: AppMotion.large,
      curve: AppMotion.easing,
      builder: (context, current, _) =>
          Text(AppFormatters.currency(current), style: style),
    );
  }
}
