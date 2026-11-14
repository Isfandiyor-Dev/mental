import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/pressable.dart';

/// The primary call to action: a gradient slab with a slow specular sweep that
/// keeps it feeling alive without demanding attention.
class StartButton extends StatefulWidget {
  const StartButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<StartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.96,
      haptic: HapticStrength.medium,
      onTap: widget.onPressed,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.glow(AppColors.primary, opacity: 0.42, blur: 34, spread: -8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _shimmer,
                    builder: (BuildContext context, _) {
                      // Sweeps from off-left to off-right, then rests.
                      final double t = Curves.easeInOut.transform(_shimmer.value);
                      return FractionallySizedBox(
                        widthFactor: 0.35,
                        alignment: Alignment(-2.4 + 4.8 * t, 0),
                        child: Transform.rotate(
                          angle: 0.35,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('START', style: AppTextStyles.button),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.background.withValues(alpha: 0.9),
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
