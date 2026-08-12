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

    final reminder = ref.watch(backupReminderProvider);
    final show = shouldShowBackupReminder(
      lastExportAt: reminder.lastExportAt,
      dismissedAt: reminder.dismissedAt,
      now: DateTime.now(),
    );
    if (!show) {
      return const SizedBox.shrink();
    }

    final secondaryColor =
        isDark ? AppColors.textSecDark : AppColors.textSecondary;

    return GlassPanel(
      isDark: isDark,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      borderColor: AppColors.primary.withValues(alpha: 0.25),
      glowColor: AppColors.primary,
      showTopHighlight: false,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Stack(
        children: [
          PressableScale(
            onTap: () => context.push(RouteConstants.kRouteBackup),
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
                      Padding(
                        // Reserva espaço para o botão de dispensar no canto.
                        padding: const EdgeInsets.only(right: 40),
                        child: Text(
                          BackupText.reminderTitle,
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        BackupText.reminderMessage,
                        style: AppTypography.bodySmall.copyWith(
                          color: secondaryColor,
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
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              tooltip: BackupText.reminderDismiss,
              style: IconButton.styleFrom(
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                Icons.close_rounded,
                color: secondaryColor,
                size: 20,
                semanticLabel: BackupText.reminderDismiss,
              ),
              onPressed: () {
                ref.read(backupReminderProvider.notifier).dismiss();
              },
            ),
          ),
        ],
      ),
    );
  }
}
