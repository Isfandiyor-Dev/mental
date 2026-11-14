import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/number_range.dart';

/// Four mutually exclusive digit bands. A single gradient pill slides between
/// the segments — the selection literally travels to where you tapped.
class RangeSelector extends StatelessWidget {
  const RangeSelector({super.key, required this.selected, required this.onChanged});

  final NumberRange selected;
  final ValueChanged<NumberRange> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<NumberRange> ranges = NumberRange.values;
    final int index = ranges.indexOf(selected);

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double segmentWidth = constraints.maxWidth / ranges.length;

          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: const Duration(milliseconds: 340),
                curve: Curves.easeOutBack,
                left: segmentWidth * index,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.glow(AppColors.primary, opacity: 0.30, blur: 16, spread: -4),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (final NumberRange range in ranges)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (range == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(range);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                            style: AppTextStyles.value.copyWith(
                              // The labels top out at six characters, so this
                              // sits comfortably even on the narrowest phones;
                              // the FittedBox below is only a safety net.
                              fontSize: 14,
                              color: range == selected
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                              fontWeight:
                                  range == selected ? FontWeight.w800 : FontWeight.w600,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(range.label),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
