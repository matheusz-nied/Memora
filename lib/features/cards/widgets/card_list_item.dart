import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../card_model.dart';
import '../card_text.dart';

class CardListItem extends StatelessWidget {
  const CardListItem({
    super.key,
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  final CardModel card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: null,
      child: GlassPanel(
        isDark: isDark,
        showGlow: false,
        showTopHighlight: false,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.front,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headingMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<_CardAction>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: isDark
                        ? AppColors.textSecDark
                        : AppColors.textSecondary,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _CardAction.edit:
                        onEdit();
                      case _CardAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _CardAction.edit,
                      child: Text(CardText.edit),
                    ),
                    PopupMenuItem(
                      value: _CardAction.delete,
                      child: Text(CardText.delete),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              card.back,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CardAction { edit, delete }
