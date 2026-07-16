import 'dart:convert';

/// Holds user-configured settings for a single tracked activity.
///
/// [options] is a free-form string→string map so each activity type can
/// store whatever it needs without changing the base class.
///
/// Examples
/// --------
/// Daily Text:       { } — no extra options needed
/// Bible Reading:    { 'method': 'plan', 'planId': 'chronological',
///                     'currentDay': '42' }
/// Meeting Prep:     { 'midweekReminderHour': '18',
///                     'weekendReminderHour': '09' }
class ActivityConfig {
  final bool enabled;

  /// Activity-specific key/value settings.  All values stored as strings
  /// so they serialise cleanly to SharedPreferences JSON.
  final Map<String, String> options;

  const ActivityConfig({
    required this.enabled,
    this.options = const {},
  });

  ActivityConfig copyWith({bool? enabled, Map<String, String>? options}) =>
      ActivityConfig(
        enabled: enabled ?? this.enabled,
        options: options ?? this.options,
      );

  // ── Serialisation ──────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'options': options,
      };

  factory ActivityConfig.fromJson(Map<String, dynamic> json) => ActivityConfig(
        enabled: json['enabled'] as bool? ?? false,
        options: (json['options'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
      );

  String toJsonString() => jsonEncode(toJson());

  factory ActivityConfig.fromJsonString(String s) =>
      ActivityConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// Sensible defaults for each activity type.
  static ActivityConfig defaultFor(Object type) => const ActivityConfig(enabled: false);
}
