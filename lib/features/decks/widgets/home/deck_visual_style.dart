import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DeckVisualStyle {
  const DeckVisualStyle({
    required this.color,
    required this.icon,
    required this.backgroundColor,
  });

  final Color color;
  final IconData icon;
  final Color backgroundColor;

  factory DeckVisualStyle.fromTitle(String title, bool isDark) {
    final normalized = title.toLowerCase();

    if (normalized.contains('cor') ||
        normalized.contains('saúd') ||
        normalized.contains('med') ||
        normalized.contains('cardio')) {
      return DeckVisualStyle(
        color: AppColors.error,
        icon: Icons.favorite,
        backgroundColor: AppColors.error.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      );
    }

    if (normalized.contains('dir') ||
        normalized.contains('lei') ||
        normalized.contains('law') ||
        normalized.contains('gavel') ||
        normalized.contains('tribunal')) {
      return DeckVisualStyle(
        color: AppColors.primaryDark,
        icon: Icons.gavel,
        backgroundColor: AppColors.primaryDark.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      );
    }

    if (normalized.contains('ingl') ||
        normalized.contains('idiom') ||
        normalized.contains('span') ||
        normalized.contains('vocab') ||
        normalized.contains('trad') ||
        normalized.contains('english')) {
      return DeckVisualStyle(
        color: AppColors.warning,
        icon: Icons.translate,
        backgroundColor: AppColors.warning.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      );
    }

    if (normalized.contains('prog') ||
        normalized.contains('code') ||
        normalized.contains('comput') ||
        normalized.contains('dev') ||
        normalized.contains('tech')) {
      return DeckVisualStyle(
        color: AppColors.info,
        icon: Icons.code,
        backgroundColor: AppColors.info.withValues(alpha: isDark ? 0.15 : 0.08),
      );
    }

    if (normalized.contains('ciên') ||
        normalized.contains('quím') ||
        normalized.contains('bio') ||
        normalized.contains('fís')) {
      return DeckVisualStyle(
        color: AppColors.success,
        icon: Icons.science,
        backgroundColor: AppColors.success.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      );
    }

    return switch (title.hashCode.abs() % 5) {
      0 => DeckVisualStyle(
        color: AppColors.primary,
        icon: Icons.school,
        backgroundColor: AppColors.primary.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      ),
      1 => DeckVisualStyle(
        color: AppColors.info,
        icon: Icons.lightbulb,
        backgroundColor: AppColors.info.withValues(alpha: isDark ? 0.15 : 0.08),
      ),
      2 => DeckVisualStyle(
        color: AppColors.warning,
        icon: Icons.auto_stories,
        backgroundColor: AppColors.warning.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      ),
      3 => DeckVisualStyle(
        color: AppColors.error,
        icon: Icons.psychology,
        backgroundColor: AppColors.error.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      ),
      _ => DeckVisualStyle(
        color: AppColors.primaryHover,
        icon: Icons.menu_book,
        backgroundColor: AppColors.primaryHover.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
      ),
    };
  }
}
