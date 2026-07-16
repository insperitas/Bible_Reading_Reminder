package org.foss.biblereader.bible_reading_reminder

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * Drives the slow background flash in DEJECTED state.
 *
 * On each firing it toggles FlashPhaseTracker and redraws all widget
 * instances, then schedules itself again ~60 seconds later.
 *
 * Uses AlarmManager.set() (inexact, no special permission) with RTC_WAKEUP
 * so the widget updates even when the device screen is on and the user is
 * looking at the home screen. Battery impact is negligible at 1 fire/minute.
 *
 * The chain is started by BibleWidget when state = DEJECTED, and cancelled
 * by ReadingActionReceiver when the user taps Read.
 */
class FlashAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // Stop if state has changed (user read, or new day reset things)
        val state = CharacterState.current(ReadingTracker.hasReadToday(context))
        if (state != CharacterState.DEJECTED) return

        FlashPhaseTracker.toggle(context)

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, BibleWidget::class.java))
        for (id in ids) {
            BibleWidget.updateWidget(context, manager, id)
        }

        scheduleNext(context)
    }

    companion object {
        private const val FLASH_INTERVAL_MS = 60_000L  // ~60 s between colour changes
        private const val REQUEST_CODE = 9001

        private fun buildPendingIntent(context: Context, flags: Int): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                Intent(context, FlashAlarmReceiver::class.java),
                flags or PendingIntent.FLAG_IMMUTABLE,
            )

        fun scheduleNext(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.set(
                AlarmManager.RTC_WAKEUP,
                System.currentTimeMillis() + FLASH_INTERVAL_MS,
                buildPendingIntent(context, PendingIntent.FLAG_UPDATE_CURRENT),
            )
        }

        /** Starts the flash chain only if one isn't already pending. */
        fun scheduleIfNeeded(context: Context) {
            val existing = buildPendingIntent(context, PendingIntent.FLAG_NO_CREATE)
            if (existing == null) scheduleNext(context)
        }

        fun cancel(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(buildPendingIntent(context, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_UPDATE_CURRENT))
        }
    }
}
