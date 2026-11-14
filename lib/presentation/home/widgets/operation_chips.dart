import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/math_operation.dart';

/// Multi-select operation chips. Deselecting the final chip is refused — the
/// chip shakes instead, which explains the rule without a snackbar.
class OperationChips extends StatefulWidget {
  const OperationChips({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<MathOperation> selected;

  /// Returns `false` when the toggle was rejected.
  final bool Function(MathOperation operation) onToggle;

  @override
  State<OperationChips> createState() => _OperationChipsState();
}

class _OperationChipsState extends State<OperationChips> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  MathOperation? _rejected;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _handleTap(MathOperation operation) {
    final bool accepted = widget.onToggle(operation);
    if (accepted) {
      HapticFeedback.selectionClick();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _rejected = operation);
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final MathOperation operation in MathOperation.values) ...<Widget>[
          Expanded(
            child: AnimatedBuilder(
              animation: _shake,
              builder: (BuildContext context, Widget? child) {
                final bool isShaking = _rejected == operation && _shake.isAnimating;
                if (!isShaking) return child!;
                // Decaying sine — three quick swings that settle back to centre.
                final double dx =
                    math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: _Chip(
                operation: operation,
                selected: widget.selected.contains(operation),
                onTap: () => _handleTap(operation),
              ),
            ),
          ),
          if (operation != MathOperation.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.operation, required this.selected, required this.onTap});

  final MathOperation operation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double t, _) {
          // A half-sine pop on every state change that resolves back to 1.0.
          final double pop = 1 + 0.10 * math.sin(t * math.pi);
          return Transform.scale(
            scale: pop,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                gradient: t > 0.02 ? AppColors.brandGradient : null,
                color: Color.lerp(AppColors.surfaceHigh, Colors.transparent, t),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color.lerp(AppColors.stroke, Colors.transparent, t)!),
                boxShadow: t > 0
                    ? AppColors.glow(AppColors.primary, opacity: 0.34 * t, blur: 18, spread: -6)
                    : null,
              ),
              child: Center(
                child: Text(
                  operation.symbol,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color.lerp(AppColors.textSecondary, AppColors.background, t),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
