import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographic scale. Numeric styles use tabular figures so digits never jitter
/// while a value animates or a sequence plays.
abstract final class AppTextStyles {
  static const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.textTertiary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    color: AppColors.textSecondary,
  );

  static const TextStyle value = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
    fontFeatures: _tabular,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
    color: AppColors.background,
  );

  static const TextStyle keypad = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    fontFeatures: _tabular,
  );

  /// The huge number shown during the sequence and while answering.
  static const TextStyle stage = TextStyle(
    fontSize: 76,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -3,
    color: AppColors.textPrimary,
    fontFeatures: _tabular,
  );
}
