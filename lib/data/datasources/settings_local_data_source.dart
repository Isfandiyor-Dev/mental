import '../models/game_settings_model.dart';

/// Where configuration is physically stored.
///
/// Implemented by [SharedPrefsSettingsLocalDataSource]. Nothing above this
/// interface knows the storage mechanism, so swapping it — for a database, a
/// secure store, a remote sync — touches this layer only.
abstract interface class SettingsLocalDataSource {
  /// Returns `null` when nothing has been saved yet, which the repository reads
  /// as "first launch" and answers with the novice defaults.
  Future<GameSettingsModel?> read();

  Future<void> write(GameSettingsModel settings);
}
