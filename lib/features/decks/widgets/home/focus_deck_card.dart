import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../deck_card_counts_provider.dart';
import '../../deck_model.dart';
import '../../deck_text.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/neon_button.dart';
import 'progress_ring.dart';

class FocusDeckCard extends ConsumerWidget {
  const FocusDeckCard({super.key, required this.deck, required this.isDark});

  final DeckModel deck;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(deckCardCountsStreamProvider(deck.id));

    return GlassPanel(
      isDark: isDark,
      glowColor: AppColors.neonGlowStrong,
      padding: const EdgeInsets.all(AppDimensions.xxl),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -48,
            right: -48,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                deck.title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.neonCyan : AppColors.primary,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              countsAsync.maybeWhen(
                data: (counts) => _DueProgress(counts: counts, isDark: isDark),
                orElse: () => const SizedBox.square(
                  dimension: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              countsAsync.maybeWhen(
                data: (counts) => _StatsRow(counts: counts, isDark: isDark),
                orElse: () => _StatsRow(counts: null, isDark: isDark),
              ),
              const SizedBox(height: AppDimensions.xl),
              NeonButton(
                label: DeckText.startReview,
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  context.push(RouteConstants.studyPath(deck.id));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DueProgress extends StatelessWidget {
  const _DueProgress({required this.counts, required this.isDark});

  final DeckCardCounts counts;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = counts.total == 0
        ? 1.0
        : (counts.total - counts.due) / counts.total;

    return ProgressRing(
      progress: progress,
      trackColor: isDark
          ? AppColors.glassBorderDark
          : AppColors.textPrimary.withValues(alpha: 0.06),
      progressColor: isDark
          ? AppColors.primary.withValues(alpha: 0.78)
          : AppColors.primary.withValues(alpha: 0.88),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${counts.due}',
            style: AppTypography.displayLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            DeckText.cardsDue,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.counts, required this.isDark});

  final DeckCardCounts? counts;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasCounts = counts != null;
    final total = counts?.total ?? 0;
    final due = counts?.due ?? 0;
    final progressVal = total == 0
        ? 100
        : (((total - due) / total) * 100).round();

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.lg),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.md,
        horizontal: AppDimensions.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        color: isDark
            ? AppColors.surfaceDeep.withValues(alpha: 0.65)
            : AppColors.background.withValues(alpha: 0.7),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _StatValue(
              label: DeckText.progress,
              value: hasCounts ? '$progressVal%' : '-',
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: isDark
                ? AppColors.glassBorderDark
                : AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          Expanded(
            child: _StatValue(
              label: DeckText.remaining,
              value: hasCounts ? '$due' : '-',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
            fontWeight: FontWeight.bold,
            fontSize: 8,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
