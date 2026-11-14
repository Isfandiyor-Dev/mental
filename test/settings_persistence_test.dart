import 'package:flutter_test/flutter_test.dart';
import 'package:mental/data/datasources/shared_prefs_settings_local_data_source.dart';
import 'package:mental/data/models/game_settings_model.dart';
import 'package:mental/data/repositories/settings_repository_impl.dart';
import 'package:mental/domain/entities/game_settings.dart';
import 'package:mental/domain/entities/math_operation.dart';
import 'package:mental/domain/entities/number_range.dart';
import 'package:mental/domain/repositories/settings_repository.dart';
import 'package:mental/domain/usecases/get_settings_usecase.dart';
import 'package:mental/domain/usecases/save_settings_usecase.dart';
import 'package:mental/presentation/controllers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts writes so the slider's deferred-save behaviour can be asserted
/// directly, without going through the widget tree.
class _RecordingRepository implements SettingsRepository {
  _RecordingRepository([this.stored]);

  GameSettings? stored;
  GameSettings? lastSaved;
  int saveCount = 0;

  @override
  Future<GameSettings> load() async => stored ?? GameSettings.initial();

  @override
  Future<void> save(GameSettings settings) async {
    stored = settings;
    lastSaved = settings;
    saveCount++;
  }
}

SettingsController controllerFor(SettingsRepository repository) {
  return SettingsController(
    getSettings: GetSettingsUseCase(repository),
    saveSettings: SaveSettingsUseCase(repository),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('novice defaults', () {
    test('first launch starts beginner-friendly', () {
      final GameSettings defaults = GameSettings.initial();

      expect(defaults.speedMillis, 2000);
      expect(defaults.range, NumberRange.oneDigit);
      expect(defaults.sequenceLength, 5);
      expect(defaults.allowNegativeResults, isFalse);
      expect(defaults.operations, <MathOperation>{MathOperation.addition});
    });
  });

  group('NumberRange', () {
    test('every band starts at 1 and caps at its digit count', () {
      expect(NumberRange.values.map((NumberRange r) => r.min), everyElement(1));
      expect(NumberRange.oneDigit.max, 9);
      expect(NumberRange.twoDigits.max, 99);
      expect(NumberRange.threeDigits.max, 999);
      expect(NumberRange.fourDigits.max, 9999);
    });

    test('labels read as cumulative ranges', () {
      expect(
        NumberRange.values.map((NumberRange r) => r.label),
        <String>['1–9', '1–99', '1–999', '1–9999'],
      );
    });

    test('persistence ids are unchanged, so a saved selection still resolves', () {
      // These ids predate the rename; breaking them would silently reset every
      // existing user's range back to the default.
      expect(NumberRange.fromId('units'), NumberRange.oneDigit);
      expect(NumberRange.fromId('tens'), NumberRange.twoDigits);
      expect(NumberRange.fromId('hundreds'), NumberRange.threeDigits);
      expect(NumberRange.fromId('thousands'), NumberRange.fourDigits);
    });
  });

  group('SharedPrefsSettingsLocalDataSource', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('reports nothing stored on a clean install', () async {
      expect(await SharedPrefsSettingsLocalDataSource().read(), isNull);
    });

    test('round-trips every field', () async {
      final SharedPrefsSettingsLocalDataSource dataSource =
          SharedPrefsSettingsLocalDataSource();

      final GameSettings original = GameSettings(
        speedMillis: 3500,
        range: NumberRange.threeDigits,
        sequenceLength: 42,
        allowNegativeResults: true,
        operations: <MathOperation>{MathOperation.division, MathOperation.multiplication},
      );

      await dataSource.write(GameSettingsModel.fromEntity(original));

      // A fresh instance, as if the app had been restarted.
      final GameSettings? restored = await SharedPrefsSettingsLocalDataSource().read();

      expect(restored, isNotNull);
      expect(restored, original);
    });

    test('falls back to defaults when the stored payload is corrupt', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'mental.settings': 'not json at all',
      });

      final SettingsRepository repository =
          SettingsRepositoryImpl(SharedPrefsSettingsLocalDataSource());

      expect(await repository.load(), GameSettings.initial());
    });

    test('the repository persists through to storage', () async {
      final SettingsRepository repository =
          SettingsRepositoryImpl(SharedPrefsSettingsLocalDataSource());

      final GameSettings updated =
          GameSettings.initial().copyWith(sequenceLength: 30, speedMillis: 900);
      await repository.save(updated);

      final SettingsRepository reopened =
          SettingsRepositoryImpl(SharedPrefsSettingsLocalDataSource());
      expect(await reopened.load(), updated);
    });
  });

  group('SettingsController write policy', () {
    test('slider drags update state without writing, and commit writes once',
        () async {
      final _RecordingRepository repository = _RecordingRepository();
      final SettingsController controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      // Simulate a drag across many frames.
      controller.setSpeedMillis(1500);
      controller.setSpeedMillis(1750);
      controller.setSpeedMillis(2400);
      controller.setSequenceLength(12);

      expect(repository.saveCount, 0, reason: 'dragging must not touch storage');
      expect(controller.settings.speedMillis, 2400, reason: 'state stays live');
      expect(controller.settings.sequenceLength, 12);

      // Release.
      controller.commit();
      await Future<void>.delayed(Duration.zero);

      expect(repository.saveCount, 1);
      expect(repository.lastSaved!.speedMillis, 2400);
      expect(repository.lastSaved!.sequenceLength, 12);
    });

    test('commit with nothing pending is a no-op', () async {
      final _RecordingRepository repository = _RecordingRepository();
      final SettingsController controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      controller.commit();
      controller.commit();
      await Future<void>.delayed(Duration.zero);

      expect(repository.saveCount, 0);
    });

    test('discrete controls persist immediately', () async {
      final _RecordingRepository repository = _RecordingRepository();
      final SettingsController controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      controller.setRange(NumberRange.fourDigits);
      await Future<void>.delayed(Duration.zero);
      expect(repository.saveCount, 1);

      controller.setAllowNegativeResults(true);
      await Future<void>.delayed(Duration.zero);
      expect(repository.saveCount, 2);

      controller.toggleOperation(MathOperation.division);
      await Future<void>.delayed(Duration.zero);
      expect(repository.saveCount, 3);

      expect(repository.lastSaved!.range, NumberRange.fourDigits);
      expect(repository.lastSaved!.allowNegativeResults, isTrue);
      expect(repository.lastSaved!.operations, contains(MathOperation.division));
    });

    test('a rejected operation toggle writes nothing', () async {
      final _RecordingRepository repository = _RecordingRepository();
      final SettingsController controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.load();

      // Addition is the only default selection, so removing it is refused.
      expect(controller.toggleOperation(MathOperation.addition), isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(repository.saveCount, 0);
      expect(controller.settings.operations, <MathOperation>{MathOperation.addition});
    });

    test('stored settings win over defaults on load', () async {
      final GameSettings saved =
          GameSettings.initial().copyWith(speedMillis: 3000, sequenceLength: 20);
      final SettingsController controller = controllerFor(_RecordingRepository(saved));
      addTearDown(controller.dispose);

      expect(controller.isLoading, isTrue);
      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.settings, saved);
    });
  });
}
