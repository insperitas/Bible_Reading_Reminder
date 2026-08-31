# ── Flutter ────────────────────────────────────────────────────────────────
# Keep Flutter engine and plugin registrant.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter references Play Store deferred-component APIs that don't exist in
# FOSS/F-Droid builds. Suppress the missing-class errors — these code paths
# are never executed without Play Store.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**

# ── WorkManager workers ────────────────────────────────────────────────────
# WorkManager resolves worker classes by name at runtime; renaming them
# causes a ClassNotFoundException and a silent widget/crash failure.
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keep class * extends androidx.work.CoroutineWorker { *; }
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# ── App widget & broadcast receivers ──────────────────────────────────────
# These are in the manifest, so the linker should keep them, but be explicit.
-keep class org.foss.biblereader.bible_reading_reminder.BibleWidget { *; }
-keep class org.foss.biblereader.bible_reading_reminder.DailyWidgetRefreshWorker { *; }
-keep class org.foss.biblereader.bible_reading_reminder.ReadingActionReceiver { *; }
-keep class org.foss.biblereader.bible_reading_reminder.FlashAlarmReceiver { *; }
-keep class org.foss.biblereader.bible_reading_reminder.MainActivity { *; }

# ── home_widget plugin ─────────────────────────────────────────────────────
-keep class es.antonborri.home_widget.** { *; }

# ── WorkManager internals ──────────────────────────────────────────────────
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
