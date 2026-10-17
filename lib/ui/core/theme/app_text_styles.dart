import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nest/ui/core/theme/nest_colors.dart';

/// Nest typography tokens.
///
/// Body copy uses DM Sans; headings and large numbers use Manrope — matching
/// the web type scale.
///
/// Styles that carry a role colour take the active [NestColors] so they adapt
/// to light and dark: `AppTextStyles.bodyMuted(context.colors)`. Styles whose
/// colour is applied at the call site (or inherited) have no colour.
abstract final class AppTextStyles {
  /// Tabular figures keep monetary digits aligned in columns.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Page-level heading — list pages, detail pages, module headers.
  static TextStyle get pageTitle => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  /// Card and section heading.
  static TextStyle get sectionHeading => GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
  );

  /// Large numeric value on stat cards.
  ///
  /// Colour is applied at the call site using the card's accent token:
  /// `AppTextStyles.statDisplay.copyWith(color: context.colors.primary)`.
  static TextStyle get statDisplay => GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontFeatures: _tabular,
  );

  /// General body content.
  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  /// Secondary body copy — descriptions, table cells.
  static TextStyle bodyMuted(NestColors colors) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colors.muted,
    fontFeatures: _tabular,
  );

  /// Small secondary text — subtitles, counts, breadcrumbs.
  static TextStyle small(NestColors colors) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colors.muted,
    fontFeatures: _tabular,
  );

  /// Form and inline labels.
  static TextStyle label(NestColors colors) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: colors.inkSoft,
    fontFeatures: _tabular,
  );

  /// Assistive text below inputs.
  static TextStyle helper(NestColors colors) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colors.faint,
  );

  /// Button label.
  ///
  /// Colour is applied by the button's `foregroundColor`, never set here.
  /// Matches the Material 3 label-large scale.
  static TextStyle get button => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Status badge label.
  ///
  /// Colour comes from the badge's `BadgeStyle`, never set here.
  static TextStyle get badge =>
      GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700);

  /// Section eyebrow above a list or panel, e.g. `Por mês`.
  static TextStyle navSection(NestColors colors) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: colors.muted,
  );
}
