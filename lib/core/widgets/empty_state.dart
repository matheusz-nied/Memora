import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'glass_panel.dart';
import 'pressable_scale.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.compactAction = false,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final bool compactAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final panel = GlassPanel(
      isDark: isDark,
      showGlow: false,
      borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              compactAction
                  ? _CompactActionButton(
                      label: actionLabel!,
                      icon: actionIcon ?? Icons.add_rounded,
                      onPressed: onAction,
                    )
                  : AppButton(
                      label: actionLabel!,
                      icon: actionIcon,
                      onPressed: onAction,
                    ),
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: panel,
        );

        // Unbounded height: let the parent scroll view size to the content.
        if (!constraints.hasBoundedHeight) {
          return content;
        }

        // Bounded height: scroll internally and keep content centered.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Align(
      alignment: Alignment.center,
      child: PressableScale(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: AppDimensions.animNormal,
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? [AppColors.primary, AppColors.primaryHover]
                  : [
                      AppColors.primary.withValues(alpha: 0.4),
                      AppColors.primaryHover.withValues(alpha: 0.4),
                    ],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primaryStrongShadow.withValues(
                        alpha: 0.45,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.surface),
              const SizedBox(width: AppDimensions.xs),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
