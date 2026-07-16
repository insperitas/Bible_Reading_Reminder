import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_config.dart';
import '../models/activity_type.dart';

/// Persists and retrieves per-activity user settings.
///
/// Each [ActivityType] is stored as a JSON blob under the key
/// `activity_config_<type.name>` in SharedPreferences.
///
/// Usage
/// -----
///   final svc = await SettingsService.load();
///   final cfg = svc.configFor(ActivityType.bibleReading);
///   await svc.save(ActivityType.bibleReading, cfg.copyWith(enabled: true));
class SettingsService {
  SettingsService._(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'activity_config_';
  static const _keyOnboardingComplete = 'onboarding_complete';

  // ── Factory ────────────────────────────────────────────────────────────

  static Future<SettingsService> load() async =>
      SettingsService._(await SharedPreferences.getInstance());

  // ── Onboarding flag ────────────────────────────────────────────────────

  bool get onboardingComplete =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  Future<void> markOnboardingComplete() =>
      _prefs.setBool(_keyOnboardingComplete, true);

  // ── Activity config ────────────────────────────────────────────────────

  /// Returns the stored config for [type], or a disabled default if not yet set.
  ActivityConfig configFor(ActivityType type) {
    final raw = _prefs.getString(_key(type));
    if (raw == null) return ActivityConfig.defaultFor(type);
    try {
      return ActivityConfig.fromJsonString(raw);
    } catch (_) {
      return ActivityConfig.defaultFor(type);
    }
  }

  /// Returns configs for all known activity types.
  Map<ActivityType, ActivityConfig> get allConfigs => {
        for (final t in ActivityType.values) t: configFor(t),
      };

  /// Persists [config] for [type].
  Future<void> save(ActivityType type, ActivityConfig config) =>
      _prefs.setString(_key(type), config.toJsonString());

  /// Convenience: enable or disable an activity without changing its options.
  Future<void> setEnabled(ActivityType type, {required bool enabled}) async {
    final updated = configFor(type).copyWith(enabled: enabled);
    await save(type, updated);
  }

  /// Convenience: update a single option key for an activity.
  Future<void> setOption(
    ActivityType type,
    String key,
    String value,
  ) async {
    final current = configFor(type);
    final newOptions = Map<String, String>.from(current.options)..[key] = value;
    await save(type, current.copyWith(options: newOptions));
  }

  String _key(ActivityType type) => '$_keyPrefix${type.name}';
}
