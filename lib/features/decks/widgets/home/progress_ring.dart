import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.size = 180,
    this.strokeWidth = 8,
    this.animate = true,
    this.glow = false,
    required this.child,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double size;
  final double strokeWidth;
  final bool animate;
  final bool glow;
  final Widget child;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDimensions.animSlow,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress && widget.animate) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _ProgressRingPainter(
                  progress: widget.progress * _animation.value,
                  trackColor: widget.trackColor,
                  progressColor: widget.progressColor,
                  strokeWidth: widget.strokeWidth,
                  glow: widget.glow,
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
    this.glow = false,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;

    if (glow) {
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * clamped, false, glowPaint);
    }

    final progressPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          progressColor,
          Color.lerp(progressColor, AppColors.neonBlue, 0.35)!,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * clamped, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glow != glow;
  }
}
