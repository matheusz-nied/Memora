import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';
import 'glass_panel.dart';

class GlassSearchField extends StatelessWidget {
  const GlassSearchField({
    super.key,
    required this.isDark,
    required this.controller,
    required this.hintText,
    required this.hasQuery,
    this.onClear,
  });

  final bool isDark;
  final TextEditingController controller;
  final String hintText;
  final bool hasQuery;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      showTopHighlight: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: AppDimensions.minTouchTarget,
        child: TextField(
          controller: controller,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
            ),
            suffixIcon: hasQuery && onClear != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
