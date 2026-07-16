package org.foss.biblereader.bible_reading_reminder

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Runs once per day to refresh the home screen widget so the date label and
 * tap URL roll over to the new day without the user opening the app.
 *
 * Scheduled with WorkManager (AOSP Jetpack, F-Droid safe — no Google Play
 * Services required at runtime).
 */
class DailyWidgetRefreshWorker(
    private val context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, BibleWidget::class.java)
        )
        for (id in widgetIds) {
            BibleWidget.updateWidget(context, appWidgetManager, id)
        }
        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "daily_widget_refresh"

        /**
         * Enqueues a periodic 24-hour refresh task. Safe to call on every app
         * start — KEEP_EXISTING prevents duplicate chains from being created.
         */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<DailyWidgetRefreshWorker>(
                repeatInterval = 1,
                repeatIntervalTimeUnit = TimeUnit.HOURS,
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
        }
    }
}
