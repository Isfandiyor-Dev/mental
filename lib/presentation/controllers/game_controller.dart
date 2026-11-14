import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/game_result.dart';
import '../../domain/entities/game_sequence.dart';
import '../../domain/entities/game_settings.dart';
import '../../domain/entities/sequence_step.dart';
import '../../domain/usecases/evaluate_answer_usecase.dart';
import '../../domain/usecases/generate_sequence_usecase.dart';

enum GamePhase {
  /// 3 · 2 · 1 · GO before the first number.
  countdown,

  /// Numbers are flashing on stage, one per configured interval.
  presenting,

  /// Sequence finished; the custom keypad is live.
  input,

  /// An answer was submitted and the result modal is up.
  result,
}

/// Pure state for one round. It deliberately owns **no** timers and **no**
/// tickers: the widget drives progression from a single `AnimationController`,
/// so there is exactly one thing to dispose and no timer can outlive the view.
class GameController extends ChangeNotifier {
  GameController({
    required this.settings,
    required GenerateSequenceUseCase generateSequence,
    required this._evaluateAnswer,
    // The whole round is resolved up front, so nothing is computed while
    // numbers are on stage.
  }) : _sequence = generateSequence(settings);

  final GameSettings settings;
  final EvaluateAnswerUseCase _evaluateAnswer;
  final GameSequence _sequence;

  GamePhase _phase = GamePhase.countdown;
  int _stepIndex = 0;
  String _entry = '';
  GameResult? _result;

  // Read-only surface ---------------------------------------------------------

  GameSequence get sequence => _sequence;
  GamePhase get phase => _phase;
  int get stepIndex => _stepIndex;
  SequenceStep get currentStep => _sequence.stepAt(_stepIndex);
  GameResult? get result => _result;
  String get entry => _entry;

  /// 0 → 1 across the whole sequence, for the progress bar.
  double get progress => (_stepIndex + 1) / _sequence.length;

  bool get hasNextStep => _stepIndex < _sequence.length - 1;
  bool get canSubmit => _entry.isNotEmpty && _entry != '-';
  bool get canBackspace => _entry.isNotEmpty;

  // Phase transitions ---------------------------------------------------------

  void beginPresenting() {
    if (_phase != GamePhase.countdown) return;
    _phase = GamePhase.presenting;
    notifyListeners();
  }

  void advance() {
    if (!hasNextStep) return;
    _stepIndex++;
    notifyListeners();
  }

  void beginInput() {
    if (_phase != GamePhase.presenting) return;
    _phase = GamePhase.input;
    notifyListeners();
  }

  // Keypad --------------------------------------------------------------------

  void appendDigit(String digit) {
    if (_phase != GamePhase.input) return;
    final int digitCount = _entry.startsWith('-') ? _entry.length - 1 : _entry.length;
    if (digitCount >= AppConstants.maxAnswerDigits) return;
    // Suppress leading zeros: "0" then "5" reads as "5", not "05".
    if (_entry == '0') {
      _entry = digit;
    } else if (_entry == '-0') {
      _entry = '-$digit';
    } else {
      _entry += digit;
    }
    notifyListeners();
  }

  void toggleSign() {
    if (_phase != GamePhase.input) return;
    _entry = _entry.startsWith('-') ? _entry.substring(1) : '-$_entry';
    notifyListeners();
  }

  void backspace() {
    if (_phase != GamePhase.input || _entry.isEmpty) return;
    _entry = _entry.substring(0, _entry.length - 1);
    notifyListeners();
  }

  /// Grades the entry and moves to [GamePhase.result].
  GameResult submit() {
    final GameResult evaluated = _evaluateAnswer(
      sequence: _sequence,
      submittedAnswer: int.tryParse(_entry) ?? 0,
    );
    _result = evaluated;
    _phase = GamePhase.result;
    notifyListeners();
    return evaluated;
  }
}
