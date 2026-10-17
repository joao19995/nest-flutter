import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nest/ui/core/theme/app_colors.dart';
import 'package:nest/ui/core/theme/app_radius.dart';
import 'package:nest/ui/core/theme/app_spacing.dart';
import 'package:nest/ui/core/theme/app_text_styles.dart';

/// The only place in the project that builds a `ThemeData`.
///
/// Nest is light-only; the token palette defines no dark variants.
abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary)
        .copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.surface,
          primaryContainer: AppColors.mintSoft,
          onPrimaryContainer: AppColors.primaryDark,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.line,
          outlineVariant: AppColors.lineSoft,
          error: AppColors.over,
          onError: AppColors.surface,
          errorContainer: AppColors.dangerSoft,
          onErrorContainer: AppColors.dangerOnSoft,
          scrim: AppColors.scrim,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.dmSans().fontFamily,
      scaffoldBackgroundColor: AppColors.paper,
      dividerColor: AppColors.line,
      textTheme: TextTheme(
        headlineMedium: AppTextStyles.pageTitle,
        titleMedium: AppTextStyles.sectionHeading,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.small,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.helper,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionHeading,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.faint),
        labelStyle: AppTextStyles.label,
        helperStyle: AppTextStyles.helper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: AppColors.over),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: AppColors.over, width: 1.5),
        ),
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
