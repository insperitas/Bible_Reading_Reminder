package org.foss.biblereader.bible_reading_reminder

import android.content.Context

/**
 * Tracks which of the two flash-on / flash-off backgrounds is currently
 * shown in DEJECTED state. Toggled by FlashAlarmReceiver on each alarm.
 */
object FlashPhaseTracker {

    private const val PREFS = "elijah_flash_prefs"
    private const val KEY   = "flash_phase"

    /** Flip the phase and return the new value (true = flash-on / vivid). */
    fun toggle(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val next  = !prefs.getBoolean(KEY, false)
        prefs.edit().putBoolean(KEY, next).apply()
        return next
    }

    fun get(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY, false)

    fun reset(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY, false).apply()
}
