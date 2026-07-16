import 'dart:math';

import '../data/bible_data.dart';
import '../models/reading_plan.dart';

/// Generates a complete reading plan from a [ReadingOrder] and [targetDays].
///
/// The total reading units are 1,193:
///   • 1,189 Bible chapters
///   • −1  for Psalm 119 (treated as a single chapter in the raw data)
///   • +5  for the five Psalm 119 parts
///
/// Chapters per day = ⌈1193 / targetDays⌉ — so the plan always finishes
/// on or before the target.  The final day may have fewer units than the rest.
class ReadingPlanGenerator {
  /// Returns all [DayAssignment]s for the given order and duration.
  static List<DayAssignment> generate({
    required ReadingOrder order,
    required int targetDays,
  }) {
    final units = _buildUnits(order);
    final perDay = (units.length / targetDays).ceil();
    final assignments = <DayAssignment>[];
    var dayNumber = 1;

    for (var i = 0; i < units.length; i += perDay) {
      final slice = units.sublist(i, min(i + perDay, units.length));
      assignments.add(DayAssignment(dayNumber: dayNumber, units: slice));
      dayNumber++;
    }

    return assignments;
  }

  /// Convenience: returns only the assignment for one specific day (1-based).
  /// Returns null if [day] is out of range.
  static DayAssignment? dayAssignment({
    required ReadingOrder order,
    required int targetDays,
    required int day,
  }) {
    if (day < 1) return null;
    final units = _buildUnits(order);
    final perDay = (units.length / targetDays).ceil();
    final start = (day - 1) * perDay;
    if (start >= units.length) return null;
    final slice = units.sublist(start, min(start + perDay, units.length));
    return DayAssignment(dayNumber: day, units: slice);
  }

  /// Total number of days in the generated plan (may be < targetDays if the
  /// last day runs short).
  static int totalDays({
    required ReadingOrder order,
    required int targetDays,
  }) {
    final units = _buildUnits(order);
    final perDay = (units.length / targetDays).ceil();
    return (units.length / perDay).ceil();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static List<ReadingUnit> _buildUnits(ReadingOrder order) {
    final bookSequence = _sequenceFor(order);
    final units = <ReadingUnit>[];

    for (final bookName in bookSequence) {
      final chapters = chaptersInBook(bookName);
      for (var ch = 1; ch <= chapters; ch++) {
        if (bookName == 'Psalms' && ch == 119) {
          // Split Psalm 119 into 5 equal-ish parts
          units.addAll(_psalm119Parts());
        } else {
          units.add(ReadingUnit(bookName: bookName, chapter: ch));
        }
      }
    }
    return units;
  }

  static List<ReadingUnit> _psalm119Parts() => const [
        ReadingUnit(bookName: 'Psalms', chapter: 119, verseFrom: 1,   verseTo: 35),
        ReadingUnit(bookName: 'Psalms', chapter: 119, verseFrom: 36,  verseTo: 70),
        ReadingUnit(bookName: 'Psalms', chapter: 119, verseFrom: 71,  verseTo: 105),
        ReadingUnit(bookName: 'Psalms', chapter: 119, verseFrom: 106, verseTo: 140),
        ReadingUnit(bookName: 'Psalms', chapter: 119, verseFrom: 141, verseTo: 176),
      ];

  static List<String> _sequenceFor(ReadingOrder order) => switch (order) {
        ReadingOrder.canonical     => orderCanonical,
        ReadingOrder.gospelsFirst  => orderGospelsFirst,
        ReadingOrder.psalmsFirst   => orderPsalmsFirst,
        ReadingOrder.chronological => orderChronological,
      };
}
