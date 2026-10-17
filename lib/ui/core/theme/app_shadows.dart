import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/nest_colors.dart';

/// Nest shadow tokens. Never declare an inline `BoxShadow`.
abstract final class AppShadows {
  /// `shadow-card` — resting state for all cards and panels.
  ///
  /// Two layers: a tight contact shadow plus a soft, diffuse one for depth.
  static List<BoxShadow> card(NestColors colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Elevated surface — dropdowns and popovers.
  static List<BoxShadow> dropdown(NestColors colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Maximum elevation — modals and sheets.
  static List<BoxShadow> elevated(NestColors colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.16),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
