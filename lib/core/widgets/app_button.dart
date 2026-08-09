import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'pressable_scale.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    if (variant == AppButtonVariant.primary) {
      final enabled = effectiveOnPressed != null;

      return PressableScale(
        onTap: effectiveOnPressed,
        child: AnimatedContainer(
          duration: AppDimensions.animNormal,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            color: enabled
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.md,
              horizontal: AppDimensions.xxl,
            ),
            child: _buildChild(context, onPrimary: true),
          ),
        ),
      );
    }

    final child = _buildChild(context);

    return switch (variant) {
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.primary => throw StateError('Handled above'),
    };
  }

  Widget _buildChild(BuildContext context, {bool onPrimary = false}) {
    if (isLoading) {
      return SizedBox.square(
        dimension: AppDimensions.xl,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: onPrimary ? AppColors.surface : null,
        ),
      );
    }

    final textStyle = onPrimary
        ? AppTypography.bodyLarge.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.bold,
          )
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: AppDimensions.sm),
          Icon(
            icon,
            size: AppDimensions.xl,
            color: onPrimary ? AppColors.surface : null,
          ),
        ],
      ],
    );
  }
}

enum AppButtonVariant { primary, secondary, text }
