import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
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
    return Row(
      children: [
        Expanded(
          child: _RatingButton(
            label: StudyText.again,
            color: AppColors.error,
            enabled: enabled,
            onPressed: () => onRating(CardRating.again),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _RatingButton(
            label: StudyText.hard,
            color: AppColors.warning,
            enabled: enabled,
            onPressed: () => onRating(CardRating.hard),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _RatingButton(
            label: StudyText.good,
            color: AppColors.info,
            enabled: enabled,
            onPressed: () => onRating(CardRating.good),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _RatingButton(
            label: StudyText.easy,
            color: AppColors.success,
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
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: enabled ? color.withValues(alpha: 0.5) : AppColors.borderStrong,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
