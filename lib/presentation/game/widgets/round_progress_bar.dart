import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Slim progress rail showing how far through the sequence the round is.
class RoundProgressBar extends StatelessWidget {
  const RoundProgressBar({super.key, required this.progress});

  /// 0 → 1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 5,
        color: AppColors.surfaceHigh,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          builder: (BuildContext context, double value, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
