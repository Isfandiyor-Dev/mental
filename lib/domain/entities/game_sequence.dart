import 'sequence_step.dart';

/// A fully resolved round: the ordered steps and the answer they add up to.
class GameSequence {
  GameSequence(List<SequenceStep> steps)
      : assert(steps.length >= 2, 'A round needs at least two numbers'),
        steps = List<SequenceStep>.unmodifiable(steps);

  final List<SequenceStep> steps;

  int get length => steps.length;

  /// The value the player has to arrive at.
  int get answer => steps.last.runningResult;

  SequenceStep stepAt(int index) => steps[index];

  /// Human-readable form of the whole round, e.g. `7 + 12 ÷ 19`.
  String get expression => steps.map((SequenceStep step) => step.label).join('  ');
}
