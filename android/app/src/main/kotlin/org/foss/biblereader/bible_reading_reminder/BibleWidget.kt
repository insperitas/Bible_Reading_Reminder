package org.foss.biblereader.bible_reading_reminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * BibleWidget — home screen AppWidgetProvider.
 *
 * Shows Elijah, a J-profile mascot whose beard direction reflects how
 * urgently the user needs to read today's text. Tapping the CTA:
 *   → fires ReadingActionReceiver (marks today read, redraws Elijah as
 *     SATISFIED, then opens the jw.org daily text URL in the browser).
 *
 * A WorkManager job refreshes the widget hourly so Elijah's mood tracks
 * the time of day without the user needing to open the app.
 */
class BibleWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {

        private val URL_DATE_FORMAT     = SimpleDateFormat("yyyyMMdd", Locale.US)
        private val DISPLAY_DATE_FORMAT = SimpleDateFormat("EEEE, d MMMM", Locale.getDefault())

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val now         = Date()
            val urlDate     = URL_DATE_FORMAT.format(now)
            val displayDate = DISPLAY_DATE_FORMAT.format(now)

            val dailyTextUrl = "https://www.jw.org/finder" +
                "?srcid=jwlshare&alias=daily-text&date=$urlDate&wtlocale=E"

            // Broadcast intent → ReadingActionReceiver handles tap
            val tapIntent = Intent(ReadingActionReceiver.ACTION_READ_TAPPED).apply {
                setPackage(context.packageName)
                putExtra(ReadingActionReceiver.EXTRA_URL, dailyTextUrl)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                tapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val state      = CharacterState.current(ReadingTracker.hasReadToday(context))
            val flashPhase = if (state == CharacterState.DEJECTED) FlashPhaseTracker.get(context) else false
            val streak     = ReadingTracker.getStreak(context)

            val views = RemoteViews(context.packageName, R.layout.bible_widget).apply {
                setTextViewText(R.id.widget_date_label, displayDate)
                setOnClickPendingIntent(R.id.widget_read_button, pendingIntent)
                setImageViewResource(R.id.widget_character, state.drawableRes)
                setInt(R.id.widget_root, "setBackgroundResource", state.backgroundDrawableRes(flashPhase))

                if (streak > 0) {
                    val days = if (streak == 1) "day" else "days"
                    setTextViewText(R.id.widget_streak, "🔥 $streak $days")
                    setViewVisibility(R.id.widget_streak, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_streak, android.view.View.GONE)
                }
            }

            // Start or stop the slow background flash
            if (state == CharacterState.DEJECTED) {
                FlashAlarmReceiver.scheduleIfNeeded(context)
            } else {
                FlashAlarmReceiver.cancel(context)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
