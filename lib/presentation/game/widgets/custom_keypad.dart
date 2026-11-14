import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/number_formatter.dart';
import '../../shared/widgets/pressable.dart';

/// The app's own keypad. The system keyboard is never used: there is no text
/// field anywhere, so input can be constrained to exactly what an answer needs
/// — digits, a sign flip, a backspace and a confirm.
class CustomKeypad extends StatelessWidget {
  const CustomKeypad({
    super.key,
    required this.entrance,
    required this.onDigit,
    required this.onToggleSign,
    required this.onBackspace,
    required this.onSubmit,
    required this.canSubmit,
    required this.canBackspace,
  });

  /// Parent-owned timeline used to stagger the keys into view.
  final Animation<double> entrance;

  final ValueChanged<String> onDigit;
  final VoidCallback onToggleSign;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool canSubmit;
  final bool canBackspace;

  static const List<List<String>> _rows = <List<String>>[
    <String>['1', '2', '3'],
    <String>['4', '5', '6'],
    <String>['7', '8', '9'],
    <String>['sign', '0', 'backspace'],
  ];

  @override
  Widget build(BuildContext context) {
    int keyIndex = 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<String> row in _rows) ...<Widget>[
          Row(
            children: <Widget>[
              for (final String key in row) ...<Widget>[
                Expanded(
                  child: _KeyEntrance(
                    entrance: entrance,
                    index: keyIndex++,
                    child: _buildKey(key),
                  ),
                ),
                if (key != row.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        _KeyEntrance(
          entrance: entrance,
          index: keyIndex,
          child: _ConfirmKey(enabled: canSubmit, onTap: onSubmit),
        ),
      ],
    );
  }

  Widget _buildKey(String key) {
    switch (key) {
      case 'sign':
        return _Key(
          onTap: onToggleSign,
          child: Text(
            NumberFormatter.minusSign,
            style: AppTextStyles.keypad.copyWith(color: AppColors.accent, fontSize: 30),
          ),
        );
      case 'backspace':
        return _Key(
          onTap: canBackspace ? onBackspace : null,
          child: Icon(
            Icons.backspace_outlined,
            size: 23,
            color: canBackspace ? AppColors.textSecondary : AppColors.textTertiary,
          ),
        );
      default:
        return _Key(
          onTap: () => onDigit(key),
          child: Text(key, style: AppTextStyles.keypad),
        );
    }
  }
}

/// Scales and fades a single key in, offset along the shared timeline.
class _KeyEntrance extends StatelessWidget {
  const _KeyEntrance({required this.entrance, required this.index, required this.child});

  final Animation<double> entrance;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double start = (index * 0.045).clamp(0.0, 0.5);
    final Animation<double> curved = CurvedAnimation(
      parent: entrance,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: curved.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.6 + 0.4 * curved.value, child: child),
        );
      },
      child: child,
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.90,
      haptic: HapticStrength.light,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _ConfirmKey extends StatelessWidget {
  const _ConfirmKey({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: enabled ? onTap : null,
      pressedScale: 0.96,
      haptic: HapticStrength.medium,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        height: 62,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.brandGradient : null,
          color: enabled ? null : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: enabled ? Colors.transparent : AppColors.stroke),
          boxShadow:
              enabled ? AppColors.glow(AppColors.accent, opacity: 0.36, blur: 26, spread: -8) : null,
        ),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            scale: enabled ? 1 : 0.85,
            child: Icon(
              Icons.check_rounded,
              size: 30,
              color: enabled ? AppColors.background : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
