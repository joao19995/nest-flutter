import 'package:flutter/material.dart';
import 'package:nest/ui/core/theme/app_radius.dart';
import 'package:nest/ui/core/theme/app_sizes.dart';
import 'package:nest/ui/core/theme/app_spacing.dart';
import 'package:nest/ui/core/theme/app_text_styles.dart';
import 'package:nest/ui/core/theme/nest_colors.dart';

/// The only place in the project that builds a `ThemeData`.
///
/// Both brightnesses are built from the same token set — [NestColors.light]
/// and [NestColors.dark] — so the palette stays in one place.
abstract final class AppTheme {
  static ThemeData get light => _build(NestColors.light, Brightness.light);

  static ThemeData get dark => _build(NestColors.dark, Brightness.dark);

  static ThemeData _build(NestColors colors, Brightness brightness) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.surface,
          primaryContainer: colors.mintSoft,
          onPrimaryContainer: colors.primaryDark,
          surface: colors.surface,
          onSurface: colors.ink,
          onSurfaceVariant: colors.muted,
          outline: colors.line,
          outlineVariant: colors.lineSoft,
          error: colors.over,
          onError: colors.surface,
          errorContainer: colors.dangerSoft,
          onErrorContainer: colors.dangerOnSoft,
          scrim: colors.scrim,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [colors],
      fontFamily: AppTextStyles.bodyFamily,
      scaffoldBackgroundColor: colors.paper,
      dividerColor: colors.line,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
      textTheme: TextTheme(
        headlineMedium: AppTextStyles.pageTitle,
        titleMedium: AppTextStyles.sectionHeading,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.small(colors),
        labelMedium: AppTextStyles.label(colors),
        labelSmall: AppTextStyles.helper(colors),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(
          color: colors.ink,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.mint,
        elevation: 0,
        height: AppSizes.mobileBottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSizes.iconLarge,
            color: selected ? colors.primaryDark : colors.faint,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.label(
            colors,
          ).copyWith(color: selected ? colors.primaryDark : colors.muted);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.mint,
        selectedIconTheme: IconThemeData(
          size: AppSizes.iconLarge,
          color: colors.primaryDark,
        ),
        unselectedIconTheme: IconThemeData(
          size: AppSizes.iconLarge,
          color: colors.faint,
        ),
        selectedLabelTextStyle: AppTextStyles.label(
          colors,
        ).copyWith(color: colors.primaryDark),
        unselectedLabelTextStyle: AppTextStyles.label(
          colors,
        ).copyWith(color: colors.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBg,
        hintStyle: AppTextStyles.body.copyWith(color: colors.faint),
        labelStyle: AppTextStyles.label(colors),
        helperStyle: AppTextStyles.helper(colors),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(
            color: colors.primary,
            width: AppSizes.inputFocusBorderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: colors.over),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(
            color: colors.over,
            width: AppSizes.inputFocusErrorBorderWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: colors.line),
        ),
      ),
    );
  }
}
