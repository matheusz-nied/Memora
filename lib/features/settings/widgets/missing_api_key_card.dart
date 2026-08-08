import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/deepseek_key_store.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../api_key_text.dart';

/// Chamada para cadastrar a chave da DeepSeek, exibida enquanto não houver uma.
///
/// Fecha o buraco mais provável da primeira execução: sem este aviso, o usuário
/// só descobre que precisa de chave quando a primeira geração falha — e nesse
/// ponto ele já escreveu o material e escolheu a quantidade.
class MissingApiKeyCard extends ConsumerWidget {
  const MissingApiKeyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(deepSeekKeyProvider) != null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.warningBg,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () => context.push(RouteConstants.kRouteApiKey),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            children: [
              const Icon(Icons.key_off_outlined, color: AppColors.warning),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ApiKeyText.dashboardTitle,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      ApiKeyText.dashboardMessage,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}
