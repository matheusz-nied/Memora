import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../onboarding_page_model.dart';

/// Ilustração customizada por página — sem assets externos.
class OnboardingHeroVisual extends StatelessWidget {
  const OnboardingHeroVisual({
    super.key,
    required this.visualType,
    required this.isDark,
  });

  final OnboardingVisualType visualType;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.onboardingHeroSize + 48,
      height: AppDimensions.onboardingHeroSize + 32,
      child: switch (visualType) {
        OnboardingVisualType.study => _StudyVisual(isDark: isDark),
        OnboardingVisualType.ai => _AiVisual(isDark: isDark),
        OnboardingVisualType.privacy => _PrivacyVisual(isDark: isDark),
        OnboardingVisualType.apiKey => _ApiKeyVisual(isDark: isDark),
      },
    );
  }
}

class _GlowBackdrop extends StatelessWidget {
  const _GlowBackdrop({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          child: Container(
            width: AppDimensions.onboardingHeroSize,
            height: AppDimensions.onboardingHeroSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.isDark,
    this.width = 120,
    this.height = 76,
    this.rotation = 0,
    this.opacity = 1,
    this.accent = false,
  });

  final bool isDark;
  final double width;
  final double height;
  final double rotation;
  final double opacity;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: rotation * math.pi / 180,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.surfaceDeep,
                      AppColors.backgroundDark,
                    ]
                  : [
                      AppColors.surface,
                      AppColors.primaryLight.withValues(alpha: 0.35),
                    ],
            ),
            border: Border.all(
              color: accent
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : (isDark
                      ? AppColors.glassBorderDark
                      : AppColors.glassBorderLight),
            ),
            boxShadow: accent
                ? [
                    BoxShadow(
                      color: AppColors.neonGlow.withValues(
                        alpha: isDark ? 0.45 : 0.25,
                      ),
                      blurRadius: AppDimensions.glowBlur,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: accent ? 40 : 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accent
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textTertDark
                            : AppColors.textTertiary),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDarkStrong
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDarkStrong
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyVisual extends StatelessWidget {
  const _StudyVisual({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _GlowBackdrop(
      isDark: isDark,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 12,
            left: 8,
            child: _MiniCard(
              isDark: isDark,
              rotation: -8,
              opacity: 0.55,
              width: 100,
              height: 64,
            ),
          ),
          Positioned(
            top: 24,
            right: 4,
            child: _MiniCard(
              isDark: isDark,
              rotation: 6,
              opacity: 0.4,
              width: 96,
              height: 60,
            ),
          ),
          _MiniCard(isDark: isDark, accent: true),
          Positioned(
            bottom: 0,
            child: _DueBadge(isDark: isDark),
          ),
          Positioned(
            top: 0,
            right: 20,
            child: _FloatingChip(
              isDark: isDark,
              icon: Icons.schedule_rounded,
              color: AppColors.neonCyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDeep.withValues(alpha: 0.9)
            : AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: AppColors.neonCyan.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Text(
            '3 para hoje',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.neonCyan : AppColors.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiVisual extends StatelessWidget {
  const _AiVisual({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _GlowBackdrop(
      isDark: isDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DocIcon(isDark: isDark, icon: Icons.description_outlined),
              const SizedBox(width: AppDimensions.md),
              _DocIcon(isDark: isDark, icon: Icons.picture_as_pdf_outlined),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          _FlowArrow(isDark: isDark),
          const SizedBox(height: AppDimensions.sm),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _MiniCard(isDark: isDark, accent: true, width: 132, height: 84),
              Positioned(
                right: -12,
                bottom: -8,
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary.withValues(alpha: 0.9),
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocIcon extends StatelessWidget {
  const _DocIcon({required this.isDark, required this.icon});

  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        color: isDark
            ? AppColors.surfaceDeep.withValues(alpha: 0.8)
            : AppColors.surface.withValues(alpha: 0.9),
        border: Border.all(
          color: isDark ? AppColors.glassBorderDark : AppColors.border,
        ),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? AppColors.borderDarkStrong : AppColors.border,
              AppColors.primary.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),
    );
  }
}

class _PrivacyVisual extends StatelessWidget {
  const _PrivacyVisual({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _GlowBackdrop(
      isDark: isDark,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 130,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [AppColors.surfaceDeep, AppColors.depthDark]
                    : [AppColors.surface, AppColors.background],
              ),
              border: Border.all(
                color: isDark
                    ? AppColors.glassBorderDark
                    : AppColors.glassBorderLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: AppDimensions.glowBlur,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.md),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDarkStrong
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.folder_outlined,
                  size: 36,
                  color: isDark ? AppColors.neonCyan : AppColors.primary,
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  'Local',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
          Positioned(
            top: 28,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.surfaceDeep.withValues(alpha: 0.95)
                    : AppColors.surface,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.success,
                size: 26,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            child: _FloatingChip(
              isDark: isDark,
              icon: Icons.cloud_off_outlined,
              color: AppColors.neonBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyVisual extends StatelessWidget {
  const _ApiKeyVisual({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _GlowBackdrop(
      isDark: isDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.key_rounded,
              size: 44,
              color: isDark ? AppColors.neonCyan : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              color: isDark
                  ? AppColors.surfaceDeep.withValues(alpha: 0.85)
                  : AppColors.surface.withValues(alpha: 0.95),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'DeepSeek API',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.isDark,
    required this.icon,
    required this.color,
  });

  final bool isDark;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        color: isDark
            ? AppColors.glassDark.withValues(alpha: 0.9)
            : AppColors.glassLight,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
