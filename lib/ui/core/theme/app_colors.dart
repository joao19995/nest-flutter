import 'package:flutter/material.dart';

/// Nest colour tokens — mirrored from the web palette (`app/globals.css` `@theme`).
///
/// No raw colour may appear in widget code; always reference a token here.
abstract final class AppColors {
  // ── Core ────────────────────────────────────────────────────────────────
  /// `--color-ink` — primary text and the default button fill.
  static const Color ink = Color(0xFF17372D);

  /// `--color-ink-soft` — secondary headings and button hover fill.
  static const Color inkSoft = Color(0xFF2A4A3F);

  /// `--color-muted` — body copy, descriptions, secondary links.
  static const Color muted = Color(0xFF5D6B64);

  /// `--color-faint` — least prominent text, helper copy.
  static const Color faint = Color(0xFF7D8A83);

  // ── Surfaces & lines ────────────────────────────────────────────────────
  /// `--color-line` — borders and dividers.
  static const Color line = Color(0xFFE2E8E2);

  /// `--color-line-soft` — subtle fills (neutral badges, hover backgrounds).
  static const Color lineSoft = Color(0xFFEEF1EC);

  /// `--color-paper` — application page background.
  static const Color paper = Color(0xFFF7F8F5);

  /// `--color-input-bg` — input field background.
  static const Color inputBg = Color(0xFFFCFDFC);

  /// `--color-white` — cards, panels, sheets, menu surfaces.
  static const Color surface = Color(0xFFFFFFFF);

  // ── Primary (brand green) ───────────────────────────────────────────────
  /// `--color-primary` — positive/ok state, active accents.
  static const Color primary = Color(0xFF278763);

  /// `--color-primary-dark` — text on light primary fills.
  static const Color primaryDark = Color(0xFF1E6B4F);

  /// `--color-mint` — stronger primary fill.
  static const Color mint = Color(0xFFDCEBE0);

  /// `--color-mint-soft` — primary-tinted container fill.
  static const Color mintSoft = Color(0xFFE6EFE8);

  // ── Terra (decorative only) ─────────────────────────────────────────────
  /// `--color-terra-soft` — decorative chip/avatar background.
  static const Color terraSoft = Color(0xFFF7E9D8);

  /// `--color-terra-dark` — decorative terra foreground.
  static const Color terraDark = Color(0xFFA86F3C);

  // ── Over (over-planned state) ───────────────────────────────────────────
  /// `--color-over` — coral, used only to signal over-planned/shortfall state.
  static const Color over = Color(0xFFC4492F);

  /// `--color-over-on-dark` — coral on dark backgrounds.
  static const Color overOnDark = Color(0xFFFFB4A2);

  // ── Destructive badge pair (web: #fff0ef / #a33a32) ─────────────────────
  /// Destructive badge background.
  static const Color dangerSoft = Color(0xFFFFF0EF);

  /// Destructive badge foreground.
  static const Color dangerOnSoft = Color(0xFFA33A32);

  // ── Overlay ─────────────────────────────────────────────────────────────
  /// `--color-ink` at 40% — backdrops behind modals, sheets and drawers.
  static const Color scrim = Color(0x6617372D);

  /// Fully transparent — for clearing backgrounds and overlay layers.
  static const Color transparent = Color(0x00000000);
}
