import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../deck_text.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/neon_button.dart';

class EmptyFocusCard extends StatefulWidget {
  const EmptyFocusCard({
    super.key,
    required this.isDark,
    required this.onCreateDeck,
  });

  final bool isDark;
  final VoidCallback onCreateDeck;

  @override
  State<EmptyFocusCard> createState() => _EmptyFocusCardState();
}

class _EmptyFocusCardState extends State<EmptyFocusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  static bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AppDimensions.animPulse,
      value: 0.5,
    );
    if (!_isWidgetTest) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: widget.isDark,
      padding: const EdgeInsets.all(AppDimensions.xxl),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Container(
                width: AppDimensions.huge + AppDimensions.lg,
                height: AppDimensions.huge + AppDimensions.lg,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGlow.withValues(
                        alpha: 0.25 + _pulse.value * 0.25,
                      ),
                      blurRadius: AppDimensions.glowBlur + _pulse.value * 12,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.neonCyan.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: AppColors.glassBorderDark,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: AppDimensions.huge,
                color: AppColors.neonBlue,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            DeckText.emptyTitle,
            style: AppTypography.headingMedium.copyWith(
              color: widget.isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            DeckText.emptyMessage,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: widget.isDark
                  ? AppColors.textSecDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          NeonButton(
            label: DeckText.newDeck,
            icon: Icons.add_rounded,
            onPressed: widget.onCreateDeck,
            expand: false,
          ),
        ],
      ),
    );
  }
}
