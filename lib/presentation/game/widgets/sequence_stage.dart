import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/sequence_step.dart';

/// Renders one number of the sequence for exactly one cycle of [animation],
/// whose duration is the configured speed interval.
///
/// The whole beat — fade in, hold, fade out — is derived from the single
/// controller value, so the visuals can never drift out of step with the timing.
class SequenceStage extends StatelessWidget {
  const SequenceStage({super.key, required this.animation, required this.step});

  final Animation<double> animation;
  final SequenceStep step;

  /// Fraction of the beat spent fading in, and again fading out.
  static const double _fadePortion = 0.26;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        final double appear = Curves.easeOutCubic.transform((t / _fadePortion).clamp(0.0, 1.0));
        final double vanish = Curves.easeInCubic
            .transform(((t - (1 - _fadePortion)) / _fadePortion).clamp(0.0, 1.0));

        final double opacity = (appear * (1 - vanish)).clamp(0.0, 1.0);
        // Settles up to full size, then lifts and shrinks away.
        final double scale = 0.82 + 0.18 * appear - 0.10 * vanish;
        final double dy = 22 * (1 - appear) - 26 * vanish;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: _StepText(step: step),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({required this.step});

  final SequenceStep step;

  @override
  Widget build(BuildContext context) {
    // A four-digit negative operand renders as `+ (−9 999)`, which is wider
    // than a phone at the stage size — scale it down rather than overflow.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _buildText(),
      ),
    );
  }

  Widget _buildText() {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (!step.isOpening) ...<InlineSpan>[
            TextSpan(
              text: step.operatorLabel,
              // The operator is the quieter half — the operand is what you add.
              style: AppTextStyles.stage.copyWith(
                color: AppColors.accent,
                fontSize: 54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: '  '),
          ],
          TextSpan(text: step.operandLabel),
        ],
      ),
      textAlign: TextAlign.center,
      style: AppTextStyles.stage,
    );
  }
}
