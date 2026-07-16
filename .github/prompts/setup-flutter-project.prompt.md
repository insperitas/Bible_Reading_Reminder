---
description: "Scaffold the Bible Reading Reminder Flutter project with FOSS-safe dependencies and home screen widget support"
---

Set up the Flutter project for **Bible Reading Reminder** at the workspace root.

## Steps

1. **Initialize Flutter project** (if not already done):
   ```
   flutter create --org org.foss.biblereader --platforms android bible_reading_reminder
   ```

2. **Add dependencies to `pubspec.yaml`** (FOSS-safe only):
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     home_widget: ^0.7.0          # Home screen widget bridge — no Google deps
     flutter_local_notifications: ^18.0.0  # Local reminders — no Firebase
     workmanager: ^0.5.0          # Background scheduling — AOSP WorkManager
     shared_preferences: ^2.0.0  # Lightweight local storage

   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^5.0.0
   ```

3. **Verify no proprietary Google dependencies** after `flutter pub get`:
   - Run `flutter pub deps` and confirm no `com.google.android.gms` entries
   - Flag any hit and suggest a replacement before continuing

4. **Create folder structure**:
   ```
   lib/
     features/
       widget/        # Home screen widget data + update logic
       reminders/     # Scheduling and notification logic
       reading/       # Bible content and reading plan
     shared/
       models/
       services/
   android/
     app/src/main/res/xml/   # Widget provider XML config
   ```

5. **Scaffold Android widget files**:
   - `android/.../BibleWidget.kt` — AppWidgetProvider subclass
   - `android/.../res/xml/bible_widget_info.xml` — widget metadata (size, update period)
   - `android/.../res/layout/bible_widget.xml` — RemoteViews layout (TextView for verse, streak)

6. **Confirm build passes**: run `flutter build apk --debug` and report any errors.
