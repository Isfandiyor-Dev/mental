import '../entities/game_result.dart';
import '../entities/game_sequence.dart';

/// Compares what the player entered against what the round actually resolves to.
class EvaluateAnswerUseCase {
  const EvaluateAnswerUseCase();

  GameResult call({required GameSequence sequence, required int submittedAnswer}) {
    return GameResult(
      submittedAnswer: submittedAnswer,
      expectedAnswer: sequence.answer,
    );
  }
}
