import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/app_colors.dart';
import 'package:nest/ui/core/theme/nest_colors.dart';

/// A background/foreground pair (with an optional border) for a status badge.
typedef BadgeStyle = ({Color background, Color foreground, Color? border});

/// Nest status-badge colour pairs.
///
/// The themed variants take the active [NestColors]; the `*OnHero` variants
/// are fixed for the always-dark hero.
abstract final class AppBadgeStyles {
  /// Open / ok state.
  static BadgeStyle open(NestColors colors) => (
    background: colors.mintSoft,
    foreground: colors.primaryDark,
    border: null,
  );

  /// Closed / settled state.
  static BadgeStyle closed(NestColors colors) =>
      (background: colors.lineSoft, foreground: colors.inkSoft, border: null);

  /// Neutral muted state.
  static BadgeStyle muted(NestColors colors) =>
      (background: colors.lineSoft, foreground: colors.muted, border: null);

  /// Outlined neutral state.
  static BadgeStyle outline(NestColors colors) => (
    background: colors.surface,
    foreground: colors.muted,
    border: colors.line,
  );

  /// Destructive / over-planned state.
  static BadgeStyle destructive(NestColors colors) => (
    background: colors.dangerSoft,
    foreground: colors.dangerOnSoft,
    border: null,
  );

  /// Open / ok state, for the dark gradient hero.
  static const BadgeStyle openOnHero = (
    background: AppColors.heroPill,
    foreground: AppColors.onHero,
    border: null,
  );

  /// Closed / settled state, for the dark gradient hero.
  static const BadgeStyle closedOnHero = (
    background: AppColors.heroPill,
    foreground: AppColors.onHeroMuted,
    border: null,
  );
}
