/// Outcome of a submitted answer.
class GameResult {
  const GameResult({required this.submittedAnswer, required this.expectedAnswer});

  final int submittedAnswer;
  final int expectedAnswer;

  bool get isCorrect => submittedAnswer == expectedAnswer;
}
