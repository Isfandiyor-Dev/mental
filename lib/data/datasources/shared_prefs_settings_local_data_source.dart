import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_settings_model.dart';
import 'settings_local_data_source.dart';

/// Persists configuration to the platform key-value store.
///
/// The whole configuration goes in as one JSON string under a single key, so
/// adding or removing a setting later needs no migration step —
/// [GameSettingsModel.fromJson] already substitutes the default for anything
/// missing and ignores keys it no longer knows about.
class SharedPrefsSettingsLocalDataSource implements SettingsLocalDataSource {
  static const String _key = 'mental.settings';

  /// Held as the [Future] rather than the resolved value so that concurrent
  /// reads and writes share a single platform round-trip.
  Future<SharedPreferences>? _preferences;

  Future<SharedPreferences> get _store =>
      _preferences ??= SharedPreferences.getInstance();

  @override
  Future<GameSettingsModel?> read() async {
    try {
      final String? raw = (await _store).getString(_key);
      if (raw == null) return null; // first launch

      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      return GameSettingsModel.fromJson(decoded);
    } catch (error) {
      // Unreadable or corrupt storage must never block launch; the repository
      // falls back to the novice defaults instead.
      debugPrint('Mental: could not read saved settings ($error)');
      return null;
    }
  }

  @override
  Future<void> write(GameSettingsModel settings) async {
    try {
      await (await _store).setString(_key, jsonEncode(settings.toJson()));
    } catch (error) {
      // A failed save is not worth interrupting the user over — the in-memory
      // state is already correct for this session.
      debugPrint('Mental: could not save settings ($error)');
    }
  }
}
