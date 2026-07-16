import 'package:home_widget/home_widget.dart';

/// Keys that match the shared-prefs keys read in BibleWidget.kt.
const _kVerseText = 'widget_verse_text';
const _kVerseRef  = 'widget_verse_ref';
const _kStreak    = 'widget_streak';

const _kAndroidWidgetName = 'org.foss.biblereader.bible_reading_reminder.BibleWidget';

/// Pushes [verse], [reference], and [streak] to the home screen widget via
/// the home_widget shared-preferences bridge, then requests a redraw.
Future<void> updateHomeWidget({
  required String verse,
  required String reference,
  required int streak,
}) async {
  await Future.wait([
    HomeWidget.saveWidgetData<String>(_kVerseText, verse),
    HomeWidget.saveWidgetData<String>(_kVerseRef,  reference),
    HomeWidget.saveWidgetData<int>(_kStreak,        streak),
  ]);
  await HomeWidget.updateWidget(androidName: _kAndroidWidgetName);
}
