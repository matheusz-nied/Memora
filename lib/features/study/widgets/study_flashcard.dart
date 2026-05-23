import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
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

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surface;
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
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.60,
          constraints: const BoxConstraints(minHeight: 380, maxHeight: 600),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppDimensions.radius3Xl),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: isDark ? 50 : 40,
                offset: Offset(0, isDark ? 20 : 20),
                spreadRadius: isDark ? -12 : -10,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.border,
            ),
          ),
          child: Stack(
            children: [
              // Background Icon
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
              // Content
              Padding(
                padding: const EdgeInsets.all(AppDimensions.xxxl),
                child: Column(
                  children: [
                    // Top Row
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
                    // Center Content
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
                    // Bottom Hint
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
