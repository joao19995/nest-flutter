import 'package:flutter/material.dart';

/// The Nest colour palette, resolved per theme brightness.
///
/// These are the "chrome" colours — page surfaces, cards, text and lines.
/// They are read from the active theme, so every widget adapts to light and
/// dark automatically:
///
/// ```dart
/// Container(color: context.colors.surface)
/// ```
///
/// Colours that only ever appear on the always-dark hero (on-hero text, the
/// hero gradient, coral-on-dark) stay fixed in [AppColors].
@immutable
class NestColors extends ThemeExtension<NestColors> {
  const NestColors({
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.faint,
    required this.line,
    required this.lineSoft,
    required this.paper,
    required this.inputBg,
    required this.surface,
    required this.primary,
    required this.primaryDark,
    required this.mint,
    required this.mintSoft,
    required this.over,
    required this.dangerSoft,
    required this.dangerOnSoft,
    required this.scrim,
    required this.terraSoft,
    required this.terraDark,
    required this.shadow,
  });

  /// Primary text.
  final Color ink;

  /// Secondary headings and label text.
  final Color inkSoft;

  /// Body copy and secondary links.
  final Color muted;

  /// Least prominent text, helper copy and disabled glyphs.
  final Color faint;

  /// Borders and dividers.
  final Color line;

  /// Subtle fills (neutral badges, skeletons, hover backgrounds).
  final Color lineSoft;

  /// Application page background.
  final Color paper;

  /// Input field background.
  final Color inputBg;

  /// Cards, panels, sheets and menu surfaces.
  final Color surface;

  /// Brand green — positive/ok state and active accents.
  final Color primary;

  /// Foreground on primary-tinted fills.
  final Color primaryDark;

  /// Stronger primary fill (tonal buttons, hover).
  final Color mint;

  /// Primary-tinted container fill (chips, icon boxes).
  final Color mintSoft;

  /// Coral, used only to signal an over-planned/shortfall state.
  final Color over;

  /// Destructive badge background.
  final Color dangerSoft;

  /// Destructive badge foreground.
  final Color dangerOnSoft;

  /// Backdrop behind modals, sheets and drawers.
  final Color scrim;

  /// Decorative chip/avatar background.
  final Color terraSoft;

  /// Decorative chip/avatar foreground.
  final Color terraDark;

  /// Base colour for card/panel shadows.
  final Color shadow;

  /// The light palette — identical to the web `@theme` defaults.
  static const NestColors light = NestColors(
    ink: Color(0xFF17372D),
    inkSoft: Color(0xFF2A4A3F),
    muted: Color(0xFF5D6B64),
    faint: Color(0xFF7D8A83),
    line: Color(0xFFE2E8E2),
    lineSoft: Color(0xFFEEF1EC),
    paper: Color(0xFFF7F8F5),
    inputBg: Color(0xFFFCFDFC),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF278763),
    primaryDark: Color(0xFF1E6B4F),
    mint: Color(0xFFDCEBE0),
    mintSoft: Color(0xFFE6EFE8),
    over: Color(0xFFC4492F),
    dangerSoft: Color(0xFFFFF0EF),
    dangerOnSoft: Color(0xFFA33A32),
    scrim: Color(0x6617372D),
    terraSoft: Color(0xFFF7E9D8),
    terraDark: Color(0xFFA86F3C),
    shadow: Color(0xFF17372D),
  );

  /// The dark palette — deeper greens, brighter accents, same identity.
  static const NestColors dark = NestColors(
    ink: Color(0xFFE7EFEA),
    inkSoft: Color(0xFFC7D5CD),
    muted: Color(0xFF9AA9A1),
    faint: Color(0xFF74837C),
    line: Color(0xFF2C3B34),
    lineSoft: Color(0xFF1E2B25),
    paper: Color(0xFF0E1512),
    inputBg: Color(0xFF16211C),
    surface: Color(0xFF17231E),
    primary: Color(0xFF45B98A),
    primaryDark: Color(0xFF9BDCC0),
    mint: Color(0xFF1F3A2E),
    mintSoft: Color(0xFF16281F),
    over: Color(0xFFE4715A),
    dangerSoft: Color(0xFF3A201C),
    dangerOnSoft: Color(0xFFF0A79A),
    scrim: Color(0x99000000),
    terraSoft: Color(0xFF33281C),
    terraDark: Color(0xFFD8A469),
    shadow: Color(0xFF000000),
  );

  @override
  NestColors copyWith() => this;

  @override
  NestColors lerp(covariant ThemeExtension<NestColors>? other, double t) {
    if (other is! NestColors) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

/// Reads the active [NestColors] from the theme.
extension NestColorsX on BuildContext {
  /// The Nest palette for the current brightness.
  NestColors get colors =>
      Theme.of(this).extension<NestColors>() ?? NestColors.light;
}
