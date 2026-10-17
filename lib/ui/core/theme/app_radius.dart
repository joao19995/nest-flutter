import 'package:flutter/material.dart';

/// Nest border-radius tokens. Always reference these, never a raw
/// `BorderRadius.circular(x)`.
abstract final class AppRadius {
  /// 8 px — buttons, inputs, selects, thumbnails.
  static const double sm = 8;

  /// 8 px, all corners.
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  /// 12 px — standard cards and containers.
  static const double md = 12;

  /// 12 px, all corners.
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  /// 16 px — sheets, dialogs, hero surfaces.
  static const double lg = 16;

  /// 16 px, all corners.
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));

  /// Fully rounded — badges, pills.
  static const double full = 9999;

  /// Fully rounded, all corners.
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}
