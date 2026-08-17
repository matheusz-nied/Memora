import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'pressable_scale.dart';

/// Primary CTA with fluid press animation and solid fill.
class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.subtitle,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? subtitle;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return PressableScale(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: AppDimensions.animNormal,
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          color: enabled
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.4),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: subtitle == null ? AppDimensions.lg : AppDimensions.xl,
            horizontal: AppDimensions.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.surface, size: 22),
                    const SizedBox(width: AppDimensions.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimensions.xs),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
