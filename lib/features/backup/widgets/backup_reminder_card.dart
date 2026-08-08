import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../decks/deck_repository.dart';
import '../backup_reminder.dart';
import '../backup_text.dart';

/// Lembra de exportar quando faz tempo demais — ou quando nunca aconteceu.
///
/// Só aparece para quem já tem o que perder: num app recém-instalado, sem deck
/// nenhum, o aviso seria ruído antes de existir conteúdo, e a primeira lição
/// que o usuário aprenderia era a ignorá-lo.
class BackupReminderCard extends ConsumerWidget {
  const BackupReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Material(
      color: AppColors.infoBg,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () => context.push(RouteConstants.kRouteBackup),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            children: [
              const Icon(Icons.save_alt_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      BackupText.reminderTitle,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      BackupText.reminderMessage,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
