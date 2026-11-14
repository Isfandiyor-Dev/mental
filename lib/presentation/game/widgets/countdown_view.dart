import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// The 3 · 2 · 1 · GO lead-in. Each tick rushes in from large and blurs out to
/// small, driven entirely by the parent's controller.
class CountdownView extends StatelessWidget {
  const CountdownView({super.key, required this.animation, required this.label});

  final Animation<double> animation;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) {
        final double t = animation.value;
        final double appear = Curves.easeOutBack.transform((t / 0.45).clamp(0.0, 1.0));
        final double vanish = Curves.easeInCubic.transform(((t - 0.62) / 0.38).clamp(0.0, 1.0));

        final double scale = 0.5 + 0.5 * appear + 0.45 * vanish;
        final double opacity = (appear * (1 - vanish)).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Expanding ring that echoes each tick outward.
                Container(
                  width: 150 + 90 * vanish,
                  height: 150 + 90 * vanish,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.30 * (1 - vanish)),
                      width: 2,
                    ),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (Rect bounds) =>
                      AppColors.brandGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    label,
                    style: AppTextStyles.stage.copyWith(
                      fontSize: label.length > 1 ? 56 : 88,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
