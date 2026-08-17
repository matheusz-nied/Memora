import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Progress bar with the softened blue gradient used across the app.
class SoftProgressBar extends StatelessWidget {
  const SoftProgressBar({
    super.key,
    required this.progress,
    required this.isDark,
    this.height = 6,
  });

  final double progress;
  final bool isDark;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.glassBorderDark
                    : AppColors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.primary.withValues(alpha: 0.78),
                            AppColors.neonBlue.withValues(alpha: 0.68),
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.88),
                            AppColors.primary.withValues(alpha: 0.78),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
