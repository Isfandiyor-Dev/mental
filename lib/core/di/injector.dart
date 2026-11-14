import 'package:flutter/foundation.dart';

import '../../data/datasources/settings_local_data_source.dart';
import '../../data/datasources/shared_prefs_settings_local_data_source.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/services/dart_random_source.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/random_source.dart';
import '../../domain/usecases/evaluate_answer_usecase.dart';
import '../../domain/usecases/generate_sequence_usecase.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';

/// Composition root. Everything is wired here and nowhere else, so the
/// presentation layer only ever depends on domain abstractions.
///
/// Dependencies are `late final` and therefore built lazily on first use.
class Injector {
  Injector();

  static Injector _instance = Injector();

  static Injector get instance => _instance;

  /// Discards the graph and builds a fresh one. Tests use this to isolate from
  /// one another, since the settings data source caches its platform handle.
  @visibleForTesting
  static void reset() => _instance = Injector();

  // Data ---------------------------------------------------------------------
  late final SettingsLocalDataSource _settingsDataSource =
      SharedPrefsSettingsLocalDataSource();
  late final RandomSource randomSource = DartRandomSource();

  // Repositories -------------------------------------------------------------
  late final SettingsRepository settingsRepository = SettingsRepositoryImpl(_settingsDataSource);

  // Use cases ----------------------------------------------------------------
  late final GetSettingsUseCase getSettings = GetSettingsUseCase(settingsRepository);
  late final SaveSettingsUseCase saveSettings = SaveSettingsUseCase(settingsRepository);
  late final GenerateSequenceUseCase generateSequence = GenerateSequenceUseCase(randomSource);
  late final EvaluateAnswerUseCase evaluateAnswer = const EvaluateAnswerUseCase();
}
