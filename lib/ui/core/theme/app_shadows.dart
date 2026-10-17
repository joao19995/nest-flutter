import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/app_colors.dart';

/// Nest shadow tokens. Never declare an inline `BoxShadow`.
abstract final class AppShadows {
  /// `shadow-card` — resting state for all cards and panels.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.08),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Elevated surface — dropdowns and popovers.
  static List<BoxShadow> get dropdown => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Maximum elevation — modals and sheets.
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AppColors.ink.withValues(alpha: 0.16),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
