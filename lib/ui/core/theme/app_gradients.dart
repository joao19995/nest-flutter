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
}
