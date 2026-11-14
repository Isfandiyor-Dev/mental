import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/game_settings.dart';
import '../../domain/entities/math_operation.dart';
import '../../domain/entities/number_range.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';

/// Owns the configuration screen's state. Every mutation writes through to the
/// repository, but the UI never waits on that round-trip.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required this._getSettings,
    required this._saveSettings,
  });

  final GetSettingsUseCase _getSettings;
  final SaveSettingsUseCase _saveSettings;

  GameSettings _settings = GameSettings.initial();
  bool _isLoading = true;
  bool _isDisposed = false;

  /// Set by [_preview] when a slider moves; cleared once [commit] flushes it.
  bool _hasPendingWrite = false;

  GameSettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _settings = await _getSettings();
    _isLoading = false;
    _safeNotify();
  }

  // Sliders update live but defer their write until the drag ends.
  void setSpeedMillis(int value) => _preview(_settings.copyWith(speedMillis: value));

  void setSequenceLength(int value) => _preview(_settings.copyWith(sequenceLength: value));

  /// Flushes a pending slider change. Called on release, so scrubbing a slider
  /// writes once at the end instead of on every frame of the drag.
  void commit() {
    if (!_hasPendingWrite) return;
    _hasPendingWrite = false;
    unawaited(_saveSettings(_settings));
  }

  // Discrete controls persist the moment they change.
  void setRange(NumberRange range) => _update(_settings.copyWith(range: range));

  void setAllowNegativeResults(bool value) =>
      _update(_settings.copyWith(allowNegativeResults: value));

  /// Toggles an operation. Returns `false` when the change was rejected because
  /// it would have cleared the last remaining operation — the UI answers that
  /// with a shake instead of silently ignoring the tap.
  bool toggleOperation(MathOperation operation) {
    final Set<MathOperation> next = Set<MathOperation>.of(_settings.operations);
    if (next.contains(operation)) {
      if (next.length == 1) return false;
      next.remove(operation);
    } else {
      next.add(operation);
    }
    _update(_settings.copyWith(operations: next));
    return true;
  }

  /// Applies a change and writes it through immediately.
  void _update(GameSettings next) {
    if (next == _settings) return;
    _settings = next;
    _hasPendingWrite = false;
    _safeNotify();
    // Fire-and-forget: persistence must never block the UI.
    unawaited(_saveSettings(next));
  }

  /// Applies a change to in-memory state only, leaving the write to [commit].
  void _preview(GameSettings next) {
    if (next == _settings) return;
    _settings = next;
    _hasPendingWrite = true;
    _safeNotify();
  }

  void _safeNotify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
