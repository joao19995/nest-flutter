import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/app_colors.dart';

/// A background/foreground pair (with an optional border) for a status badge.
typedef BadgeStyle = ({Color background, Color foreground, Color? border});

/// Nest status-badge colour pairs — mirrored from the web `Badge` variants.
///
/// No badge may define its own colours; always use one of these.
abstract final class AppBadgeStyles {
  /// Open / ok state (web: `open`).
  static const BadgeStyle open = (
    background: AppColors.mintSoft,
    foreground: AppColors.primaryDark,
    border: null,
  );

  /// Closed / settled state (web: `closed`).
  static const BadgeStyle closed = (
    background: AppColors.lineSoft,
    foreground: AppColors.inkSoft,
    border: null,
  );

  /// Neutral muted state (web: `muted`).
  static const BadgeStyle muted = (
    background: AppColors.lineSoft,
    foreground: AppColors.muted,
    border: null,
  );

  /// Outlined neutral state (web: `outline`).
  static const BadgeStyle outline = (
    background: AppColors.surface,
    foreground: AppColors.muted,
    border: AppColors.line,
  );

  /// Destructive / over-planned state (web: `destructive`).
  static const BadgeStyle destructive = (
    background: AppColors.dangerSoft,
    foreground: AppColors.dangerOnSoft,
    border: null,
  );
}
