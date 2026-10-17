import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nest/ui/core/theme/app_colors.dart';

/// Nest typography tokens.
///
/// Body copy uses DM Sans; headings and large numbers use Manrope — matching
/// the web type scale. Colour comes from the role unless noted otherwise.
abstract final class AppTextStyles {
  /// Page-level heading — list pages, detail pages, module headers.
  static TextStyle get pageTitle => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  /// Card and section heading.
  static TextStyle get sectionHeading => GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.ink,
  );

  /// Large numeric value on stat cards.
  ///
  /// Colour is applied at the call site using the card's accent token:
  /// `AppTextStyles.statDisplay.copyWith(color: AppColors.primary)`.
  static TextStyle get statDisplay => GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  /// General body content.
  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  /// Secondary body copy — descriptions, table cells.
  static TextStyle get bodyMuted => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  /// Small secondary text — subtitles, counts, breadcrumbs.
  static TextStyle get small => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
  );

  /// Form and inline labels.
  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inkSoft,
  );

  /// Assistive text below inputs.
  static TextStyle get helper => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.faint,
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

  /// All-caps navigation section label.
  static TextStyle get navSection => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.faint,
  );
}
