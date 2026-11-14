import '../../domain/entities/game_settings.dart';
import '../../domain/entities/math_operation.dart';
import '../../domain/entities/number_range.dart';

/// Serialisable mirror of [GameSettings]. Keeping (de)serialisation here means
/// the domain entity stays free of storage concerns.
class GameSettingsModel extends GameSettings {
  GameSettingsModel({
    required super.speedMillis,
    required super.range,
    required super.sequenceLength,
    required super.allowNegativeResults,
    required super.operations,
  });

  factory GameSettingsModel.fromEntity(GameSettings settings) {
    return GameSettingsModel(
      speedMillis: settings.speedMillis,
      range: settings.range,
      sequenceLength: settings.sequenceLength,
      allowNegativeResults: settings.allowNegativeResults,
      operations: settings.operations,
    );
  }

  /// Tolerant of missing or unknown values — anything unreadable falls back to
  /// the corresponding default rather than throwing.
  factory GameSettingsModel.fromJson(Map<String, dynamic> json) {
    final GameSettings defaults = GameSettings.initial();

    final Object? rawOperations = json['operations'];
    final Set<MathOperation> operations = <MathOperation>{
      if (rawOperations is List)
        for (final Object? id in rawOperations)
          if (id is String && MathOperation.fromId(id) != null) MathOperation.fromId(id)!,
    };

    return GameSettingsModel(
      speedMillis: json['speedMillis'] is int ? json['speedMillis'] as int : defaults.speedMillis,
      range: json['range'] is String
          ? NumberRange.fromId(json['range'] as String) ?? defaults.range
          : defaults.range,
      sequenceLength:
          json['sequenceLength'] is int ? json['sequenceLength'] as int : defaults.sequenceLength,
      allowNegativeResults: json['allowNegativeResults'] is bool
          ? json['allowNegativeResults'] as bool
          : defaults.allowNegativeResults,
      operations: operations.isEmpty ? defaults.operations : operations,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'speedMillis': speedMillis,
        'range': range.id,
        'sequenceLength': sequenceLength,
        'allowNegativeResults': allowNegativeResults,
        'operations': operations.map((MathOperation o) => o.id).toList(growable: false),
      };
}
