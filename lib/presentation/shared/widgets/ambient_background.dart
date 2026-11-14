import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Two oversized, very soft colour fields drifting behind the content. Uses
/// radial gradients rather than a blur filter, so it costs almost nothing, and
/// is isolated in a [RepaintBoundary] so the drift never repaints the UI above.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, this.child, this.intensity = 1});

  final Widget? child;

  /// Scales the opacity of both fields — the gameplay screen dims them so the
  /// numbers stay the brightest thing on stage.
  final double intensity;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) {
                final double t = _controller.value * 2 * math.pi;
                return CustomPaint(
                  painter: _AmbientPainter(
                    phase: t,
                    intensity: widget.intensity,
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({required this.phase, required this.intensity});

  final double phase;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);

    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.16 + 0.10 * math.sin(phase)),
        size.height * (0.12 + 0.06 * math.cos(phase * 0.8)),
      ),
      radius: size.width * 0.85,
      color: AppColors.primary,
      opacity: 0.20 * intensity,
    );

    _blob(
      canvas,
      size,
      center: Offset(
        size.width * (0.92 + 0.08 * math.cos(phase * 0.7)),
        size.height * (0.82 + 0.08 * math.sin(phase * 1.1)),
      ),
      radius: size.width * 0.75,
      color: AppColors.accent,
      opacity: 0.12 * intensity,
    );
  }

  void _blob(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    if (opacity <= 0) return;
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        stops: const <double>[0, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.intensity != intensity;
}
