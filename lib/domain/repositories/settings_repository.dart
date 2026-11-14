import '../entities/game_settings.dart';

/// Contract the data layer fulfils. The domain never learns where settings
/// actually live.
abstract interface class SettingsRepository {
  Future<GameSettings> load();

  Future<void> save(GameSettings settings);
}
