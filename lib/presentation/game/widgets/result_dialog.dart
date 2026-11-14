import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../domain/entities/game_result.dart';
import '../../shared/widgets/pressable.dart';

/// Presents the outcome as a modal over the gameplay screen — the round stays
/// visible behind the blur rather than being replaced by a new route.
Future<void> showResultDialog({
  required BuildContext context,
  required GameResult result,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'result',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 440),
    pageBuilder: (_, _, _) => _ResultDialog(result: result),
    transitionBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return AnimatedBuilder(
        animation: curved,
        builder: (BuildContext context, Widget? child) {
          final double t = curved.value;
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18 * t, sigmaY: 18 * t),
            child: Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.86 + 0.14 * Curves.easeOutBack.transform(t.clamp(0.0, 1.0)),
                child: child,
              ),
            ),
          );
        },
        child: child,
      );
    },
  );
}

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({required this.result});

  final GameResult result;

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool get _isCorrect => widget.result.isCorrect;

  @override
  void initState() {
    super.initState();
    _reveal.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color tint = _isCorrect ? AppColors.success : AppColors.danger;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.stroke),
                boxShadow: AppColors.glow(tint, opacity: 0.22, blur: 52, spread: 0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _ResultGlyph(reveal: _reveal, isCorrect: _isCorrect),
                  const SizedBox(height: 26),
                  Text(
                    _isCorrect ? 'Perfect!' : 'Not quite',
                    style: AppTextStyles.display.copyWith(fontSize: 32, color: tint),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isCorrect
                        ? 'You tracked the whole sequence.'
                        : 'Here is how the sequence resolved.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 24),
                  _AnswerPanel(result: widget.result),
                  const SizedBox(height: 24),
                  Pressable(
                    haptic: HapticStrength.medium,
                    pressedScale: 0.96,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient:
                            _isCorrect ? AppColors.successGradient : AppColors.dangerGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.glow(tint, opacity: 0.34, blur: 24, spread: -8),
                      ),
                      child: Center(
                        child: Text(
                          _isCorrect ? 'THANK' : 'OK',
                          style: AppTextStyles.button.copyWith(fontSize: 15),
                        ),
                      ),
                    ),
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

/// Correct: the answer alone. Incorrect: the correct answer, with what the
/// player submitted struck through beneath it.
class _AnswerPanel extends StatelessWidget {
  const _AnswerPanel({required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: <Widget>[
          Text(
            result.isCorrect ? 'THE ANSWER' : 'CORRECT ANSWER',
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormatter.grouped(result.expectedAnswer),
              style: AppTextStyles.stage.copyWith(fontSize: 44),
            ),
          ),
          if (!result.isCorrect) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'You answered ${NumberFormatter.grouped(result.submittedAnswer)}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The ring plus stroked check/cross, with a one-shot ray burst on success.
class _ResultGlyph extends StatelessWidget {
  const _ResultGlyph({required this.reveal, required this.isCorrect});

  final Animation<double> reveal;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: AnimatedBuilder(
        animation: reveal,
        builder: (BuildContext context, _) {
          final double t = reveal.value;
          final double ring = Curves.easeOutCubic.transform((t / 0.45).clamp(0.0, 1.0));
          final double glyph =
              Curves.easeOutCubic.transform(((t - 0.30) / 0.45).clamp(0.0, 1.0));
          final double burst =
              Curves.easeOutCubic.transform(((t - 0.40) / 0.60).clamp(0.0, 1.0));

          return CustomPaint(
            painter: _GlyphPainter(
              ringProgress: ring,
              glyphProgress: glyph,
              burstProgress: isCorrect ? burst : 0,
              color: isCorrect ? AppColors.success : AppColors.danger,
              isCheck: isCorrect,
            ),
          );
        },
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.ringProgress,
    required this.glyphProgress,
    required this.burstProgress,
    required this.color,
    required this.isCheck,
  });

  final double ringProgress;
  final double glyphProgress;
  final double burstProgress;
  final Color color;
  final bool isCheck;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width * 0.38;

    if (burstProgress > 0 && burstProgress < 1) {
      _paintBurst(canvas, center, radius);
    }

    // Soft halo
    canvas.drawCircle(
      center,
      radius * (0.9 + 0.35 * ringProgress),
      Paint()..color = color.withValues(alpha: 0.12 * ringProgress),
    );

    // Ring, drawn as a sweeping arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ringProgress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    if (glyphProgress <= 0) return;

    final Paint stroke = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = isCheck ? _checkPath(size) : _crossPath(size);
    canvas.drawPath(_partial(path, glyphProgress), stroke);
  }

  void _paintBurst(Canvas canvas, Offset center, double radius) {
    const int rayCount = 12;
    final double inner = radius * (1.25 + 0.55 * burstProgress);
    final double outer = inner + 12 * (1 - burstProgress);
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.55 * (1 - burstProgress))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rayCount; i++) {
      final double angle = (i / rayCount) * 2 * math.pi;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + direction * inner, center + direction * outer, paint);
    }
  }

  Path _checkPath(Size size) => Path()
    ..moveTo(size.width * 0.36, size.height * 0.51)
    ..lineTo(size.width * 0.46, size.height * 0.62)
    ..lineTo(size.width * 0.66, size.height * 0.39);

  Path _crossPath(Size size) => Path()
    ..moveTo(size.width * 0.40, size.height * 0.40)
    ..lineTo(size.width * 0.60, size.height * 0.60)
    ..moveTo(size.width * 0.60, size.height * 0.40)
    ..lineTo(size.width * 0.40, size.height * 0.60);

  /// Draws only the first [t] of the path's length so the glyph is stroked on.
  Path _partial(Path source, double t) {
    final Path result = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      result.addPath(metric.extractPath(0, metric.length * t), Offset.zero);
    }
    return result;
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.ringProgress != ringProgress ||
      oldDelegate.glyphProgress != glyphProgress ||
      oldDelegate.burstProgress != burstProgress;
}
