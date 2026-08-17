import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/neon_button.dart';
import '../study_session_model.dart';
import '../study_text.dart';

class StudySummary extends StatelessWidget {
  const StudySummary({
    super.key,
    required this.summary,
    this.onRestart,
    required this.onBackToDeck,
  });

  final StudySessionSummary summary;
  final VoidCallback? onRestart;
  final VoidCallback onBackToDeck;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final subtitleColor = isDark
        ? AppColors.textSecDark
        : AppColors.textSecondary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: GlassPanel(
          isDark: isDark,
          showGlow: false,
          padding: const EdgeInsets.all(AppDimensions.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                size: 64,
                color: isDark ? AppColors.neonCyan : AppColors.primary,
              ),
              const SizedBox(height: AppDimensions.xxl),
              Text(
                StudyText.finishTitle,
                style: AppTypography.displayLarge.copyWith(color: titleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                StudyText.finishMessage,
                style: AppTypography.bodyLarge.copyWith(color: subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.xxl),
              Wrap(
                spacing: AppDimensions.sm,
                runSpacing: AppDimensions.sm,
                alignment: WrapAlignment.center,
                children: [
                  _SummaryChip(
                    label: StudyText.summaryCards,
                    value: summary.totalCards,
                    isDark: isDark,
                  ),
                  _SummaryChip(
                    label: StudyText.summaryKnown,
                    value: summary.knownCards,
                    isDark: isDark,
                  ),
                  _SummaryChip(
                    label: StudyText.summaryReview,
                    value: summary.needsReview,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xxl),
              if (onRestart != null) ...[
                NeonButton(label: StudyText.restart, onPressed: onRestart),
                const SizedBox(height: AppDimensions.md),
              ],
              AppButton(
                label: StudyText.backToDeck,
                variant: AppButtonVariant.secondary,
                onPressed: onBackToDeck,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final int value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.glassDark.withValues(alpha: 0.6)
            : AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
