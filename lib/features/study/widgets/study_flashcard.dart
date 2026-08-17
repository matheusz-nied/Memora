import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../study_text.dart';

class StudyFlashcard extends StatelessWidget {
  const StudyFlashcard({
    super.key,
    required this.front,
    required this.back,
    required this.showBack,
    required this.onToggle,
    required this.onSpeak,
  });

  final String front;
  final String back;
  final bool showBack;
  final VoidCallback onToggle;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isQuestion = !showBack;
    final badgeText = isQuestion ? StudyText.front : StudyText.back;
    final badgeBg = AppColors.primary.withValues(alpha: 0.1);
    final badgeBorder = AppColors.primary.withValues(alpha: 0.2);
    final badgeTextColor = AppColors.primary;

    final content = showBack ? back : front;
    final contentStyle = isQuestion
        ? AppTypography.headingLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          )
        : AppTypography.headingMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          );

    return Semantics(
      button: true,
      label: StudyText.tapToReveal,
      child: PressableScale(
        onTap: onToggle,
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.60,
          child: GlassPanel(
            isDark: isDark,
            showGlow: false,
            borderRadius: BorderRadius.circular(AppDimensions.radius3Xl),
            padding: const EdgeInsets.all(AppDimensions.xxxl),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: IgnorePointer(
                      child: Transform.rotate(
                        angle: 12 * math.pi / 180,
                        child: Icon(
                          Icons.school,
                          size: 200,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : AppColors.textSecondary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.md,
                            vertical: AppDimensions.xs,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.xs),
                              Text(
                                badgeText.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: badgeTextColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: AppDimensions.minTouchTarget,
                          height: AppDimensions.minTouchTarget,
                          child: IconButton(
                            tooltip: StudyText.speak,
                            onPressed: onSpeak,
                            icon: const Icon(Icons.volume_up, size: 24),
                            style: IconButton.styleFrom(
                              foregroundColor: isDark
                                  ? AppColors.textTertDark
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            content,
                            textAlign: TextAlign.center,
                            style: contentStyle,
                          ),
                        ),
                      ),
                    ),
                    if (isQuestion)
                      Padding(
                        padding: const EdgeInsets.only(top: AppDimensions.lg),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 18,
                              color: isDark
                                  ? AppColors.textTertDark
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: AppDimensions.xs),
                            Text(
                              StudyText.tapToReveal.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textTertDark
                                    : AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
