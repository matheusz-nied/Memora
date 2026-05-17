import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../study_session_model.dart';
import '../study_text.dart';

class StudySummary extends StatelessWidget {
  const StudySummary({
    super.key,
    required this.summary,
    required this.onRestart,
    required this.onBackToDeck,
  });

  final StudySessionSummary summary;
  final VoidCallback onRestart;
  final VoidCallback onBackToDeck;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppDimensions.xxl),
            Text(
              StudyText.finishTitle,
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              StudyText.finishMessage,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
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
                ),
                _SummaryChip(
                  label: StudyText.summaryKnown,
                  value: summary.knownCards,
                ),
                _SummaryChip(
                  label: StudyText.summaryReview,
                  value: summary.needsReview,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xxl),
            AppButton(label: StudyText.restart, onPressed: onRestart),
            const SizedBox(height: AppDimensions.md),
            AppButton(
              label: StudyText.backToDeck,
              variant: AppButtonVariant.secondary,
              onPressed: onBackToDeck,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: AppColors.infoBg,
      side: BorderSide.none,
    );
  }
}