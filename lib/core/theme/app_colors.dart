import 'package:flutter/material.dart';

/// Dark-only palette. Every surface is a step on a single neutral ramp so the
/// UI keeps a calm, layered depth; colour is reserved for state and accents.
abstract final class AppColors {
  // Neutrals ---------------------------------------------------------------
  static const Color background = Color(0xFF080A0F);
  static const Color surface = Color(0xFF11151E);
  static const Color surfaceHigh = Color(0xFF191F2B);
  static const Color surfaceHighest = Color(0xFF222937);
  static const Color stroke = Color(0xFF232A38);
  static const Color strokeStrong = Color(0xFF39435A);

  // Text -------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF3F5FA);
  static const Color textSecondary = Color(0xFF98A2B8);
  static const Color textTertiary = Color(0xFF5A6479);

  // Accents ----------------------------------------------------------------
  static const Color primary = Color(0xFF6C8CFF);
  static const Color primarySoft = Color(0xFF8FA6FF);
  static const Color accent = Color(0xFF35E4B4);
  static const Color success = Color(0xFF35E4B4);
  static const Color danger = Color(0xFFFF5C7A);

  // Gradients --------------------------------------------------------------
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[primary, accent],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[accent, primary],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[danger, Color(0xFFFF9A5C)],
  );

  /// Soft glow used under interactive, elevated elements.
  static List<BoxShadow> glow(Color color, {double opacity = 0.35, double blur = 28, double spread = -6}) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
