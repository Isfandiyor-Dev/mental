/// Tunable bounds shared by the domain rules and the configuration UI.
abstract final class AppConstants {
  // Speed interval (milliseconds a single number stays on stage).
  static const int minSpeedMillis = 500;
  static const int maxSpeedMillis = 4000;
  static const int speedStepMillis = 50;

  // How many numbers make up one round.
  static const int minSequenceLength = 2;
  static const int maxSequenceLength = 100;

  /// Longest answer the custom keypad accepts, digits only.
  static const int maxAnswerDigits = 16;

  // Animation durations used across the presentation layer.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 620);
}
