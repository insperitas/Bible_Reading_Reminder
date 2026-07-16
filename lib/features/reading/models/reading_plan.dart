/// Models for the Bible reading plan feature.

// ── Reading order ──────────────────────────────────────────────────────────

enum ReadingOrder {
  canonical,
  gospelsFirst,
  psalmsFirst,
  chronological;

  String get displayName => switch (this) {
        ReadingOrder.canonical     => 'Genesis to Revelation',
        ReadingOrder.gospelsFirst  => 'Gospels first',
        ReadingOrder.psalmsFirst   => 'Psalms first',
        ReadingOrder.chronological => 'Chronological order',
      };

  String get description => switch (this) {
        ReadingOrder.canonical =>
          'Follow the Bible from beginning to end.',
        ReadingOrder.gospelsFirst =>
          'Start with Jesus — Matthew through to Acts — then the whole Old Testament.',
        ReadingOrder.psalmsFirst =>
          'Begin with poetry and prayer, then the rest of the Bible.',
        ReadingOrder.chronological =>
          'Read books in the order events happened historically.',
      };
}

// ── A single reading unit ──────────────────────────────────────────────────

/// One "unit" of reading — normally a full chapter.
/// Psalm 119 is split into 5 parts (verses 1–35, 36–70, 71–105, 106–140, 141–176).
class ReadingUnit {
  final String bookName;
  final int chapter;

  /// Non-null only for Psalm 119 parts.
  final int? verseFrom;
  final int? verseTo;

  const ReadingUnit({
    required this.bookName,
    required this.chapter,
    this.verseFrom,
    this.verseTo,
  });

  bool get isPartialChapter => verseFrom != null;

  /// Display label, e.g. "Psalms 23" or "Psalms 119 (1–35)".
  String get label {
    final base = '$bookName $chapter';
    if (verseFrom != null) return '$base ($verseFrom\u2013$verseTo)';
    return base;
  }
}

// ── A single day's reading assignment ─────────────────────────────────────

class DayAssignment {
  final int dayNumber;        // 1-based
  final List<ReadingUnit> units;

  const DayAssignment({required this.dayNumber, required this.units});

  String get summary {
    if (units.isEmpty) return '';
    if (units.length == 1) return units.first.label;

    // Group consecutive chapters from the same book
    final parts = <String>[];
    String? currentBook;
    int? firstChapter;
    int? lastChapter;

    void flush() {
      if (currentBook == null) return;
      if (firstChapter == lastChapter) {
        parts.add('$currentBook $firstChapter');
      } else {
        parts.add('$currentBook $firstChapter\u2013$lastChapter');
      }
    }

    for (final u in units) {
      if (u.isPartialChapter) {
        flush();
        currentBook = null;
        parts.add(u.label);
      } else if (u.bookName == currentBook) {
        lastChapter = u.chapter;
      } else {
        flush();
        currentBook = u.bookName;
        firstChapter = u.chapter;
        lastChapter = u.chapter;
      }
    }
    flush();
    return parts.join(', ');
  }
}
