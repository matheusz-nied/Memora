import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// Subtle press feedback for tappable elements.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.97,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppDimensions.animFast,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
