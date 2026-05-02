import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = _textTheme(
      primary: AppColors.textPrimary,
      secondary: AppColors.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.info,
        onSecondary: AppColors.surface,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headingMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: AppColors.surface,
        borderColor: AppColors.border,
        focusedBorderColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(AppColors.border),
      textButtonTheme: _textButtonTheme(),
      cardTheme: _cardTheme(AppColors.surface),
      dividerTheme: const DividerThemeData(color: AppColors.border),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _textTheme(
      primary: AppColors.textPrimaryDark,
      secondary: AppColors.textSecDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.surface,
        secondary: AppColors.info,
        onSecondary: AppColors.surface,
        error: AppColors.error,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headingMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: AppColors.surfaceDark,
        borderColor: AppColors.borderDark,
        focusedBorderColor: AppColors.primary,
        textColor: AppColors.textPrimaryDark,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(AppColors.borderDark),
      textButtonTheme: _textButtonTheme(),
      cardTheme: _cardTheme(AppColors.surfaceDark),
      dividerTheme: const DividerThemeData(color: AppColors.borderDark),
    );
  }

  static TextTheme _textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: primary),
      headlineLarge: AppTypography.headingLarge.copyWith(color: primary),
      headlineMedium: AppTypography.headingMedium.copyWith(color: primary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: primary),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondary),
      labelLarge: AppTypography.labelMedium.copyWith(color: primary),
      labelMedium: AppTypography.labelMedium.copyWith(color: primary),
      labelSmall: AppTypography.labelSmall.copyWith(color: secondary),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color borderColor,
    required Color focusedBorderColor,
    required Color textColor,
  }) {
    final borderRadius = BorderRadius.circular(AppDimensions.radiusMd);

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      hintStyle: AppTypography.bodyLarge.copyWith(
        color: AppColors.textTertiary,
      ),
      labelStyle: AppTypography.bodyLarge.copyWith(color: textColor),
      errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: focusedBorderColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppDimensions.minTouchTarget),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        textStyle: AppTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(Color borderColor) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppDimensions.minTouchTarget),
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.labelMedium,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(
          AppDimensions.minTouchTarget,
          AppDimensions.minTouchTarget,
        ),
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.labelMedium,
      ),
    );
  }

  static CardThemeData _cardTheme(Color surfaceColor) {
    return CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
    );
  }
}
