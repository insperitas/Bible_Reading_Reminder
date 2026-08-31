import '../data/bible_data.dart';
import '../models/reading_plan.dart';

/// Builds jw.org / JW Library deep-link URLs for Bible passages.
///
/// URL format:
///   https://www.jw.org/finder?srcid=jwlshare&wtlocale=E&prefer=lang
///          &bible=BBBCCCVVV&pub=nwtsty
///
/// BBB = 3-digit book number (Genesis=001 … Revelation=066)
/// CCC = 3-digit chapter number
/// VVV = 3-digit verse number (001 = start of chapter; Psalm 119 parts
///       use the actual opening verse of that part)
abstract final class JwBibleUrl {
  static const _base =
      'https://www.jw.org/finder?srcid=jwlshare&wtlocale=E&prefer=lang&pub=nwtsty';

  /// URL for a specific verse (defaults to verse 1 = start of chapter).
  static String forVerse(String bookName, int chapter, {int verse = 1}) {
    final bookNum = bookNumbers[bookName] ?? 1;
    // Use 2-digit book numbers (books 1..66) to avoid unnecessary leading zeros.
    final ref = bookNum.toString().padLeft(2, '0') +
        chapter.toString().padLeft(3, '0') +
        verse.toString().padLeft(3, '0');
    return '$_base&bible=$ref';
  }

  /// URL for a [ReadingUnit] — uses the part's opening verse when set.
  static String forUnit(ReadingUnit unit) =>
      forVerse(unit.bookName, unit.chapter, verse: unit.verseFrom ?? 1);
}
