import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/soft_progress_bar.dart';
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: PressableScale(
        onTap: () => context.push(RouteConstants.deckPath(deck.id)),
        child: GlassPanel(
          isDark: isDark,
          showGlow: false,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          padding: const EdgeInsets.all(AppDimensions.xl),
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
                            fontSize: 18,
                          ),
                        ),
                        if (deck.description != null &&
                            deck.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            deck.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecDark
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      countsAsync.maybeWhen(
                        data: (counts) {
                          final due = counts.due;
                          final isDone = due == 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isDone
                                    ? AppColors.success.withValues(alpha: 0.25)
                                    : AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              isDone ? 'Concluído' : '$due Pendentes',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDone
                                    ? AppColors.success
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<_DeckAction>(
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark
                              ? AppColors.textSecDark
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                            child: Text(
                              DeckText.delete,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
              countsAsync.maybeWhen(
                data: (counts) {
                  final total = counts.total;
                  final due = counts.due;
                  final percent = total == 0
                      ? 100
                      : (((total - due) / total) * 100).round();
                  final progress = total == 0
                      ? 1.0
                      : (total - due) / total;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecDark
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SoftProgressBar(progress: progress, isDark: isDark),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DeckAction { edit, delete }
