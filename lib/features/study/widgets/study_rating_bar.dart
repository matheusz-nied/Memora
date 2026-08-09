import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../card_rating_model.dart';
import '../study_text.dart';

class StudyRatingBar extends StatelessWidget {
  const StudyRatingBar({
    super.key,
    required this.enabled,
    required this.onRating,
  });

  final bool enabled;
  final ValueChanged<CardRating> onRating;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _RatingButton(
            label: StudyText.again,
            color: AppColors.error,
            isDark: isDark,
            enabled: enabled,
            onPressed: () => onRating(CardRating.again),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _RatingButton(
            label: StudyText.hard,
            color: AppColors.warning,
            isDark: isDark,
            enabled: enabled,
            onPressed: () => onRating(CardRating.hard),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _RatingButton(
            label: StudyText.good,
            color: AppColors.info,
            isDark: isDark,
            enabled: enabled,
            onPressed: () => onRating(CardRating.good),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _RatingButton(
            label: StudyText.easy,
            color: AppColors.success,
            isDark: isDark,
            enabled: enabled,
            onPressed: () => onRating(CardRating.easy),
          ),
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.isDark,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool isDark;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: enabled ? onPressed : null,
      child: GlassPanel(
        isDark: isDark,
        showGlow: false,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderColor: enabled
            ? color.withValues(alpha: 0.35)
            : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 56,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.xs,
                ),
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: enabled
                        ? color
                        : (isDark
                              ? AppColors.textTertDark
                              : AppColors.textTertiary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
