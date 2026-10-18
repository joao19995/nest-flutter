import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/app_colors.dart';

/// Nest gradient tokens. Never declare an inline `LinearGradient`.
abstract final class AppGradients {
  /// The hero surface — deep ink sweeping into brand green, matching the
  /// web dashboard's dark hero band.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.ink, AppColors.primaryDark],
  );

  /// [hero] lerped in from [surface] as a Hero flight progresses: `t = 0` is
  /// [surface], `t = 1` is the full hero gradient. Used by the shared hero
  /// flight shuttle so the motion reads in both directions.
  static LinearGradient heroFrom(Color surface, double t) {
    final colors = hero.colors;
    return LinearGradient(
      begin: hero.begin,
      end: hero.end,
      colors: [
        Color.lerp(surface, colors[0], t) ?? surface,
        Color.lerp(surface, colors[1], t) ?? surface,
      ],
    );
  }
}
