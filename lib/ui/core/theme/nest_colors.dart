import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/app_colors.dart';

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
    required this.categoryPalette,
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

  /// Accent colours for category icons and the expenses donut.
  ///
  /// Always an immutable, fixed-length list so every category has a stable
  /// colour in both brightnesses. Pick one with
  /// `context.colors.colorForCategory(name)`.
  final List<Color> categoryPalette;

  /// The light palette — identical to the web `@theme` defaults.
  static const NestColors light = NestColors(
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    muted: AppColors.muted,
    faint: AppColors.faint,
    line: AppColors.line,
    lineSoft: AppColors.lineSoft,
    paper: AppColors.paper,
    inputBg: AppColors.inputBg,
    surface: AppColors.surface,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    mint: AppColors.mint,
    mintSoft: AppColors.mintSoft,
    over: AppColors.over,
    dangerSoft: AppColors.dangerSoft,
    dangerOnSoft: AppColors.dangerOnSoft,
    scrim: AppColors.scrim,
    terraSoft: AppColors.terraSoft,
    terraDark: AppColors.terraDark,
    shadow: AppColors.ink,
    categoryPalette: <Color>[
      Color(0xFF2F8F6E),
      Color(0xFF6E8F2E),
      Color(0xFFB58A1F),
      Color(0xFF2C8796),
      Color(0xFF3E6FB0),
      Color(0xFF6A58B5),
      Color(0xFF9C4A94),
      Color(0xFFB04C68),
    ],
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
    categoryPalette: <Color>[
      Color(0xFF6EC5A2),
      Color(0xFFA8C56E),
      Color(0xFFD9B85F),
      Color(0xFF6FBBC9),
      Color(0xFF86ACDE),
      Color(0xFFA99BE6),
      Color(0xFFCE8FC6),
      Color(0xFFDE8CA2),
    ],
  );

  @override
  NestColors copyWith({
    Color? ink,
    Color? inkSoft,
    Color? muted,
    Color? faint,
    Color? line,
    Color? lineSoft,
    Color? paper,
    Color? inputBg,
    Color? surface,
    Color? primary,
    Color? primaryDark,
    Color? mint,
    Color? mintSoft,
    Color? over,
    Color? dangerSoft,
    Color? dangerOnSoft,
    Color? scrim,
    Color? terraSoft,
    Color? terraDark,
    Color? shadow,
    List<Color>? categoryPalette,
  }) => NestColors(
    ink: ink ?? this.ink,
    inkSoft: inkSoft ?? this.inkSoft,
    muted: muted ?? this.muted,
    faint: faint ?? this.faint,
    line: line ?? this.line,
    lineSoft: lineSoft ?? this.lineSoft,
    paper: paper ?? this.paper,
    inputBg: inputBg ?? this.inputBg,
    surface: surface ?? this.surface,
    primary: primary ?? this.primary,
    primaryDark: primaryDark ?? this.primaryDark,
    mint: mint ?? this.mint,
    mintSoft: mintSoft ?? this.mintSoft,
    over: over ?? this.over,
    dangerSoft: dangerSoft ?? this.dangerSoft,
    dangerOnSoft: dangerOnSoft ?? this.dangerOnSoft,
    scrim: scrim ?? this.scrim,
    terraSoft: terraSoft ?? this.terraSoft,
    terraDark: terraDark ?? this.terraDark,
    shadow: shadow ?? this.shadow,
    categoryPalette: categoryPalette ?? this.categoryPalette,
  );

  @override
  NestColors lerp(covariant ThemeExtension<NestColors>? other, double t) {
    if (other is! NestColors) {
      return this;
    }
    return NestColors(
      ink: _lerp(ink, other.ink, t),
      inkSoft: _lerp(inkSoft, other.inkSoft, t),
      muted: _lerp(muted, other.muted, t),
      faint: _lerp(faint, other.faint, t),
      line: _lerp(line, other.line, t),
      lineSoft: _lerp(lineSoft, other.lineSoft, t),
      paper: _lerp(paper, other.paper, t),
      inputBg: _lerp(inputBg, other.inputBg, t),
      surface: _lerp(surface, other.surface, t),
      primary: _lerp(primary, other.primary, t),
      primaryDark: _lerp(primaryDark, other.primaryDark, t),
      mint: _lerp(mint, other.mint, t),
      mintSoft: _lerp(mintSoft, other.mintSoft, t),
      over: _lerp(over, other.over, t),
      dangerSoft: _lerp(dangerSoft, other.dangerSoft, t),
      dangerOnSoft: _lerp(dangerOnSoft, other.dangerOnSoft, t),
      scrim: _lerp(scrim, other.scrim, t),
      terraSoft: _lerp(terraSoft, other.terraSoft, t),
      terraDark: _lerp(terraDark, other.terraDark, t),
      shadow: _lerp(shadow, other.shadow, t),
      categoryPalette: [
        for (var index = 0; index < categoryPalette.length; index++)
          _lerp(
            categoryPalette[index],
            other.categoryPalette.length > index
                ? other.categoryPalette[index]
                : categoryPalette[index],
            t,
          ),
      ],
    );
  }

  static Color _lerp(Color from, Color to, double t) =>
      Color.lerp(from, to, t) ?? from;
}

/// Reads the active [NestColors] from the theme.
extension NestColorsX on BuildContext {
  /// The Nest palette for the current brightness.
  NestColors get colors =>
      Theme.of(this).extension<NestColors>() ?? NestColors.light;
}
