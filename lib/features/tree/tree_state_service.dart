import 'package:shared_preferences/shared_preferences.dart';

import 'tree_state.dart';

/// Persists and computes the tree mascot state.
///
/// Keys in SharedPreferences
/// ─────────────────────────
///   tree_leaf_count           — stored leaf count (0–maxLeaves)
///   tree_last_read_date       — yyyy-MM-dd of last Bible reading completion
///   tree_flower_count         — total flowers earned (0–maxFlowers)
///   tree_flower_date_`<key>`    — yyyy-MM-dd last flower earned for that activity
///
/// Leaf decay rule
/// ───────────────
/// Reading every day keeps the tree at full leaves. If the user misses a
/// day, 2 leaves fall per missed day (grace: reading yesterday counts as
/// "current"). Completing today's reading restores all leaves.
class TreeStateService {
  TreeStateService._(this._prefs);

  final SharedPreferences _prefs;

  static const _keyLeafCount = 'tree_leaf_count';
  static const _keyLastReadDate = 'tree_last_read_date';
  static const _keyFlowerCount = 'tree_flower_count';

  static Future<TreeStateService> load() async =>
      TreeStateService._(await SharedPreferences.getInstance());

  // ── State ─────────────────────────────────────────────────────────────

  /// Returns the current [TreeState], applying leaf decay for missed days.
  TreeState get state => TreeState(
        leafCount: _effectiveLeafCount,
        flowerCount: (_prefs.getInt(_keyFlowerCount) ?? 0)
            .clamp(0, TreeState.maxFlowers),
      );

  int get _effectiveLeafCount {
    final stored =
        (_prefs.getInt(_keyLeafCount) ?? TreeState.maxLeaves)
            .clamp(0, TreeState.maxLeaves);

    final lastReadStr = _prefs.getString(_keyLastReadDate);
    if (lastReadStr == null) return stored;

    final lastRead = DateTime.tryParse(lastReadStr);
    if (lastRead == null) return stored;

    final today = _todayDate();
    final lastReadDay =
        DateTime(lastRead.year, lastRead.month, lastRead.day);
    final daysSince = today.difference(lastReadDay).inDays;

    // No decay if read today (0) or yesterday (1).
    if (daysSince <= 1) return stored;

    final missedDays = daysSince - 1;
    return (stored - missedDays * 2).clamp(0, TreeState.maxLeaves);
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  /// Call when the user marks their daily Bible reading complete.
  /// Restores the tree to full leaves and records today as read.
  Future<void> onReadingComplete() async {
    await _prefs.setInt(_keyLeafCount, TreeState.maxLeaves);
    await _prefs.setString(_keyLastReadDate, _todayStr());
  }

  /// Call when an extra (non-Bible-reading) activity is completed.
  ///
  /// [activityKey] identifies the activity (e.g. `'dailyText'`).
  /// One flower is awarded per activity per day; subsequent calls on the
  /// same day are ignored.
  Future<void> onExtraActivityCompleted(String activityKey) async {
    final dateKey = 'tree_flower_date_$activityKey';
    final today = _todayStr();

    if (_prefs.getString(dateKey) == today) return; // already awarded today

    final current = _prefs.getInt(_keyFlowerCount) ?? 0;
    await _prefs.setInt(
        _keyFlowerCount, (current + 1).clamp(0, TreeState.maxFlowers));
    await _prefs.setString(dateKey, today);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static String _todayStr() =>
      DateTime.now().toIso8601String().substring(0, 10);

  static DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
