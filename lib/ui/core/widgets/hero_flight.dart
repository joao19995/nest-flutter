import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/theme.dart';

/// A [Hero] flight shuttle showing a plain surface that fades from the list's
/// light card into the dark hero gradient (and back), so the motion reads well
/// in both directions without the complex hero content having to fit the
/// morphing rectangle mid-flight.
Widget heroSurfaceShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final surface = flightContext.colors.surface;
      final t = AppMotion.easing.transform(animation.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.heroFrom(surface, t),
          borderRadius: AppRadius.lgAll,
        ),
      );
    },
  );
}
