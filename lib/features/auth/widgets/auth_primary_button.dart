import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppDimensions.minTouchTarget),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.primaryLight,
        disabledForegroundColor: AppColors.surface,
        shadowColor: AppColors.primaryStrongShadow,
        elevation: AppDimensions.xs,
        textStyle: AppTypography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.lg,
        ),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: AppDimensions.xl,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Center(child: Text(label)),
                if (icon != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(icon, size: AppDimensions.xl),
                  ),
              ],
            ),
    );
  }
}
