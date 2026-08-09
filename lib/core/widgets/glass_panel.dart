import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Frosted glass surface with subtle neon edge and light reflection.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.isDark,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.glowColor,
    this.showTopHighlight = true,
    this.showGlow = true,
  });

  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final Color? glowColor;
  final bool showTopHighlight;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppDimensions.radius2Xl);
    final glow = glowColor ?? AppColors.neonGlow;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: glow.withValues(alpha: isDark ? 0.35 : 0.18),
                    blurRadius: AppDimensions.glowBlur,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                  if (isDark)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: AppDimensions.glowBlurStrong,
                      spreadRadius: -8,
                    ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppDimensions.glassBlur,
              sigmaY: AppDimensions.glassBlur,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.glassDark.withValues(alpha: 0.85),
                          AppColors.surfaceDeep.withValues(alpha: 0.72),
                        ]
                      : [
                          AppColors.glassLight,
                          AppColors.surface.withValues(alpha: 0.92),
                        ],
                ),
                border: Border.all(
                  color: borderColor ??
                      (isDark
                          ? AppColors.glassBorderDark
                          : AppColors.glassBorderLight),
                ),
              ),
              child: Stack(
                children: [
                  if (showTopHighlight)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              (isDark
                                      ? AppColors.glassHighlight
                                      : AppColors.primary.withValues(alpha: 0.12))
                                  .withValues(alpha: isDark ? 1 : 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: padding ?? EdgeInsets.zero,
                    child: child,
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
