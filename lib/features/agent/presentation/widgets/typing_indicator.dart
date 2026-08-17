import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

/// Animated typing indicator (three bouncing dots) shown while the AI is
/// generating a response.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(top: AppDimensions.xs),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.85),
                AppColors.neonBlue.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Padding(
          padding: const EdgeInsets.only(top: AppDimensions.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = _bounce(_controller.value, index);
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  );
                },
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Creates a staggered bounce effect for each dot.
  double _bounce(double t, int index) {
    final delayed = (t - index * 0.15) % 1.0;
    if (delayed < 0.4) {
      return -6.0 * (0.5 - (delayed / 0.4 - 0.5).abs()) * 2;
    }
    return 0;
  }
}
