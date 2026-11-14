/// How many digits an operand may have. Mutually exclusive by design — the UI
/// renders these as a four-way segmented control.
///
/// The bands are cumulative rather than disjoint: every range starts at 1, so
/// picking [fourDigits] means "anything up to 9999", not "four-digit numbers
/// only". That keeps rounds varied instead of forcing every operand to be large.
enum NumberRange {
  // The persisted ids predate the switch to cumulative bands. They are kept
  // verbatim so an existing saved selection still lands on the same button.
  oneDigit('units', 9, '1–9'),
  twoDigits('tens', 99, '1–99'),
  threeDigits('hundreds', 999, '1–999'),
  fourDigits('thousands', 9999, '1–9999');

  const NumberRange(this.id, this.max, this.label);

  /// Stable value used for persistence; must never change.
  final String id;

  /// Largest allowed operand.
  final int max;

  final String label;

  /// Smallest allowed operand. Always 1 — the generator relies on this to
  /// guarantee that a legal divisor always exists.
  int get min => 1;

  /// Number of distinct values in the band.
  int get span => max - min + 1;

  static NumberRange? fromId(String id) {
    for (final NumberRange range in NumberRange.values) {
      if (range.id == id) return range;
    }
    return null;
  }
}
