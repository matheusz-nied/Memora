import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/models/ai_quota_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../ai_quota_provider.dart';
import '../quota_text.dart';

/// Mostra quanto o usuário já consumiu de IA no mês.
///
/// O teto é aplicado no servidor (`consume_ai_quota`); esta é apenas a leitura,
/// para o limite não chegar como surpresa no meio de uma geração.
class AiQuotaCard extends ConsumerWidget {
  const AiQuotaCard({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotaAsync = ref.watch(aiQuotaStatusProvider);

    return _Shell(
      isDark: isDark,
      child: quotaAsync.when(
        loading: () => const SizedBox(
          height: AppDimensions.huge,
          child: Center(
            child: SizedBox(
              width: AppDimensions.xxl,
              height: AppDimensions.xxl,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => _ErrorBody(
          isDark: isDark,
          onRetry: () => ref.invalidate(aiQuotaStatusProvider),
        ),
        data: (status) => _QuotaBody(status: status, isDark: isDark),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: child,
    );
  }
}

class _QuotaBody extends StatelessWidget {
  const _QuotaBody({required this.status, required this.isDark});

  final AiQuotaStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final barColor = status.isExhausted
        ? AppColors.error
        : status.ratio >= 0.8
        ? AppColors.warning
        : AppColors.primary;

    final primaryText = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final secondaryText = isDark
        ? AppColors.textSecDark
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: AppDimensions.lg, color: barColor),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text(
                QuotaText.title,
                style: AppTypography.labelSmall.copyWith(
                  color: secondaryText,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Text(
              status.tier == 'premium'
                  ? QuotaText.tierPremium
                  : QuotaText.tierFree,
              style: AppTypography.labelSmall.copyWith(color: secondaryText),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Text(
          status.isExhausted
              ? QuotaText.exhausted
              : QuotaText.usage(status.used, status.quota),
          style: AppTypography.headingMedium.copyWith(color: primaryText),
        ),
        const SizedBox(height: AppDimensions.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: LinearProgressIndicator(
            value: status.ratio,
            minHeight: 6,
            backgroundColor: isDark
                ? AppColors.borderDarkStrong
                : AppColors.borderStrong,
            color: barColor,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          QuotaText.renewal(status.periodEnd),
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          QuotaText.costHint,
          style: AppTypography.bodySmall.copyWith(color: secondaryText),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.isDark, required this.onRetry});

  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            QuotaText.loadError,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text(QuotaText.retry)),
      ],
    );
  }
}
