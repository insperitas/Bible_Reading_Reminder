/// The set of trackable activities in the app.
/// New activity types can be added here; the rest of the system adapts.
enum ActivityType {
  dailyText,
  bibleReading,
  meetingPrep;

  String get displayName => switch (this) {
        ActivityType.dailyText   => 'Daily Text',
        ActivityType.bibleReading => 'Bible Reading',
        ActivityType.meetingPrep  => 'Meeting Preparation',
      };

  String get description => switch (this) {
        ActivityType.dailyText =>
          'Open the daily text from jw.org each day.',
        ActivityType.bibleReading =>
          'Follow a structured Bible reading plan.',
        ActivityType.meetingPrep =>
          'Prepare for the midweek and weekend meetings.',
      };
}
