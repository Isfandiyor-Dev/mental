import '../../core/utils/number_formatter.dart';
import 'math_operation.dart';

/// One beat of a round: the operand shown on stage plus the operation that
/// binds it to everything before it.
class SequenceStep {
  const SequenceStep({
    required this.operation,
    required this.operand,
    required this.runningResult,
  });

  /// `null` for the very first term, which has nothing to combine with.
  final MathOperation? operation;

  final int operand;

  /// The accumulated value after this step is applied.
  final int runningResult;

  bool get isOpening => operation == null;

  /// Operator glyph, or an empty string for the opening term.
  String get operatorLabel => operation?.symbol ?? '';

  /// Operands are always positive — a downward step is expressed by the
  /// operator, so no sign ever needs disambiguating here.
  String get operandLabel => NumberFormatter.grouped(operand);

  String get label => isOpening ? operandLabel : '$operatorLabel $operandLabel';

  @override
  String toString() => label;
}
