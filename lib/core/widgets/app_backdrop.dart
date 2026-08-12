import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Animated ambient glow orbs used as the app background shell.
class AppBackdrop extends StatefulWidget {
  const AppBackdrop({super.key, required this.isDark, this.animate = true});

  final bool isDark;
  final bool animate;

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _shouldAnimate =>
      widget.animate && !_isWidgetTest && TickerMode.valuesOf(context).enabled;

  static bool get _isWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
      value: 0.35,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldAnimate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!_shouldAnimate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? AppColors.depthDark : AppColors.background;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.isDark
                  ? [AppColors.depthDark, AppColors.backgroundDark, base]
                  : [
                      AppColors.background,
                      AppColors.primaryLight.withValues(alpha: 0.15),
                    ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _GlowOrb(
                alignment: Alignment(-0.85 + t * 0.15, -0.95 + t * 0.08),
                color: AppColors.primary.withValues(
                  alpha: widget.isDark ? 0.22 : 0.12,
                ),
                size: 280,
              ),
              _GlowOrb(
                alignment: Alignment(0.9 - t * 0.12, -0.55 + t * 0.1),
                color: AppColors.neonCyan.withValues(
                  alpha: widget.isDark ? 0.1 : 0.08,
                ),
                size: 220,
              ),
              _GlowOrb(
                alignment: Alignment(-0.3 + math.sin(t * math.pi) * 0.1, 0.75),
                color: AppColors.neonBlue.withValues(
                  alpha: widget.isDark ? 0.08 : 0.06,
                ),
                size: 260,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
