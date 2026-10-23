import 'package:flutter/widgets.dart';
import 'package:nest/ui/core/theme/app_spacing.dart';

/// Nest breakpoint tokens and viewport helpers.
///
/// Never compare `MediaQuery` width against a raw number; use these helpers.
abstract final class AppBreakpoints {
  /// 0 px — small-screen mobile.
  static const double xs = 0;

  /// 640 px — large-screen mobile.
  static const double sm = 640;

  /// 768 px — tablet; side navigation appears.
  static const double md = 768;

  /// 1024 px — desktop; full multi-column layouts.
  static const double lg = 1024;

  /// True when the layout should use the single-column mobile shell.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < md;

  /// True when the layout is tablet or wider.
  static bool isTabletOrWider(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= md;

  /// True when the layout is desktop.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= lg;

  /// The correct horizontal page padding for the current viewport.
  static double pagePadding(BuildContext context) =>
      isMobile(context) ? AppSpacing.mobilePagePadding : AppSpacing.pagePadding;

  /// The correct card padding for the current viewport.
  static double cardPadding(BuildContext context) =>
      isMobile(context) ? AppSpacing.mobileCardPadding : AppSpacing.cardPadding;

  /// The number of columns for a grid laid out inside [width].
  ///
  /// Defaults to three columns on mobile and four from [md] upwards.
  static int columnsForWidth(double width, {int mobile = 3, int tablet = 4}) =>
      width >= md ? tablet : mobile;

  /// The number of stat-card columns for the current viewport.
  static int statColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= lg) {
      return 4;
    }
    if (width >= md) {
      return 2;
    }
    return 2;
  }
}
