import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_mode.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../auth/auth_repository.dart';
import '../../../auth/profile_text.dart';
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
    required this.onRefresh,
    required this.onCreateDeck,
    required this.onOpenDecksTab,
    required this.onOpenProfileTab,
  });

  final bool isDark;
  final RefreshCallback onRefresh;
  final VoidCallback onCreateDeck;
  final VoidCallback onOpenDecksTab;
  final VoidCallback onOpenProfileTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(
      decksPageProvider(AppConstants.kLocalPageSize),
    );
    final session = ref.watch(authStateProvider).value;
    // No modo local a "sessão" é o aparelho e o nome sairia como "Perfil
    // local": saudar sem nome é mais honesto do que cumprimentar um rótulo
    // interno do app.
    final userName = kIsCloudMode
        ? (session?.user.displayName?.trim().isNotEmpty == true
              ? session!.user.displayName!
              : ProfileText.authenticatedUser)
        : null;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Responsive.constrainedContent(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  isDark: isDark,
                  userName: userName,
                  onOpenProfileTab: onOpenProfileTab,
                ),
                const SizedBox(height: AppDimensions.xxl),
                decksAsync.when(
                  loading: () => const LoadingState(),
                  error: (_, __) =>
                      const ErrorState(message: DeckText.loadError),
                  data: (decks) => decks.isEmpty
                      ? EmptyFocusCard(
                          isDark: isDark,
                          onCreateDeck: onCreateDeck,
                        )
                      : FocusDeckCard(deck: decks.first, isDark: isDark),
                ),
                const SizedBox(height: AppDimensions.xxl),
                // Sem chave cadastrada, toda a IA falha na primeira tentativa.
                // O aviso vem antes de qualquer CTA que dependa dela.
                if (kIsLocalMode) ...[
                  const MissingApiKeyCard(),
                  const SizedBox(height: AppDimensions.xxl),
                  // Sem nuvem, exportar é a única forma de sobreviver à perda
                  // do aparelho.
                  const BackupReminderCard(),
                ],
                StudyStatsCard(isDark: isDark),
                const SizedBox(height: AppDimensions.xxl),
                _RecentDecksHeader(
                  isDark: isDark,
                  onOpenDecksTab: onOpenDecksTab,
                ),
                const SizedBox(height: AppDimensions.sm),
                _RecentDecksList(isDark: isDark, decksAsync: decksAsync),
                const SizedBox(height: AppDimensions.xxl),
                _CreateAiDeckCta(onCreateDeck: onCreateDeck),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isDark,
    required this.userName,
    required this.onOpenProfileTab,
  });

  final bool isDark;
  final String? userName;
  final VoidCallback onOpenProfileTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                border: Border.all(
                  color: isDark
                      ? AppColors.surface.withValues(alpha: 0.1)
                      : AppColors.textPrimary.withValues(alpha: 0.05),
                ),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
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
                  ),
                ),
                Text(
                  _greeting(),
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecDark
                        : AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userName != null)
                  Text(
                    userName!,
                    style: AppTypography.headingLarge.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.account_circle_outlined,
            color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
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
      return DeckText.goodMorning.toUpperCase();
    }
    if (hour >= 12 && hour < 18) {
      return DeckText.goodAfternoon.toUpperCase();
    }
    return DeckText.goodEvening.toUpperCase();
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
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentDecksList extends StatelessWidget {
  const _RecentDecksList({required this.isDark, required this.decksAsync});

  final bool isDark;
  final AsyncValue<List<DeckModel>> decksAsync;

  @override
  Widget build(BuildContext context) {
    return decksAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Text(DeckText.loadError),
      data: (decks) {
        if (decks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Center(
              child: Text(
                DeckText.emptyMessage,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Column(
          children: decks
              .take(3)
              .map((deck) => RecentDeckTile(deck: deck, isDark: isDark))
              .toList(),
        );
      },
    );
  }
}

class _CreateAiDeckCta extends StatelessWidget {
  const _CreateAiDeckCta({required this.onCreateDeck});

  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryHover],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: AppDimensions.lg,
            offset: const Offset(0, AppDimensions.xs),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onCreateDeck,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.xl,
            horizontal: AppDimensions.xxl,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: AppColors.surface, size: 24),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    DeckText.createAiDeck,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.surface.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                DeckText.aiDeckCaption,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
