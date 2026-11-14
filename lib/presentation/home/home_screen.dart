import 'package:flutter/material.dart';

import '../../core/animation/fade_scale_route.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injector.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/number_formatter.dart';
import '../../domain/entities/game_settings.dart';
import '../controllers/settings_controller.dart';
import '../game/game_screen.dart';
import '../shared/widgets/ambient_background.dart';
import '../shared/widgets/section_card.dart';
import '../shared/widgets/stagger_in.dart';
import 'widgets/neo_slider.dart';
import 'widgets/neo_switch.dart';
import 'widgets/operation_chips.dart';
import 'widgets/range_selector.dart';
import 'widgets/start_button.dart';
import 'widgets/value_pill.dart';

/// Configuration screen. Owns the [SettingsController] for its whole lifetime
/// and disposes it, so nothing outlives the route.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final SettingsController _controller = SettingsController(
    getSettings: Injector.instance.getSettings,
    saveSettings: Injector.instance.saveSettings,
  );

  /// One timeline drives the entrance of every card on the screen.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _controller.load().then((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    // Safety net: flush a slider change that never saw its release event.
    _controller.commit();
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    Navigator.of(context).push(
      FadeScaleRoute<void>(child: GameScreen(settings: _controller.settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, _) {
              if (_controller.isLoading) {
                return const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }
              return _buildContent(_controller.settings);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(GameSettings settings) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              StaggerIn(animation: _entrance, index: 0, child: const _Header()),
              const SizedBox(height: 28),

              // Speed ------------------------------------------------------
              StaggerIn(
                animation: _entrance,
                index: 1,
                child: SectionCard(
                  label: 'Speed interval',
                  trailing: ValuePill(
                    value: NumberFormatter.duration(settings.speedMillis),
                  ),
                  child: NeoSlider(
                    value: settings.speedMillis,
                    min: AppConstants.minSpeedMillis,
                    max: AppConstants.maxSpeedMillis,
                    step: AppConstants.speedStepMillis,
                    onChanged: _controller.setSpeedMillis,
                    onChangeEnd: _controller.commit,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Range + negative operands ---------------------------------
              StaggerIn(
                animation: _entrance,
                index: 2,
                child: SectionCard(
                  label: 'Number range',
                  child: RangeSelector(
                    selected: settings.range,
                    onChanged: _controller.setRange,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sequence length -------------------------------------------
              StaggerIn(
                animation: _entrance,
                index: 3,
                child: SectionCard(
                  label: 'Sequence length',
                  trailing: ValuePill(
                    value: '${settings.sequenceLength} numbers',
                  ),
                  child: NeoSlider(
                    value: settings.sequenceLength,
                    min: AppConstants.minSequenceLength,
                    max: AppConstants.maxSequenceLength,
                    onChanged: _controller.setSequenceLength,
                    onChangeEnd: _controller.commit,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Operations -------------------------------------------------
              StaggerIn(
                animation: _entrance,
                index: 5,
                child: SectionCard(
                  label: 'Operations',
                  trailing: ValuePill(
                    value: '${settings.operations.length} of 4',
                  ),
                  child: OperationChips(
                    selected: settings.operations,
                    onToggle: _controller.toggleOperation,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Negative results ------------------------------------------
              StaggerIn(
                animation: _entrance,
                index: 4,
                child: SectionCard(
                  label: 'Results',
                  child: NeoSwitch(
                    value: settings.allowNegativeResults,
                    title: 'Allow negative results',
                    subtitle: 'Totals may drop below zero, e.g. 5 − 6 = −1',
                    onChanged: _controller.setAllowNegativeResults,
                  ),
                ),
              ),
            ],
          ),
        ),
        StaggerIn(
          animation: _entrance,
          index: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: StartButton(onPressed: _start),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        // Gradient wordmark — the only place the brand gradient touches type.
        ShaderMask(
          shaderCallback: (Rect bounds) =>
              AppColors.brandGradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Mental',
            style: AppTextStyles.display.copyWith(fontSize: 44),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Configure your round, then hold your focus.',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
