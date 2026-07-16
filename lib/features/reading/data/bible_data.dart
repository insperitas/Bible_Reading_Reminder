/// Complete canonical Bible data.
///
/// Every book is listed with its chapter count.  The total is 1,189 chapters
/// (929 OT + 260 NT).  Psalm 119 is special-cased in [ReadingUnit] as 5 parts
/// rather than 1 chapter, giving 1,193 reading units in total.

// ── Book record ────────────────────────────────────────────────────────────

class BibleBook {
  final String name;
  final int chapters;

  const BibleBook(this.name, this.chapters);
}

// ── All 66 books ───────────────────────────────────────────────────────────

const List<BibleBook> bibleBooks = [
  // Old Testament — 39 books, 929 chapters
  BibleBook('Genesis',          50),
  BibleBook('Exodus',           40),
  BibleBook('Leviticus',        27),
  BibleBook('Numbers',          36),
  BibleBook('Deuteronomy',      34),
  BibleBook('Joshua',           24),
  BibleBook('Judges',           21),
  BibleBook('Ruth',              4),
  BibleBook('1 Samuel',         31),
  BibleBook('2 Samuel',         24),
  BibleBook('1 Kings',          22),
  BibleBook('2 Kings',          25),
  BibleBook('1 Chronicles',     29),
  BibleBook('2 Chronicles',     36),
  BibleBook('Ezra',             10),
  BibleBook('Nehemiah',         13),
  BibleBook('Esther',           10),
  BibleBook('Job',              42),
  BibleBook('Psalms',          150),
  BibleBook('Proverbs',         31),
  BibleBook('Ecclesiastes',     12),
  BibleBook('Song of Solomon',   8),
  BibleBook('Isaiah',           66),
  BibleBook('Jeremiah',         52),
  BibleBook('Lamentations',      5),
  BibleBook('Ezekiel',          48),
  BibleBook('Daniel',           12),
  BibleBook('Hosea',            14),
  BibleBook('Joel',              3),
  BibleBook('Amos',              9),
  BibleBook('Obadiah',           1),
  BibleBook('Jonah',             4),
  BibleBook('Micah',             7),
  BibleBook('Nahum',             3),
  BibleBook('Habakkuk',          3),
  BibleBook('Zephaniah',         3),
  BibleBook('Haggai',            2),
  BibleBook('Zechariah',        14),
  BibleBook('Malachi',           4),

  // New Testament — 27 books, 260 chapters
  BibleBook('Matthew',          28),
  BibleBook('Mark',             16),
  BibleBook('Luke',             24),
  BibleBook('John',             21),
  BibleBook('Acts',             28),
  BibleBook('Romans',           16),
  BibleBook('1 Corinthians',    16),
  BibleBook('2 Corinthians',    13),
  BibleBook('Galatians',         6),
  BibleBook('Ephesians',         6),
  BibleBook('Philippians',       4),
  BibleBook('Colossians',        4),
  BibleBook('1 Thessalonians',   5),
  BibleBook('2 Thessalonians',   3),
  BibleBook('1 Timothy',         6),
  BibleBook('2 Timothy',         4),
  BibleBook('Titus',             3),
  BibleBook('Philemon',          1),
  BibleBook('Hebrews',          13),
  BibleBook('James',             5),
  BibleBook('1 Peter',           5),
  BibleBook('2 Peter',           3),
  BibleBook('1 John',            5),
  BibleBook('2 John',            1),
  BibleBook('3 John',            1),
  BibleBook('Jude',              1),
  BibleBook('Revelation',       22),
];

// ── Reading order sequences ────────────────────────────────────────────────
//
// Each order is a list of book names in the sequence to be read.
// The generator expands each entry into its chapters automatically.

/// Genesis → Revelation (standard published order).
const List<String> orderCanonical = [
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
  'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
  '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
  'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms',
  'Proverbs', 'Ecclesiastes', 'Song of Solomon',
  'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
  'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
  'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
  'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
  'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
  '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
  'Hebrews', 'James', '1 Peter', '2 Peter',
  '1 John', '2 John', '3 John', 'Jude', 'Revelation',
];

/// Gospels + Acts first, then Genesis → Malachi, then Romans → Revelation.
const List<String> orderGospelsFirst = [
  'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
  'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
  '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
  'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms',
  'Proverbs', 'Ecclesiastes', 'Song of Solomon',
  'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
  'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
  'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
  'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
  '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
  'Hebrews', 'James', '1 Peter', '2 Peter',
  '1 John', '2 John', '3 John', 'Jude', 'Revelation',
];

/// Psalms first, then the canonical order for everything else.
const List<String> orderPsalmsFirst = [
  'Psalms',
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
  'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
  '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
  'Ezra', 'Nehemiah', 'Esther', 'Job',
  'Proverbs', 'Ecclesiastes', 'Song of Solomon',
  'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
  'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
  'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
  'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
  'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
  '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
  'Hebrews', 'James', '1 Peter', '2 Peter',
  '1 John', '2 John', '3 John', 'Jude', 'Revelation',
];

/// Books ordered roughly by the historical period they cover.
const List<String> orderChronological = [
  'Job',
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
  'Joshua', 'Judges', 'Ruth',
  '1 Samuel', '2 Samuel', '1 Chronicles', 'Psalms',
  '1 Kings', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
  '2 Kings', '2 Chronicles',
  'Obadiah', 'Joel', 'Jonah', 'Amos', 'Hosea', 'Micah',
  'Isaiah', 'Nahum', 'Zephaniah', 'Habakkuk',
  'Jeremiah', 'Lamentations',
  'Ezekiel', 'Daniel',
  'Ezra', 'Haggai', 'Zechariah', 'Nehemiah', 'Esther', 'Malachi',
  'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'James',
  '1 Thessalonians', '2 Thessalonians',
  'Galatians',
  '1 Corinthians', '2 Corinthians',
  'Romans',
  'Philippians', 'Philemon', 'Colossians', 'Ephesians',
  '1 Timothy', 'Titus', '2 Timothy',
  'Hebrews', '1 Peter', '2 Peter',
  '1 John', '2 John', '3 John', 'Jude',
  'Revelation',
];

// ── Helper ─────────────────────────────────────────────────────────────────

/// Returns the chapter count for [bookName], or 0 if not found.
int chaptersInBook(String bookName) =>
    bibleBooks.firstWhere((b) => b.name == bookName, orElse: () => const BibleBook('', 0)).chapters;

// ── JW.org / JW Library Bible reference numbers ───────────────────────────
//
// Used to build the deep-link URL:
//   bible=BBBCCCVVV  (each section zero-padded to 3 digits)
// e.g. Malachi 1:1 → book 39 → bible=039001001
//
// Numbers follow the standard Protestant canon order (Genesis=1 … Revelation=66).

const Map<String, int> bookNumbers = {
  'Genesis': 1, 'Exodus': 2, 'Leviticus': 3, 'Numbers': 4,
  'Deuteronomy': 5, 'Joshua': 6, 'Judges': 7, 'Ruth': 8,
  '1 Samuel': 9, '2 Samuel': 10, '1 Kings': 11, '2 Kings': 12,
  '1 Chronicles': 13, '2 Chronicles': 14, 'Ezra': 15, 'Nehemiah': 16,
  'Esther': 17, 'Job': 18, 'Psalms': 19, 'Proverbs': 20,
  'Ecclesiastes': 21, 'Song of Solomon': 22, 'Isaiah': 23, 'Jeremiah': 24,
  'Lamentations': 25, 'Ezekiel': 26, 'Daniel': 27, 'Hosea': 28,
  'Joel': 29, 'Amos': 30, 'Obadiah': 31, 'Jonah': 32, 'Micah': 33,
  'Nahum': 34, 'Habakkuk': 35, 'Zephaniah': 36, 'Haggai': 37,
  'Zechariah': 38, 'Malachi': 39,
  'Matthew': 40, 'Mark': 41, 'Luke': 42, 'John': 43, 'Acts': 44,
  'Romans': 45, '1 Corinthians': 46, '2 Corinthians': 47, 'Galatians': 48,
  'Ephesians': 49, 'Philippians': 50, 'Colossians': 51,
  '1 Thessalonians': 52, '2 Thessalonians': 53, '1 Timothy': 54,
  '2 Timothy': 55, 'Titus': 56, 'Philemon': 57, 'Hebrews': 58,
  'James': 59, '1 Peter': 60, '2 Peter': 61, '1 John': 62,
  '2 John': 63, '3 John': 64, 'Jude': 65, 'Revelation': 66,
};
