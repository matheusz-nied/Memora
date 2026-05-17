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
    final isQuestion = !showBack;
    final badgeText = isQuestion ? StudyText.front : StudyText.back;
    final badgeBg = isQuestion ? AppColors.primaryLight : AppColors.primary;
    final badgeTextColor = isQuestion ? AppColors.primary : AppColors.surface;
    final cardBg = isQuestion ? AppColors.surface : AppColors.primaryLight;
    final content = showBack ? back : front;
    final contentStyle = isQuestion
        ? AppTypography.headingLarge.copyWith(color: AppColors.textPrimary)
        : AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary);

    return Semantics(
      button: true,
      label: StudyText.tapToReveal,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        onTap: onToggle,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 280),
          padding: const EdgeInsets.all(AppDimensions.xxxl),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.xs,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      badgeText,
                      style: AppTypography.labelSmall.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: AppDimensions.minTouchTarget,
                    height: AppDimensions.minTouchTarget,
                    child: IconButton(
                      tooltip: StudyText.speak,
                      onPressed: onSpeak,
                      icon: const Icon(Icons.volume_up, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xxl),
              Center(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: contentStyle,
                ),
              ),
              if (isQuestion) ...[
                const SizedBox(height: AppDimensions.xxl),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        StudyText.tapToReveal,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}