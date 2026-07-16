import '../../../shared/models/activity_type.dart';
import '../../../shared/services/settings_service.dart';
import '../models/reading_plan.dart';
import '../services/reading_plan_generator.dart';

/// Convenience wrapper around [SettingsService] for the Bible reading activity.
///
/// All reading state lives in [ActivityConfig.options] under [ActivityType.bibleReading]:
///   readingOrder    — ReadingOrder.name
///   targetDays      — int as string
///   startDate       — yyyy-MM-dd (informational; plan position is not date-driven)
///   currentDay      — 1-based position in the plan (advances on mark-complete)
///   lastReadDate    — yyyy-MM-dd of the last mark-complete (to guard double-taps)
class ReadingProgressService {
  const ReadingProgressService(this._settings);

  final SettingsService _settings;

  // ── Config access ──────────────────────────────────────────────────────

  bool get isConfigured {
    final opts = _settings.configFor(ActivityType.bibleReading).options;
    return opts.containsKey('currentDay');
  }

  ReadingOrder get readingOrder {
    final name = _settings.configFor(ActivityType.bibleReading).options['readingOrder'] ?? '';
    return ReadingOrder.values.firstWhere(
      (o) => o.name == name,
      orElse: () => ReadingOrder.canonical,
    );
  }

  int get targetDays =>
      int.tryParse(
        _settings.configFor(ActivityType.bibleReading).options['targetDays'] ?? '',
      ) ??
      365;

  int get currentDay =>
      int.tryParse(
        _settings.configFor(ActivityType.bibleReading).options['currentDay'] ?? '',
      ) ??
      1;

  bool get hasReadToday {
    final last = _settings.configFor(ActivityType.bibleReading).options['lastReadDate'];
    return last == _today();
  }

  bool get planComplete =>
      currentDay > ReadingPlanGenerator.totalDays(
        order: readingOrder,
        targetDays: targetDays,
      );

  // ── Today's assignment ─────────────────────────────────────────────────

  DayAssignment? get todayAssignment => ReadingPlanGenerator.dayAssignment(
        order: readingOrder,
        targetDays: targetDays,
        day: currentDay,
      );

  DayAssignment? get tomorrowAssignment => ReadingPlanGenerator.dayAssignment(
        order: readingOrder,
        targetDays: targetDays,
        day: currentDay + 1,
      );

  // ── Progress ───────────────────────────────────────────────────────────

  /// Records today's reading as complete and advances [currentDay] by 1.
  /// No-op if already marked today.
  Future<void> markTodayComplete() async {
    if (hasReadToday) return;
    await _settings.setOption(ActivityType.bibleReading, 'lastReadDate', _today());
    await _settings.setOption(
      ActivityType.bibleReading,
      'currentDay',
      (currentDay + 1).toString(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String targetLabel() {
    final days = targetDays;
    if (days <= 183) return '6 months';
    if (days <= 365) return '1 year';
    if (days <= 730) return '2 years';
    return '$days days';
  }

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);
}
