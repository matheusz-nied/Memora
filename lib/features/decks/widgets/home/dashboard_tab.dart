import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../backup/widgets/backup_reminder_card.dart';
import '../../../settings/widgets/missing_api_key_card.dart';
import '../../../stats/widgets/study_stats_card.dart';
import '../../deck_model.dart';
import '../../deck_repository.dart';
import '../../deck_text.dart';
import 'empty_focus_card.dart';
import 'focus_deck_card.dart';
import 'recent_deck_tile.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({
    super.key,
    required this.isDark,
    required this.onCreateDeck,
    required this.onOpenDecksTab,
    required this.onOpenProfileTab,
  });

  final bool isDark;
  final VoidCallback onCreateDeck;
  final VoidCallback onOpenDecksTab;
  final VoidCallback onOpenProfileTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(
      decksPageProvider(AppConstants.kLocalPageSize),
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Responsive.constrainedContent(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    isDark: isDark,
                    onOpenProfileTab: onOpenProfileTab,
                  ),
                  const SizedBox(height: AppDimensions.xxl),
                  decksAsync.when(
                    loading: () => const LoadingState(),
                    error: (_, __) =>
                        const ErrorState(message: DeckText.loadError),
                    data: (decks) {
                      final hasDecks = decks.isNotEmpty;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          hasDecks
                              ? FocusDeckCard(
                                  deck: decks.first,
                                  isDark: isDark,
                                )
                              : EmptyFocusCard(
                                  isDark: isDark,
                                  onCreateDeck: onCreateDeck,
                                ),
                          const SizedBox(height: AppDimensions.xxl),
                          const MissingApiKeyCard(),
                          const SizedBox(height: AppDimensions.lg),
                          const BackupReminderCard(),
                          if (hasDecks) ...[
                            const SizedBox(height: AppDimensions.lg),
                            StudyStatsCard(isDark: isDark),
                            const SizedBox(height: AppDimensions.xxl),
                            _RecentDecksHeader(
                              isDark: isDark,
                              onOpenDecksTab: onOpenDecksTab,
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            _RecentDecksList(
                              isDark: isDark,
                              decks: decks,
                            ),
                            const SizedBox(height: AppDimensions.xxl),
                            NeonButton(
                              label: DeckText.createAiDeck,
                              subtitle: DeckText.aiDeckCaption,
                              icon: Icons.auto_awesome,
                              onPressed: onCreateDeck,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isDark,
    required this.onOpenProfileTab,
  });

  final bool isDark;
  final VoidCallback onOpenProfileTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.35),
                    AppColors.neonCyan.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(
                  color: AppColors.glassBorderDark,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGlow.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppColors.neonCyan,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DeckText.title,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDark
                        ? [AppColors.textPrimaryDark, AppColors.neonCyan]
                        : [AppColors.textPrimary, AppColors.primary],
                  ).createShader(bounds),
                  child: Text(
                    _greeting(),
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.surfaceDeep.withValues(alpha: 0.6)
                : AppColors.surface.withValues(alpha: 0.8),
            side: BorderSide(
              color: isDark
                  ? AppColors.glassBorderDark
                  : AppColors.glassBorderLight,
            ),
          ),
          icon: Icon(
            Icons.account_circle_outlined,
            color: isDark ? AppColors.neonCyan : AppColors.primary,
            size: 24,
          ),
          onPressed: onOpenProfileTab,
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return DeckText.goodMorning;
    }
    if (hour >= 12 && hour < 18) {
      return DeckText.goodAfternoon;
    }
    return DeckText.goodEvening;
  }
}

class _RecentDecksHeader extends StatelessWidget {
  const _RecentDecksHeader({
    required this.isDark,
    required this.onOpenDecksTab,
  });

  final bool isDark;
  final VoidCallback onOpenDecksTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DeckText.recentDecks,
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onOpenDecksTab,
          child: Text(
            DeckText.seeAll,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentDecksList extends StatelessWidget {
  const _RecentDecksList({required this.isDark, required this.decks});

  final bool isDark;
  final List<DeckModel> decks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: decks
          .take(3)
          .map((deck) => RecentDeckTile(deck: deck, isDark: isDark))
          .toList(),
    );
  }
}
