package org.foss.biblereader.bible_reading_reminder

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Persists the date the user last tapped "Read Today's Text" and the
 * resulting consecutive-day streak count.
 */
object ReadingTracker {

    private const val PREFS_FILE    = "elijah_reading_tracker"
    private const val KEY_LAST_READ = "last_read_date"
    private const val KEY_STREAK    = "streak_count"
    private val DATE_FORMAT = SimpleDateFormat("yyyy-MM-dd", Locale.US)

    /** Call when the user taps the "Read" button. */
    fun markReadToday(context: Context) {
        val prefs    = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        val today    = DATE_FORMAT.format(Date())
        val lastRead = prefs.getString(KEY_LAST_READ, null)

        // Guard: already marked today — nothing to do
        if (lastRead == today) return

        val yesterday = Calendar.getInstance()
            .apply { add(Calendar.DAY_OF_YEAR, -1) }
            .let { DATE_FORMAT.format(it.time) }

        val current   = prefs.getInt(KEY_STREAK, 0)
        val newStreak = if (lastRead == yesterday) current + 1 else 1

        prefs.edit()
            .putString(KEY_LAST_READ, today)
            .putInt(KEY_STREAK, newStreak)
            .apply()
    }

    /** Returns true if the user has already tapped Read today. */
    fun hasReadToday(context: Context): Boolean {
        val stored = context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
            .getString(KEY_LAST_READ, null) ?: return false
        return stored == DATE_FORMAT.format(Date())
    }

    /** Current consecutive-day streak (0 = never read). */
    fun getStreak(context: Context): Int =
        context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
            .getInt(KEY_STREAK, 0)
}
