import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../decks/deck_repository.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../backup_reminder.dart';
import '../backup_text.dart';

/// Lembra de exportar quando faz tempo demais — ou quando nunca aconteceu.
class BackupReminderCard extends ConsumerWidget {
  const BackupReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDecks = ref
        .watch(decksStreamProvider)
        .maybeWhen(data: (decks) => decks.isNotEmpty, orElse: () => false);
    if (!hasDecks) {
      return const SizedBox.shrink();
    }

    final overdue = isBackupOverdue(
      lastExportAt: ref.watch(backupReminderProvider),
      now: DateTime.now(),
    );
    if (!overdue) {
      return const SizedBox.shrink();
    }

    return PressableScale(
      onTap: () => context.push(RouteConstants.kRouteBackup),
      child: GlassPanel(
        isDark: isDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderColor: AppColors.primary.withValues(alpha: 0.25),
        glowColor: AppColors.primary,
        showTopHighlight: false,
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppDimensions.sm),
                child: Icon(
                  Icons.save_alt_outlined,
                  color: AppColors.neonCyan,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BackupText.reminderTitle,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    BackupText.reminderMessage,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.neonCyan : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
