import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// A bespoke discrete slider.
///
/// Built from scratch rather than themed on top of [Slider] so the track, the
/// gradient fill and the thumb's grow-on-grab behaviour match the rest of the
/// design exactly, and so the widget can emit crisp integer steps with a haptic
/// tick on every one.
class NeoSlider extends StatefulWidget {
  const NeoSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.step = 1,
  })  : assert(min < max),
        assert(step > 0);

  final int value;
  final int min;
  final int max;
  final int step;

  /// Fires continuously while dragging.
  final ValueChanged<int> onChanged;

  /// Fires once the interaction settles — on release, or immediately after a
  /// tap. Lets the listener defer expensive work until the value is final.
  final VoidCallback? onChangeEnd;

  @override
  State<NeoSlider> createState() => _NeoSliderState();
}

class _NeoSliderState extends State<NeoSlider> with SingleTickerProviderStateMixin {
  static const double _thumbRadius = 13;
  static const double _height = 44;

  late final AnimationController _grab = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _grab.dispose();
    super.dispose();
  }

  double get _fraction => (widget.value - widget.min) / (widget.max - widget.min);

  void _emitFromDx(double dx, double width) {
    final double usable = width - _thumbRadius * 2;
    if (usable <= 0) return;

    final double fraction = ((dx - _thumbRadius) / usable).clamp(0.0, 1.0);
    final int span = widget.max - widget.min;
    final int steps = (fraction * span / widget.step).round();
    final int next = (widget.min + steps * widget.step).clamp(widget.min, widget.max);

    if (next != widget.value) {
      HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails d) {
            // A tap is a complete interaction on its own.
            _emitFromDx(d.localPosition.dx, width);
            widget.onChangeEnd?.call();
          },
          onHorizontalDragStart: (DragStartDetails d) {
            _grab.forward();
            _emitFromDx(d.localPosition.dx, width);
          },
          onHorizontalDragUpdate: (DragUpdateDetails d) =>
              _emitFromDx(d.localPosition.dx, width),
          onHorizontalDragEnd: (_) {
            _grab.reverse();
            widget.onChangeEnd?.call();
          },
          onHorizontalDragCancel: () {
            _grab.reverse();
            widget.onChangeEnd?.call();
          },
          child: SizedBox(
            height: _height,
            width: width,
            child: AnimatedBuilder(
              animation: _grab,
              builder: (BuildContext context, _) {
                return TweenAnimationBuilder<double>(
                  // Smooths taps that jump the thumb across the track.
                  tween: Tween<double>(begin: _fraction, end: _fraction),
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  builder: (BuildContext context, double fraction, _) {
                    return CustomPaint(
                      painter: _SliderPainter(
                        fraction: fraction,
                        grab: Curves.easeOut.transform(_grab.value),
                        thumbRadius: _thumbRadius,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({
    required this.fraction,
    required this.grab,
    required this.thumbRadius,
  });

  final double fraction;
  final double grab;
  final double thumbRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;
    final double left = thumbRadius;
    final double right = size.width - thumbRadius;
    final double x = left + (right - left) * fraction;
    const double trackHeight = 6;

    // Track
    final RRect track = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, cy - trackHeight / 2, size.width, cy + trackHeight / 2),
      const Radius.circular(trackHeight),
    );
    canvas.drawRRect(track, Paint()..color = AppColors.surfaceHighest);

    // Filled portion
    final Rect fillRect = Rect.fromLTRB(0, cy - trackHeight / 2, x, cy + trackHeight / 2);
    if (fillRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(trackHeight)),
        Paint()..shader = AppColors.brandGradient.createShader(track.outerRect),
      );
    }

    final Offset center = Offset(x, cy);
    final double radius = thumbRadius + grab * 3;

    // Halo that blooms while dragging
    if (grab > 0) {
      canvas.drawCircle(
        center,
        radius + 10 * grab,
        Paint()..color = AppColors.primary.withValues(alpha: 0.22 * grab),
      );
    }

    // Thumb
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()..color = AppColors.primary.withValues(alpha: 0.30),
    );
    canvas.drawCircle(center, radius, Paint()..color = AppColors.textPrimary);
    canvas.drawCircle(center, radius * 0.34, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.grab != grab;
}
