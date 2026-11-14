import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/number_formatter.dart';

/// The large running answer. Starts life as a plain `0` and swaps digits with a
/// vertical slide, so every keypad press is visibly acknowledged.
class AnswerDisplay extends StatefulWidget {
  const AnswerDisplay({super.key, required this.entry});

  /// Raw keypad buffer, e.g. `''`, `'-'`, `'-1204'`.
  final String entry;

  @override
  State<AnswerDisplay> createState() => _AnswerDisplayState();
}

class _AnswerDisplayState extends State<AnswerDisplay> with SingleTickerProviderStateMixin {
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formatted = NumberFormatter.entry(widget.entry);
    final bool isPlaceholder = widget.entry.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('YOUR ANSWER', style: AppTextStyles.sectionLabel),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                // Digits are updated in place. Swapping the whole value through
                // an AnimatedSwitcher made the number lurch on every keypress —
                // the only thing that eases now is the colour, so nothing the
                // eye is tracking ever moves.
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  style: AppTextStyles.stage.copyWith(
                    color: isPlaceholder ? AppColors.textTertiary : AppColors.textPrimary,
                  ),
                  child: Text(formatted, maxLines: 1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Blinking caret keeps the display feeling like a live input even
            // though there is no text field anywhere in the app.
            FadeTransition(
              opacity: _caret,
              child: Container(
                width: 4,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
