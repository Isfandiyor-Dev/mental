/// Formatting helpers for the large on-stage numerals.
///
/// Digits are grouped with a thin space rather than a comma or dot so the
/// grouping never reads as a decimal separator in any locale.
abstract final class NumberFormatter {
  static const String _thinSpace = ' ';

  /// Typographic minus (U+2212) — visually balanced with the digits, unlike the
  /// hyphen that the input model stores internally.
  static const String minusSign = '−';

  static String grouped(int value) {
    final bool isNegative = value < 0;
    final String digits = value.abs().toString();
    return '${isNegative ? minusSign : ''}${_group(digits)}';
  }

  /// Formats the raw keypad buffer, which may be empty or hold a lone '-'.
  static String entry(String raw) {
    if (raw.isEmpty) return '0';
    if (raw == '-') return minusSign;
    final bool isNegative = raw.startsWith('-');
    final String digits = isNegative ? raw.substring(1) : raw;
    return '${isNegative ? minusSign : ''}${_group(digits)}';
  }

  static String _group(String digits) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_thinSpace);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// "850 ms" below one second, "1.4 s" above it.
  static String duration(int millis) {
    if (millis < 1000) return '$millis ms';
    final String seconds = (millis / 1000).toStringAsFixed(millis % 1000 == 0 ? 0 : 1);
    return '$seconds s';
  }
}
