import 'package:home_widget/home_widget.dart';

import '../tree/tree_state.dart';

/// Keys shared with BibleWidget.kt — must stay in sync with the Kotlin side.
const _kStreak       = 'widget_streak';
const _kLeafCount    = 'tree_leaf_count';
const _kFlowerCount  = 'tree_flower_count';

const _kAndroidWidgetName =
    'org.foss.biblereader.bible_reading_reminder.BibleWidget';

/// Pushes [treeState] and [streak] to the home screen widget via the
/// home_widget shared-preferences bridge, then requests a redraw.
Future<void> updateHomeWidget({
  required TreeState treeState,
  required int streak,
}) async {
  await Future.wait([
    HomeWidget.saveWidgetData<int>(_kLeafCount,   treeState.leafCount),
    HomeWidget.saveWidgetData<int>(_kFlowerCount, treeState.flowerCount),
    HomeWidget.saveWidgetData<int>(_kStreak,      streak),
  ]);
  await HomeWidget.updateWidget(androidName: _kAndroidWidgetName);
}
