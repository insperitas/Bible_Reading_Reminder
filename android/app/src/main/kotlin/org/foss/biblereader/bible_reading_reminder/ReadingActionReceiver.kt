package org.foss.biblereader.bible_reading_reminder

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri

/**
 * Handles the widget "Read Today's Text" tap:
 *   1. Records today as read so Elijah immediately becomes SATISFIED.
 *   2. Redraws all widget instances to reflect the new state.
 *   3. Opens the daily text URL in the browser / JW Library app.
 */
class ReadingActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_READ_TAPPED) return

        // 1 — Mark today as read and stop any pending flash alarm
        ReadingTracker.markReadToday(context)
        FlashAlarmReceiver.cancel(context)
        FlashPhaseTracker.reset(context)

        // 2 — Redraw every widget instance (Elijah turns SATISFIED)
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, BibleWidget::class.java)
        )
        for (id in ids) {
            BibleWidget.updateWidget(context, manager, id)
        }

        // 3 — Open the daily text URL
        val url = intent.getStringExtra(EXTRA_URL) ?: return
        context.startActivity(
            Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        )
    }

    companion object {
        const val ACTION_READ_TAPPED = "org.foss.biblereader.ACTION_READ_TAPPED"
        const val EXTRA_URL          = "extra_url"
    }
}
