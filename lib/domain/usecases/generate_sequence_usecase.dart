import '../entities/game_sequence.dart';
import '../entities/game_settings.dart';
import '../entities/math_operation.dart';
import '../entities/number_range.dart';
import '../entities/sequence_step.dart';
import '../services/random_source.dart';

/// Builds a round that is guaranteed to be solvable with mental arithmetic:
///
/// * operands are always positive and inside the configured band — a negative
///   step is expressed by choosing subtraction, not by negating the operand;
/// * division always lands on a whole number — the divisor is picked from the
///   actual divisors of the running total;
/// * when negative results are disabled, no intermediate total ever dips below
///   zero;
/// * multiplication can never overflow a 64-bit int, because a factor is only
///   accepted when the product stays under [_hardCeiling].
class GenerateSequenceUseCase {
  const GenerateSequenceUseCase(this._random);

  final RandomSource _random;

  /// Absolute cap on any running total. Chosen so that `_hardCeiling * 9999`
  /// still fits comfortably in a 64-bit int, making overflow unreachable.
  static const int _hardCeiling = 1000000000000000; // 1e15

  /// Soft cap: operations whose result stays under this are strongly preferred,
  /// which keeps rounds humane instead of exploding into astronomical products.
  static const int _comfortCeiling = 1000000; // 1e6

  /// Random probes before falling back to an exhaustive scan of the band.
  static const int _probeAttempts = 32;

  GameSequence call(GameSettings settings) {
    final List<SequenceStep> steps = <SequenceStep>[];

    int total = _openingTerm(settings);
    steps.add(SequenceStep(operation: null, operand: total, runningResult: total));

    for (int i = 1; i < settings.sequenceLength; i++) {
      final SequenceStep step = _nextStep(total, settings);
      total = step.runningResult;
      steps.add(step);
    }

    return GameSequence(steps);
  }

  // ---------------------------------------------------------------------------
  // Step construction
  // ---------------------------------------------------------------------------

  int _openingTerm(GameSettings settings) => _randomMagnitude(settings.range);

  SequenceStep _nextStep(int total, GameSettings settings) {
    final List<_Candidate> viable = <_Candidate>[];
    final List<_Candidate> comfortable = <_Candidate>[];

    for (final MathOperation operation in settings.operations) {
      final int? operand = _findOperand(operation, total, settings);
      if (operand == null) continue;

      final _Candidate candidate = _Candidate(
        operation: operation,
        operand: operand,
        result: operation.apply(total, operand),
      );
      viable.add(candidate);
      if (candidate.result.abs() <= _comfortCeiling) comfortable.add(candidate);
    }

    final List<_Candidate> pool = comfortable.isNotEmpty ? comfortable : viable;
    if (pool.isEmpty) return _neutralStep(total, settings);

    final _Candidate chosen = pool[_random.nextInt(pool.length)];
    return SequenceStep(
      operation: chosen.operation,
      operand: chosen.operand,
      runningResult: chosen.result,
    );
  }

  /// Last resort for configurations that momentarily admit no legal operand —
  /// e.g. "÷ only" when the running total is prime, or "− only" with negative
  /// results disabled once the total has reached zero. The neutral operand is
  /// the mathematically forced move, and it preserves the configured length.
  SequenceStep _neutralStep(int total, GameSettings settings) {
    final MathOperation operation = settings.operations.first;
    final int operand = switch (operation) {
      MathOperation.addition || MathOperation.subtraction => 0,
      MathOperation.multiplication || MathOperation.division => 1,
    };
    return SequenceStep(
      operation: operation,
      operand: operand,
      runningResult: operation.apply(total, operand),
    );
  }

  // ---------------------------------------------------------------------------
  // Operand search
  // ---------------------------------------------------------------------------

  /// Finds an operand in the configured band that keeps [operation] legal, or
  /// `null` when the band offers none.
  ///
  /// Random probing resolves the common case in a handful of tries; the
  /// exhaustive sweep only ever runs for tightly constrained steps (typically
  /// division), and walks the band from a random offset so the result stays
  /// unbiased without allocating a shuffled list.
  int? _findOperand(MathOperation operation, int total, GameSettings settings) {
    for (int i = 0; i < _probeAttempts; i++) {
      final int operand = _randomMagnitude(settings.range);
      if (_isLegal(operation, total, operand, settings)) return operand;
    }

    final NumberRange range = settings.range;
    final int start = _random.nextInt(range.span);

    for (int i = 0; i < range.span; i++) {
      final int operand = range.min + (start + i) % range.span;
      if (_isLegal(operation, total, operand, settings)) return operand;
    }
    return null;
  }

  /// [operand] is always at least 1, since every [NumberRange] starts at 1 —
  /// hence no division-by-zero guard is needed here. It also means division
  /// always has at least one legal operand, because every total is divisible
  /// by 1.
  bool _isLegal(MathOperation operation, int total, int operand, GameSettings settings) {
    switch (operation) {
      case MathOperation.division:
        // The quotient must be exact.
        if (total % operand != 0) return false;
      case MathOperation.multiplication:
        // Guard the product *before* computing it, so the check itself cannot
        // overflow.
        if (total.abs() > _hardCeiling ~/ operand) return false;
      case MathOperation.addition:
      case MathOperation.subtraction:
        break;
    }

    if (!settings.allowNegativeResults && operation.apply(total, operand) < 0) return false;
    return true;
  }

  int _randomMagnitude(NumberRange range) => range.min + _random.nextInt(range.span);
}

/// A legal (operation, operand) pairing together with the total it produces.
class _Candidate {
  const _Candidate({required this.operation, required this.operand, required this.result});

  final MathOperation operation;
  final int operand;
  final int result;
}
