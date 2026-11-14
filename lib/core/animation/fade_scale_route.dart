import 'package:flutter/material.dart';

/// Route transition used for Home → Gameplay: the outgoing screen dissolves
/// while the incoming one settles in from a slightly larger scale.
class FadeScaleRoute<T> extends PageRouteBuilder<T> {
  FadeScaleRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, _, _) => child,
          transitionsBuilder: (_, Animation<double> animation, _, Widget page) {
            final Animation<double> curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.06, end: 1).animate(curved),
                child: page,
              ),
            );
          },
        );

  final Widget child;
}
