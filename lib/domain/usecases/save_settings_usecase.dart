import '../entities/game_settings.dart';
import '../repositories/settings_repository.dart';

class SaveSettingsUseCase {
  const SaveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(GameSettings settings) => _repository.save(settings);
}
