import 'package:flutter/material.dart';

import '../../core/di/injector.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/game_result.dart';
import '../../domain/entities/game_settings.dart';
import '../controllers/game_controller.dart';
import '../shared/widgets/ambient_background.dart';
import '../shared/widgets/pressable.dart';
import 'widgets/answer_display.dart';
import 'widgets/countdown_view.dart';
import 'widgets/custom_keypad.dart';
import 'widgets/result_dialog.dart';
import 'widgets/round_progress_bar.dart';
import 'widgets/sequence_stage.dart';

/// Gameplay. The screen owns every ticker for the round and disposes all of
/// them, so leaving mid-sequence — by back gesture or by finishing — tears down
/// cleanly with nothing left running.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings});

  final GameSettings settings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const List<String> _countdownLabels = <String>['3', '2', '1', 'GO'];

  late final GameController _game = GameController(
    settings: widget.settings,
    generateSequence: Injector.instance.generateSequence,
    evaluateAnswer: Injector.instance.evaluateAnswer,
  );

  /// Drives one number of the sequence per cycle. Its duration *is* the
  /// configured speed interval, which is why timing and animation can never
  /// drift apart — there is no separate timer to fall out of sync.
  late final AnimationController _step = AnimationController(
    vsync: this,
    duration: widget.settings.speed,
  )..addStatusListener(_onStepStatus);

  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  )..addStatusListener(_onCountdownStatus);

  late final AnimationController _keypadEntrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  int _countdownIndex = 0;

  @override
  void initState() {
    super.initState();
    _countdown.forward();
  }

  @override
  void dispose() {
    // Controllers remove their own listeners on dispose.
    _step.dispose();
    _countdown.dispose();
    _keypadEntrance.dispose();
    _game.dispose();
    super.dispose();
  }

  // Progression ---------------------------------------------------------------

  void _onCountdownStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    if (_countdownIndex < _countdownLabels.length - 1) {
      setState(() => _countdownIndex++);
      _countdown.forward(from: 0);
      return;
    }

    _game.beginPresenting();
    _step.forward(from: 0);
  }

  void _onStepStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    if (_game.hasNextStep) {
      _game.advance();
      _step.forward(from: 0);
      return;
    }

    _game.beginInput();
    _keypadEntrance.forward(from: 0);
  }

  Future<void> _submit() async {
    final NavigatorState navigator = Navigator.of(context);
    final GameResult result = _game.submit();

    await showResultDialog(context: context, result: result);

    // Dismissing the modal ends the round and returns to configuration.
    if (mounted) navigator.pop();
  }

  // UI ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        intensity: 0.5,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _game,
            builder: (BuildContext context, _) {
              final GamePhase phase = _game.phase;
              final bool answering = phase == GamePhase.input || phase == GamePhase.result;

              return Column(
                children: <Widget>[
                  _TopBar(
                    game: _game,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey<bool>(answering),
                          child: _buildStage(phase),
                        ),
                      ),
                    ),
                  ),
                  if (answering)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: _keypadEntrance, curve: Curves.easeOutCubic),
                        ),
                        child: CustomKeypad(
                          entrance: _keypadEntrance,
                          onDigit: _game.appendDigit,
                          onToggleSign: _game.toggleSign,
                          onBackspace: _game.backspace,
                          onSubmit: _submit,
                          canSubmit: _game.canSubmit,
                          canBackspace: _game.canBackspace,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStage(GamePhase phase) {
    switch (phase) {
      case GamePhase.countdown:
        return CountdownView(
          animation: _countdown,
          label: _countdownLabels[_countdownIndex],
        );
      case GamePhase.presenting:
        return SequenceStage(animation: _step, step: _game.currentStep);
      case GamePhase.input:
      case GamePhase.result:
        return AnswerDisplay(entry: _game.entry);
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.game, required this.onClose});

  final GameController game;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bool presenting = game.phase == GamePhase.presenting;
    final String caption = switch (game.phase) {
      GamePhase.countdown => 'Get ready',
      GamePhase.presenting => '${game.stepIndex + 1} of ${game.sequence.length}',
      GamePhase.input || GamePhase.result => 'Enter the total',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Pressable(
                onTap: onClose,
                pressedScale: 0.88,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Text(
                    caption,
                    key: ValueKey<String>(caption),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.value.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              // Balances the close button so the caption stays optically centred.
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: presenting ? 1 : 0.25,
            child: RoundProgressBar(
              progress: game.phase == GamePhase.countdown ? 0 : game.progress,
            ),
          ),
        ],
      ),
    );
  }
}
