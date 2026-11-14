/// The four operations a round can be built from.
///
/// [symbol] is the typographic glyph shown on stage; [id] is the stable value
/// used for persistence and must never change.
enum MathOperation {
  addition('add', '+'),
  subtraction('subtract', '−'),
  multiplication('multiply', '×'),
  division('divide', '÷');

  const MathOperation(this.id, this.symbol);

  final String id;
  final String symbol;

  static MathOperation? fromId(String id) {
    for (final MathOperation operation in MathOperation.values) {
      if (operation.id == id) return operation;
    }
    return null;
  }

  /// Applies the operation. Division is only ever invoked by the generator with
  /// an operand that divides [left] exactly, so integer division is lossless.
  int apply(int left, int right) => switch (this) {
        MathOperation.addition => left + right,
        MathOperation.subtraction => left - right,
        MathOperation.multiplication => left * right,
        MathOperation.division => left ~/ right,
      };
}
