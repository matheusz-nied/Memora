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
import 'deck_visual_style.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/soft_progress_bar.dart';

class RecentDeckTile extends ConsumerWidget {
  const RecentDeckTile({super.key, required this.deck, required this.isDark});

  final DeckModel deck;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = DeckVisualStyle.fromTitle(deck.title, isDark);
    final countsAsync = ref.watch(deckCardCountsStreamProvider(deck.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: PressableScale(
        onTap: () => context.push(RouteConstants.deckPath(deck.id)),
        child: GlassPanel(
          isDark: isDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          showTopHighlight: false,
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            children: [
              Container(
                width: AppDimensions.minTouchTarget,
                height: AppDimensions.minTouchTarget,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      style.backgroundColor,
                      style.backgroundColor.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: style.color.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(style.icon, color: style.color, size: 24),
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            deck.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        countsAsync.maybeWhen(
                          data: (counts) {
                            final percent = counts.total == 0
                                ? 100
                                : (((counts.total - counts.due) /
                                              counts.total) *
                                          100)
                                      .round();
                            return Text(
                              '$percent%',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.neonCyan.withValues(
                                  alpha: isDark ? 0.9 : 1,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                          orElse: () => const Text('-'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    countsAsync.maybeWhen(
                      data: (counts) {
                        final progress = counts.total == 0
                            ? 1.0
                            : (counts.total - counts.due) / counts.total;
                        return SoftProgressBar(
                          progress: progress,
                          isDark: isDark,
                        );
                      },
                      orElse: () => const SizedBox(height: 6),
                    ),
                    const SizedBox(height: 6),
                    countsAsync.maybeWhen(
                      data: (counts) {
                        final status = counts.due == 0
                            ? DeckText.reviewComplete
                            : '${counts.due} ${DeckText.dueToday}';
                        return Text(
                          '${counts.total} ${DeckText.cards} · $status',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecDark
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
