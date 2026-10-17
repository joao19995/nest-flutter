import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A green check that pops in, holds briefly and fades out, driven by an
/// external [animation] (typically a controller run once per saved value).
class AppSavedTick extends StatelessWidget {
  const AppSavedTick({
    super.key,
    required this.animation,
    this.size = AppSizes.iconMedium,
  });

  /// A plain 0..1 animation; the widget maps it to opacity and scale.
  final Animation<double> animation;

  final double size;

  @override
  Widget build(BuildContext context) {
    final opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 63),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(animation);
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.1), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 13),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
    ]).animate(animation);
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Opacity(
          opacity: opacity.value,
          child: Transform.scale(scale: scale.value, child: child),
        ),
        child: Icon(
          Icons.check_circle,
          size: size,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
