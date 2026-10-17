import 'package:flutter/material.dart';

/// Nest motion tokens. No animation may declare a raw `Duration`.
abstract final class AppMotion {
  /// 100 ms — micro-interactions: button hover/press, dropdown open.
  static const Duration fast = Duration(milliseconds: 100);

  /// 150 ms — small spatial transitions: card hover scale and shadow shift.
  static const Duration standard = Duration(milliseconds: 150);

  /// 250 ms — medium-distance entries/exits: dialogs, bottom sheets.
  static const Duration dialog = Duration(milliseconds: 250);

  /// 300 ms — full-panel transitions: drawers, page slides.
  static const Duration large = Duration(milliseconds: 300);

  /// The single easing curve used for all transitions.
  static const Curve easing = Curves.easeOut;
}
