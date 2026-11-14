import 'package:flutter/material.dart';

/// Fades and lifts a child into place along a shared parent timeline, offset by
/// [index]. One controller drives an entire screen's entrance this way.
class StaggerIn extends StatelessWidget {
  const StaggerIn({
    super.key,
    required this.animation,
    required this.index,
    required this.child,
    this.itemCount = 8,
    this.offset = 26,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  /// Number of slots the timeline is divided into; larger means tighter overlap.
  final int itemCount;

  /// Vertical travel in logical pixels.
  final double offset;

  @override
  Widget build(BuildContext context) {
    final double start = (index / itemCount).clamp(0.0, 0.85);
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - curved.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
