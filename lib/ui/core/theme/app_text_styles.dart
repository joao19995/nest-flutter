import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/nest_colors.dart';

/// Nest typography tokens.
///
/// Body copy uses DM Sans; headings and large numbers use Manrope — matching
/// the web type scale. Both fonts are bundled as assets, so the PWA renders
/// the same typography offline without fetching from Google Fonts.
///
/// Styles that carry a role colour take the active [NestColors] so they adapt
/// to light and dark: `AppTextStyles.bodyMuted(context.colors)`. Styles whose
/// colour is applied at the call site (or inherited) have no colour.
abstract final class AppTextStyles {
  /// Bundled body font family.
  static const String bodyFamily = 'DMSans';

  /// Bundled heading font family.
  static const String headingFamily = 'Manrope';

  /// Tabular figures keep monetary digits aligned in columns.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Page-level heading — list pages, detail pages, module headers.
  static const TextStyle pageTitle = TextStyle(
    fontFamily: headingFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  /// Card and section heading.
  static const TextStyle sectionHeading = TextStyle(
    fontFamily: headingFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
  );

  /// Large numeric value on stat cards.
  ///
  /// Colour is applied at the call site using the card's accent token:
  /// `AppTextStyles.statDisplay.copyWith(color: context.colors.primary)`.
  static const TextStyle statDisplay = TextStyle(
    fontFamily: headingFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontFeatures: _tabular,
  );

  /// General body content.
  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  /// Secondary body copy — descriptions, table cells.
  static TextStyle bodyMuted(NestColors colors) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colors.muted,
    fontFeatures: _tabular,
  );

  /// Small secondary text — subtitles, counts, breadcrumbs.
  static TextStyle small(NestColors colors) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colors.muted,
    fontFeatures: _tabular,
  );

  /// Form and inline labels.
  static TextStyle label(NestColors colors) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: colors.inkSoft,
    fontFeatures: _tabular,
  );

  /// Assistive text below inputs.
  static TextStyle helper(NestColors colors) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colors.faint,
  );

  /// Button label.
  ///
  /// Colour is applied by the button's `foregroundColor`, never set here.
  /// Matches the Material 3 label-large scale.
  static const TextStyle button = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Status badge label.
  ///
  /// Colour comes from the badge's `BadgeStyle`, never set here.
  static const TextStyle badge = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  /// Section eyebrow above a list or panel, e.g. `Por mês`.
  static TextStyle navSection(NestColors colors) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: colors.muted,
  );
}
