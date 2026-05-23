import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import '../cards/card_model.dart';
import '../cards/card_repository.dart';
import '../decks/deck_repository.dart';
import 'study_text.dart';

class InsightScreen extends ConsumerWidget {
  const InsightScreen({super.key, required this.deckId, required this.cardId});

  final String deckId;
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckStreamProvider(deckId));
    final card = ref.watch(cardStreamProvider(cardId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text(StudyText.insightScreenTitle)),
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: card.when(
            loading: () => const LoadingState(),
            error: (_, __) => const ErrorState(message: StudyText.loadingError),
            data: (value) {
              if (value == null || value.deckId != deckId) {
                return const ErrorState(message: StudyText.loadingError);
              }

              final insight = value.insight?.trim();
              if (insight == null || insight.isEmpty) {
                return const EmptyState(
                  title: StudyText.insightEmptyTitle,
                  message: StudyText.insightEmptyMessage,
                );
              }

              return deck.maybeWhen(
                data: (deckValue) => _InsightContent(
                  card: value,
                  deckTitle: deckValue?.title,
                  insight: insight,
                ),
                orElse: () => _InsightContent(card: value, insight: insight),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InsightContent extends StatelessWidget {
  const _InsightContent({
    required this.card,
    required this.insight,
    this.deckTitle,
  });

  final CardModel card;
  final String insight;
  final String? deckTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDarkStrong : AppColors.border;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final secondaryColor = isDark
        ? AppColors.textSecDark
        : AppColors.textSecondary;

    return SingleChildScrollView(
      padding: Responsive.contentPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deckTitle != null) ...[
            Text(
              deckTitle!,
              style: AppTypography.labelMedium.copyWith(color: secondaryColor),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
          _PromptCard(
            label: StudyText.insightQuestion,
            text: card.front,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
          ),
          const SizedBox(height: AppDimensions.md),
          _PromptCard(
            label: StudyText.insightAnswer,
            text: card.back,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
          ),
          const SizedBox(height: AppDimensions.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.xl),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(color: borderColor),
            ),
            child: MarkdownBody(
              data: insight,
              selectable: true,
              styleSheet: _markdownStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final secondaryColor = isDark
        ? AppColors.textSecDark
        : AppColors.textSecondary;
    final codeBg = isDark ? AppColors.borderDark : AppColors.infoBg;

    return MarkdownStyleSheet(
      p: AppTypography.bodyLarge.copyWith(color: textColor),
      h1: AppTypography.headingLarge.copyWith(color: textColor),
      h2: AppTypography.headingMedium.copyWith(color: textColor),
      h3: AppTypography.labelMedium.copyWith(color: textColor),
      strong: AppTypography.bodyLarge.copyWith(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
      em: AppTypography.bodyLarge.copyWith(
        color: textColor,
        fontStyle: FontStyle.italic,
      ),
      listBullet: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
      blockquote: AppTypography.bodyLarge.copyWith(color: secondaryColor),
      code: AppTypography.bodyMedium.copyWith(
        color: textColor,
        backgroundColor: codeBg,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      blockSpacing: AppDimensions.lg,
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.label,
    required this.text,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
  });

  final String label;
  final String text;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
