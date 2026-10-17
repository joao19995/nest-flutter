/// Nest spacing tokens.
///
/// Page and card padding, plus a general gap scale. Never use raw spacing
/// literals in layout widgets.
abstract final class AppSpacing {
  /// Padding around the main page content on large viewports.
  static const double pagePadding = 24;

  /// Internal padding of cards on large viewports.
  static const double cardPadding = 20;

  /// Padding around the main page content on small viewports.
  static const double mobilePagePadding = 16;

  /// Internal padding of cards on small viewports.
  static const double mobileCardPadding = 16;

  // ── Gap scale ───────────────────────────────────────────────────────────
  /// 4 px.
  static const double xs = 4;

  /// 8 px.
  static const double sm = 8;

  /// 12 px.
  static const double md = 12;

  /// 16 px.
  static const double lg = 16;

  /// 24 px.
  static const double xl = 24;
}
