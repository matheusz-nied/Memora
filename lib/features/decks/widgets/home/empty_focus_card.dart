import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../deck_text.dart';

class EmptyFocusCard extends StatelessWidget {
  const EmptyFocusCard({
    super.key,
    required this.isDark,
    required this.onCreateDeck,
  });

  final bool isDark;
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
        border: Border.all(
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.05)
              : AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.school_outlined,
            size: AppDimensions.huge,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            DeckText.emptyTitle,
            style: AppTypography.headingMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            DeckText.emptyMessage,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          AppButton(label: DeckText.newDeck, onPressed: onCreateDeck),
        ],
      ),
    );
  }
}
