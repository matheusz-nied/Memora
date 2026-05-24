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

class LibraryDeckCard extends ConsumerWidget {
  const LibraryDeckCard({
    super.key,
    required this.deck,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final DeckModel deck;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(deckCardCountsStreamProvider(deck.id));

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.05)
              : AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () => context.push(RouteConstants.deckPath(deck.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headingMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (deck.description != null &&
                            deck.description!.isNotEmpty) ...[
                          const SizedBox(height: AppDimensions.xs),
                          Text(
                            deck.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<_DeckAction>(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case _DeckAction.edit:
                          onEdit();
                        case _DeckAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _DeckAction.edit,
                        child: Text(DeckText.edit),
                      ),
                      PopupMenuItem(
                        value: _DeckAction.delete,
                        child: Text(DeckText.delete),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  _SyncPill(syncPending: deck.syncPending),
                  const Spacer(),
                  countsAsync.maybeWhen(
                    data: (counts) {
                      return Text(
                        '${counts.total} ${DeckText.cards} (${counts.due} ${DeckText.dueToday})',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecDark
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.syncPending});

  final bool syncPending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: syncPending ? AppColors.warningBg : AppColors.successBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        syncPending ? DeckText.pending : DeckText.synced,
        style: AppTypography.labelSmall.copyWith(
          color: syncPending ? AppColors.warning : AppColors.success,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

enum _DeckAction { edit, delete }
