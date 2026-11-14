import '../../domain/entities/game_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';
import '../models/game_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<GameSettings> load() async {
    return await _localDataSource.read() ?? GameSettings.initial();
  }

  @override
  Future<void> save(GameSettings settings) {
    return _localDataSource.write(GameSettingsModel.fromEntity(settings));
  }
}
