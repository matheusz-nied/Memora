import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../auth_text.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.borderDarkStrong : AppColors.border;
    final textColor = isDark ? AppColors.textTertDark : AppColors.textSecondary;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
              child: Text(
                AuthText.continueWith,
                style: AppTypography.bodyMedium.copyWith(color: textColor),
              ),
            ),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        const SizedBox(height: AppDimensions.xxl),
        Row(
          children: const [
            Expanded(
              child: _SocialButton(
                label: AuthText.google,
                icon: Icons.g_mobiledata,
              ),
            ),
            SizedBox(width: AppDimensions.lg),
            Expanded(
              child: _SocialButton(label: AuthText.apple, icon: Icons.apple),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderStrong;
    final foreground = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final background = isDark ? AppColors.surfaceSubtle : AppColors.surface;

    return Tooltip(
      message: AuthText.socialUnavailable,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon, size: AppDimensions.xxl),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.minTouchTarget),
          disabledForegroundColor: foreground,
          disabledBackgroundColor: background,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
        ),
      ),
    );
  }
}
