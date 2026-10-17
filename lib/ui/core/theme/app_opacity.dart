/// Nest opacity tokens.
///
/// Never use raw opacity literals in widget code; dim de-emphasised content
/// with [dimmed] instead.
abstract final class AppOpacity {
  /// Fully opaque content.
  static const double full = 1;

  /// Content that is still interactive but visually de-emphasised, such as a
  /// completed to-do list.
  static const double dimmed = 0.6;
}
