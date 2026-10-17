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

  /// 1100 ms — one full cycle of the loading-skeleton pulse.
  static const Duration pulse = Duration(milliseconds: 1100);

  /// 250 ms — a single list row's entrance (fade + slide).
  static const Duration entry = Duration(milliseconds: 250);

  /// 30 ms — delay between consecutive list rows entering.
  static const Duration stagger = Duration(milliseconds: 30);

  /// 1400 ms — how long the save-confirmation tick stays on screen.
  static const Duration confirm = Duration(milliseconds: 1400);

  /// The single easing curve used for all transitions.
  static const Curve easing = Curves.easeOut;
}
