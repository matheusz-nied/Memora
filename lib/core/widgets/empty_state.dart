import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'glass_panel.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: GlassPanel(
          isDark: isDark,
          showGlow: false,
          borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppDimensions.lg),
                  child: Icon(Icons.style, color: AppColors.primary, size: 32),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headingMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecDark
                      : AppColors.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppDimensions.lg),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
