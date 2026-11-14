import 'package:flutter_test/flutter_test.dart';
import 'package:mental/data/services/dart_random_source.dart';
import 'package:mental/domain/entities/game_sequence.dart';
import 'package:mental/domain/entities/game_settings.dart';
import 'package:mental/domain/entities/math_operation.dart';
import 'package:mental/domain/entities/number_range.dart';
import 'package:mental/domain/entities/sequence_step.dart';
import 'package:mental/domain/usecases/generate_sequence_usecase.dart';

/// Asserts every invariant the gameplay depends on. Any violation would surface
/// as an unsolvable or unanswerable round.
void assertSequenceIsValid(GameSequence sequence, GameSettings settings) {
  expect(sequence.length, settings.sequenceLength, reason: 'length must match settings');

  final SequenceStep opening = sequence.steps.first;
  expect(opening.isOpening, isTrue);
  expect(opening.runningResult, opening.operand);

  int total = opening.runningResult;

  for (int i = 0; i < sequence.length; i++) {
    final SequenceStep step = sequence.stepAt(i);
    final MathOperation? operation = step.operation;

    if (i > 0) {
      expect(operation, isNotNull, reason: 'only the first step may lack an operation');
      expect(
        settings.operations.contains(operation),
        isTrue,
        reason: 'used $operation which was not selected',
      );

      if (operation == MathOperation.division) {
        expect(step.operand, isNot(0), reason: 'division by zero');
        expect(total % step.operand, 0, reason: '$total ÷ ${step.operand} is not exact');
      }

      // The running total must be exactly what the step claims.
      expect(step.runningResult, operation!.apply(total, step.operand));
      total = step.runningResult;
    }

    // Operand magnitude sits in the configured band, or is the documented
    // neutral fallback (0 for +/−, 1 for ×/÷) for otherwise-impossible states.
    final int magnitude = step.operand.abs();
    final bool inBand = magnitude >= settings.range.min && magnitude <= settings.range.max;
    final bool isNeutral = i > 0 &&
        ((step.operand == 0 &&
                (operation == MathOperation.addition ||
                    operation == MathOperation.subtraction)) ||
            (step.operand == 1 &&
                (operation == MathOperation.multiplication ||
                    operation == MathOperation.division)));
    expect(inBand || isNeutral, isTrue, reason: 'operand ${step.operand} out of range');

    // Operands are never negative; sign is carried by the operation instead.
    expect(step.operand >= 0, isTrue, reason: 'operands must be positive');

    if (!settings.allowNegativeResults) {
      expect(step.runningResult >= 0, isTrue,
          reason: 'running total went negative at step $i: ${step.runningResult}');
    }
  }

  expect(sequence.answer, total, reason: 'answer must equal the final running total');
}

void main() {
  GameSettings settingsWith({
    required Set<MathOperation> operations,
    NumberRange range = NumberRange.twoDigits,
    int length = 12,
    bool negativeResults = false,
  }) {
    return GameSettings(
      speedMillis: 1000,
      range: range,
      sequenceLength: length,
      allowNegativeResults: negativeResults,
      operations: operations,
    );
  }

  group('GenerateSequenceUseCase', () {
    test('holds every invariant across the full configuration matrix', () {
      // Exhaustive sweep: all 15 non-empty operation subsets × 4 ranges ×
      // both negative-result settings × several lengths, over 40 seeds.
      final List<Set<MathOperation>> operationSets = <Set<MathOperation>>[
        for (int mask = 1; mask < 16; mask++)
          <MathOperation>{
            for (int bit = 0; bit < 4; bit++)
              if (mask & (1 << bit) != 0) MathOperation.values[bit],
          },
      ];

      for (int seed = 0; seed < 40; seed++) {
        final GenerateSequenceUseCase generate =
            GenerateSequenceUseCase(DartRandomSource(seed));

        for (final Set<MathOperation> operations in operationSets) {
          for (final NumberRange range in NumberRange.values) {
            for (final bool negativeResults in <bool>[false, true]) {
              for (final int length in <int>[2, 9, 40]) {
                final GameSettings settings = settingsWith(
                  operations: operations,
                  range: range,
                  length: length,
                  negativeResults: negativeResults,
                );
                assertSequenceIsValid(generate(settings), settings);
              }
            }
          }
        }
      }
    });

    test('respects the maximum sequence length without overflowing', () {
      final GenerateSequenceUseCase generate = GenerateSequenceUseCase(DartRandomSource(7));
      final GameSettings settings = settingsWith(
        operations: MathOperation.values.toSet(),
        range: NumberRange.fourDigits,
        length: 100,
        negativeResults: true,
      );

      final GameSequence sequence = generate(settings);
      assertSequenceIsValid(sequence, settings);
      // Every total stays inside the generator's hard ceiling, so no int64 wrap.
      for (final SequenceStep step in sequence.steps) {
        expect(step.runningResult.abs() <= 1000000000000000, isTrue);
      }
    });

    test('multiplication-only rounds stay bounded', () {
      final GenerateSequenceUseCase generate = GenerateSequenceUseCase(DartRandomSource(3));
      final GameSettings settings = settingsWith(
        operations: <MathOperation>{MathOperation.multiplication},
        range: NumberRange.fourDigits,
        length: 100,
      );
      assertSequenceIsValid(generate(settings), settings);
    });

    test('division-only rounds always divide exactly', () {
      final GenerateSequenceUseCase generate = GenerateSequenceUseCase(DartRandomSource(11));
      final GameSettings settings = settingsWith(
        operations: <MathOperation>{MathOperation.division},
        range: NumberRange.oneDigit,
        length: 30,
      );
      assertSequenceIsValid(generate(settings), settings);
    });

    test('is deterministic for a given seed', () {
      final GameSettings settings = settingsWith(
        operations: <MathOperation>{MathOperation.addition, MathOperation.subtraction},
      );
      final GameSequence a = GenerateSequenceUseCase(DartRandomSource(42))(settings);
      final GameSequence b = GenerateSequenceUseCase(DartRandomSource(42))(settings);
      expect(a.expression, b.expression);
      expect(a.answer, b.answer);
    });
  });

  group('GameSettings', () {
    test('clamps out-of-bounds values', () {
      final GameSettings settings = GameSettings(
        speedMillis: 10,
        range: NumberRange.oneDigit,
        sequenceLength: 5000,
        allowNegativeResults: false,
        operations: <MathOperation>{MathOperation.addition},
      );
      expect(settings.speedMillis, 500);
      expect(settings.sequenceLength, 100);
    });

    test('never allows an empty operation set', () {
      final GameSettings settings = GameSettings(
        speedMillis: 1000,
        range: NumberRange.oneDigit,
        sequenceLength: 5,
        allowNegativeResults: false,
        operations: <MathOperation>{},
      );
      expect(settings.operations, isNotEmpty);
    });
  });
}
