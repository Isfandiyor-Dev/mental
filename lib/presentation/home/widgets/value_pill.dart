import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// The small readout that sits in a [SectionCard]'s header. The value swaps with
/// a vertical slide so scrubbing a slider reads as motion, not a flicker.
class ValuePill extends StatelessWidget {
  const ValuePill({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.stroke),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          value,
          key: ValueKey<String>(value),
          style: AppTextStyles.value.copyWith(color: AppColors.primarySoft),
        ),
      ),
    );
  }
}
