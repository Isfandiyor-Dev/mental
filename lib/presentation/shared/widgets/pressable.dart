import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps any child with a spring-y press response plus haptics.
///
/// Preferred over [InkWell] here because the design has no Material ripple —
/// feedback is physical (scale) rather than pigment.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
    this.haptic = HapticStrength.selection,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final HapticStrength haptic;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

enum HapticStrength { none, selection, light, medium }

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    reverseDuration: const Duration(milliseconds: 260),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1, end: widget.pressedScale).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut, reverseCurve: Curves.easeOutBack),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onTap != null;

  void _fireHaptic() {
    switch (widget.haptic) {
      case HapticStrength.none:
        break;
      case HapticStrength.selection:
        HapticFeedback.selectionClick();
      case HapticStrength.light:
        HapticFeedback.lightImpact();
      case HapticStrength.medium:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _enabled ? (_) => _controller.forward() : null,
      onTapUp: _enabled ? (_) => _controller.reverse() : null,
      onTapCancel: _enabled ? () => _controller.reverse() : null,
      onTap: _enabled
          ? () {
              _fireHaptic();
              widget.onTap!.call();
            }
          : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
