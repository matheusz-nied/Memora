import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../legal/legal_text.dart';
import '../onboarding_page_model.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.showSkip,
    required this.isDark,
    required this.onSkip,
  });

  final bool showSkip;
  final bool isDark;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.minTouchTarget,
      child: Row(
        children: [
          const Spacer(),
          AnimatedOpacity(
            duration: AppDimensions.animNormal,
            opacity: showSkip ? 1 : 0,
            child: IgnorePointer(
              ignoring: !showSkip,
              child: PressableScale(
                onTap: onSkip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.sm,
                  ),
                  child: Text(
                    OnboardingText.skip,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageIndicators extends StatelessWidget {
  const OnboardingPageIndicators({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.isDark,
  });

  final int count;
  final int activeIndex;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        isDark ? AppColors.borderDarkStrong : AppColors.border;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: AppDimensions.animNormal,
          curve: Curves.easeOutCubic,
          width: isActive ? AppDimensions.xxl : AppDimensions.sm,
          height: AppDimensions.sm,
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : inactiveColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.isLastPage,
    required this.onPrimary,
    required this.onSkipKey,
    required this.onOpenPolicy,
    required this.isDark,
  });

  final bool isLastPage;
  final VoidCallback onPrimary;
  final VoidCallback onSkipKey;
  final VoidCallback onOpenPolicy;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tertiaryColor =
        isDark ? AppColors.textTertDark : AppColors.textTertiary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeonButton(
          label: isLastPage ? OnboardingText.setupKey : OnboardingText.next,
          icon: isLastPage ? Icons.key_rounded : Icons.arrow_forward_rounded,
          onPressed: onPrimary,
        ),
        AnimatedCrossFade(
          duration: AppDimensions.animNormal,
          crossFadeState: isLastPage
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: AppDimensions.md),
              AppButton(
                label: OnboardingText.skipKey,
                variant: AppButtonVariant.secondary,
                onPressed: onSkipKey,
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(
                LegalText.consent,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: tertiaryColor),
              ),
              TextButton(
                onPressed: onOpenPolicy,
                child: Text(
                  LegalText.openPolicy,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.neonCyan : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
