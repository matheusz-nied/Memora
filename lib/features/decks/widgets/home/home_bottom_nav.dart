import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../deck_text.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.isDark,
    required this.onChanged,
  });

  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.radiusLg),
        topRight: Radius.circular(AppDimensions.radiusLg),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppDimensions.glassBlur,
          sigmaY: AppDimensions.glassBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.glassDark.withValues(alpha: 0.88)
                : AppColors.glassLight.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.glassBorderDark
                    : AppColors.glassBorderLight,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      index: 0,
                      icon: Icons.dashboard,
                      label: DeckText.dashboard,
                      currentIndex: currentIndex,
                      isDark: isDark,
                      onChanged: onChanged,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      index: 1,
                      icon: Icons.style,
                      label: DeckText.decks,
                      currentIndex: currentIndex,
                      isDark: isDark,
                      onChanged: onChanged,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      index: 2,
                      icon: Icons.person,
                      label: DeckText.profile,
                      currentIndex: currentIndex,
                      isDark: isDark,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.currentIndex,
    required this.isDark,
    required this.onChanged,
  });

  final int index;
  final IconData icon;
  final String label;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    final color = isActive
        ? AppColors.primary
        : (isDark ? AppColors.textSecDark : AppColors.textSecondary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(index),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: AppDimensions.xs,
              width: AppDimensions.xs,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
