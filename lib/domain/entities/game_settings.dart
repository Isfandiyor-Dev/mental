import '../../core/constants/app_constants.dart';
import 'math_operation.dart';
import 'number_range.dart';

/// Immutable configuration for a round. Every field is clamped/validated on
/// construction so no invalid combination can reach the generator.
class GameSettings {
  GameSettings({
    required int speedMillis,
    required this.range,
    required int sequenceLength,
    required this.allowNegativeResults,
    required Set<MathOperation> operations,
  })  : speedMillis = _clamp(speedMillis, AppConstants.minSpeedMillis, AppConstants.maxSpeedMillis),
        sequenceLength =
            _clamp(sequenceLength, AppConstants.minSequenceLength, AppConstants.maxSequenceLength),
        operations = Set<MathOperation>.unmodifiable(
          operations.isEmpty ? <MathOperation>{MathOperation.addition} : operations,
        );

  /// Novice defaults, used on first launch and whenever stored settings cannot
  /// be read: slow pace, single digits, a short sequence, addition only.
  factory GameSettings.initial() => GameSettings(
        speedMillis: 2000,
        range: NumberRange.oneDigit,
        sequenceLength: 5,
        allowNegativeResults: false,
        operations: <MathOperation>{MathOperation.addition},
      );

  /// How long a single number stays on stage, in milliseconds.
  final int speedMillis;

  /// Band operands are drawn from. Operands are always positive; sign is
  /// expressed by the selected operations instead.
  final NumberRange range;

  /// How many numbers appear in a row.
  final int sequenceLength;

  /// Whether intermediate and final results may drop below zero.
  final bool allowNegativeResults;

  /// Always non-empty — at least one operation is guaranteed.
  final Set<MathOperation> operations;

  Duration get speed => Duration(milliseconds: speedMillis);

  bool usesOperation(MathOperation operation) => operations.contains(operation);

  GameSettings copyWith({
    int? speedMillis,
    NumberRange? range,
    int? sequenceLength,
    bool? allowNegativeResults,
    Set<MathOperation>? operations,
  }) {
    return GameSettings(
      speedMillis: speedMillis ?? this.speedMillis,
      range: range ?? this.range,
      sequenceLength: sequenceLength ?? this.sequenceLength,
      allowNegativeResults: allowNegativeResults ?? this.allowNegativeResults,
      operations: operations ?? this.operations,
    );
  }

  static int _clamp(int value, int min, int max) => value < min ? min : (value > max ? max : value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSettings &&
        other.speedMillis == speedMillis &&
        other.range == range &&
        other.sequenceLength == sequenceLength &&
        other.allowNegativeResults == allowNegativeResults &&
        other.operations.length == operations.length &&
        other.operations.containsAll(operations);
  }

  @override
  int get hashCode => Object.hash(
        speedMillis,
        range,
        sequenceLength,
        allowNegativeResults,
        Object.hashAllUnordered(operations),
      );
}
