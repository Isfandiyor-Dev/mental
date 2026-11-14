import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Custom toggle with a travelling thumb and a track that lights up as it goes.
class NeoSwitch extends StatelessWidget {
  const NeoSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTextStyles.body),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: AppTextStyles.caption.copyWith(fontSize: 12.5)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value ? 1 : 0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double t, _) {
              return Container(
                width: 56,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Color.lerp(AppColors.surfaceHighest, AppColors.primary, t),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Color.lerp(AppColors.stroke, AppColors.primary, t)!,
                  ),
                  boxShadow: t > 0
                      ? AppColors.glow(AppColors.primary, opacity: 0.35 * t, blur: 16, spread: -6)
                      : null,
                ),
                child: Align(
                  alignment: Alignment.lerp(Alignment.centerLeft, Alignment.centerRight, t)!,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Color.lerp(AppColors.textTertiary, AppColors.textPrimary, t),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
