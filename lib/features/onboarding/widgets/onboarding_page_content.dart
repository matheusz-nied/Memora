import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../onboarding_page_model.dart';
import 'onboarding_hero_visual.dart';

class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    super.key,
    required this.page,
    required this.isDark,
    required this.showBrand,
  });

  final OnboardingPageModel page;
  final bool isDark;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textSecDark : AppColors.textSecondary;
    final primaryTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final accentColor = isDark ? AppColors.neonCyan : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showBrand) ...[
                  Text(
                    AppConstants.appName.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: accentColor,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xxl),
                ],
                OnboardingHeroVisual(
                  visualType: page.visualType,
                  isDark: isDark,
                ),
                const SizedBox(height: AppDimensions.xxxl),
                _AccentTitle(
                  title: page.title,
                  accent: page.titleAccent,
                  baseColor: primaryTextColor,
                  accentColor: accentColor,
                ),
                const SizedBox(height: AppDimensions.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                  ),
                  child: Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: secondaryColor,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccentTitle extends StatelessWidget {
  const _AccentTitle({
    required this.title,
    required this.accent,
    required this.baseColor,
    required this.accentColor,
  });

  final String title;
  final String accent;
  final Color baseColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final accentIndex = title.indexOf(accent);
    if (accentIndex < 0) {
      return Text(
        title,
        textAlign: TextAlign.center,
        style: AppTypography.displayLarge.copyWith(color: baseColor),
      );
    }

    final before = title.substring(0, accentIndex);
    final after = title.substring(accentIndex + accent.length);

    return Text.rich(
      TextSpan(
        style: AppTypography.displayLarge.copyWith(color: baseColor),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: accent,
            style: TextStyle(color: accentColor),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
