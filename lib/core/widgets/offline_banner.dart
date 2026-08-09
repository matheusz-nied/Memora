import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'glass_panel.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      showTopHighlight: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      borderColor: AppColors.warning.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.sm,
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.xs),
              child: Icon(
                Icons.cloud_off_outlined,
                color: AppColors.warning,
                size: AppDimensions.xl,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
