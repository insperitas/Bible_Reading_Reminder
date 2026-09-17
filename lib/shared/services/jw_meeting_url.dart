/// Builds jw.org deep-link URLs for the Meetings section.
///
/// URL format:
///   https://www.jw.org/finder?srcid=jwlshare&alias=meetings&date=YYYYMMDD&wtlocale=E
///
/// The [date] selects which week's meeting materials to show.
/// We compute the next upcoming meeting day (midweek or weekend) so the
/// link always lands on relevant material.
abstract final class JwMeetingUrl {
  static const _base =
      'https://www.jw.org/finder?srcid=jwlshare&alias=meetings&wtlocale=E';

  /// Weekday numbers for the default meeting schedule (1=Mon … 7=Sun).
  static const _midweekDay = DateTime.thursday; // 4
  static const _weekendDay = DateTime.sunday;   // 7

  /// Returns the URL for the next upcoming meeting (midweek or weekend).
  ///
  /// [midweekDay] and [weekendDay] are weekday numbers using DateTime's
  /// convention (1=Mon ... 7=Sun).
  static String nextMeeting({
    DateTime? from,
    int midweekDay = DateTime.thursday,
    int weekendDay = DateTime.sunday,
  }) {
    final safeMidweek = _validWeekday(midweekDay, DateTime.thursday);
    final safeWeekend = _validWeekday(weekendDay, DateTime.sunday);
    final date = _nextMeetingDate(from ?? DateTime.now(), safeMidweek, safeWeekend);
    return '$_base&date=${_format(date)}';
  }

  /// Finds the next meeting day on or after [from].
  ///
  /// Meeting days (default): Thursday (midweek) and Sunday (weekend).
  /// If today is a meeting day, today is returned.
  static DateTime _nextMeetingDate(DateTime from, int midweekDay, int weekendDay) {
    final today = DateTime(from.year, from.month, from.day);
    // Check each of the next 7 days (covers any meeting-day combo).
    for (var offset = 0; offset < 7; offset++) {
      final candidate = today.add(Duration(days: offset));
      if (candidate.weekday == midweekDay ||
          candidate.weekday == weekendDay) {
        return candidate;
      }
    }
    // Fallback — should never be reached.
    return today;
  }

  static int _validWeekday(int value, int fallback) {
    if (value >= DateTime.monday && value <= DateTime.sunday) return value;
    return fallback;
  }

  static String _format(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
