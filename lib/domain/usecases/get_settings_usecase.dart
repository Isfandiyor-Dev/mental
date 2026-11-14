import '../entities/game_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettingsUseCase {
  const GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<GameSettings> call() => _repository.load();
}
