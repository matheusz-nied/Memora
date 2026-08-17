import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/deepseek_key_store.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../api_key_text.dart';

/// Chamada para cadastrar a chave da DeepSeek, exibida enquanto não houver uma.
class MissingApiKeyCard extends ConsumerWidget {
  const MissingApiKeyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(deepSeekKeyProvider) != null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: () => context.push(RouteConstants.kRouteApiKey),
      child: GlassPanel(
        isDark: isDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderColor: AppColors.warning.withValues(alpha: 0.25),
        showGlow: false,
        showTopHighlight: false,
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppDimensions.sm),
                child: Icon(Icons.key_off_outlined, color: AppColors.warning),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ApiKeyText.dashboardTitle,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    ApiKeyText.dashboardMessage,
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
              color: AppColors.warning.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}
