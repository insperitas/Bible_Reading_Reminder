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
 * Layout: date + tree stats in the header; four action buttons below.
 *   [Daily Text]  — opens jw.org daily text in the browser
 *   [My Tree]     — opens the app to the tree / dashboard screen
 *   [Settings]    — opens the app to the settings screen
 *   [+ Extra]     — opens the app and signals an extra-activity reward
 *
 * Tree stats (leaf count and flower count) are read from HomeWidgetPreferences,
 * which Flutter keeps in sync via the home_widget package.
 */
class BibleWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) updateWidget(context, appWidgetManager, id)
    }

    companion object {

        // ── Intent extras ──────────────────────────────────────────────
        const val EXTRA_SCREEN   = "extra_screen"
        const val SCREEN_TREE    = "tree"
        const val SCREEN_SETTINGS = "settings"
        const val SCREEN_EXTRA   = "extra"

        // ── Date formatters ────────────────────────────────────────────
        private val URL_DATE_FORMAT     = SimpleDateFormat("yyyyMMdd",       Locale.US)
        private val DISPLAY_DATE_FORMAT = SimpleDateFormat("EEEE, d MMMM",   Locale.getDefault())

        // HomeWidgetPreferences keys (must match widget_updater.dart)
        private const val HW_PREFS      = "HomeWidgetPreferences"
        private const val KEY_LEAVES    = "tree_leaf_count"
        private const val KEY_FLOWERS   = "tree_flower_count"
        private const val MAX_LEAVES    = 20
        private const val MAX_FLOWERS   = 20

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val now         = Date()
            val displayDate = DISPLAY_DATE_FORMAT.format(now)
            val urlDate     = URL_DATE_FORMAT.format(now)
            val dailyTextUrl = "https://www.jw.org/finder" +
                "?srcid=jwlshare&alias=daily-text&date=$urlDate&wtlocale=E"

            // ── Read tree stats from HomeWidgetPreferences ─────────────
            val hwPrefs     = context.getSharedPreferences(HW_PREFS, Context.MODE_PRIVATE)
            val leafCount   = hwPrefs.getInt(KEY_LEAVES,  MAX_LEAVES)
            val flowerCount = hwPrefs.getInt(KEY_FLOWERS, 0)

            // ── Streak ─────────────────────────────────────────────────
            val streak = ReadingTracker.getStreak(context)

            // ── Background mood (still driven by reading state + time) ─
            val state      = CharacterState.current(ReadingTracker.hasReadToday(context))
            val flashPhase = state == CharacterState.DEJECTED && FlashPhaseTracker.get(context)

            // ── Build RemoteViews ──────────────────────────────────────
            val views = RemoteViews(context.packageName, R.layout.bible_widget).apply {

                // Header
                setTextViewText(R.id.widget_date_label, displayDate)
                setTextViewText(R.id.widget_leaf_count,   "🌿 $leafCount/$MAX_LEAVES")
                setTextViewText(R.id.widget_flower_count, "🌸 $flowerCount/$MAX_FLOWERS")
                setInt(R.id.widget_root, "setBackgroundResource",
                    state.backgroundDrawableRes(flashPhase))

                // Streak
                if (streak > 0) {
                    val days = if (streak == 1) "day" else "days"
                    setTextViewText(R.id.widget_streak, "🔥 $streak $days")
                    setViewVisibility(R.id.widget_streak, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_streak, android.view.View.GONE)
                }

                // ── Button 1: Daily Text — broadcast opens URL ─────────
                val dailyTextIntent = Intent(ReadingActionReceiver.ACTION_READ_TAPPED).apply {
                    setPackage(context.packageName)
                    putExtra(ReadingActionReceiver.EXTRA_URL, dailyTextUrl)
                }
                setOnClickPendingIntent(
                    R.id.widget_btn_daily_text,
                    PendingIntent.getBroadcast(
                        context, 1000 + appWidgetId, dailyTextIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    ),
                )

                // ── Button 2: My Tree — open app ──────────────────────
                setOnClickPendingIntent(
                    R.id.widget_btn_tree,
                    appIntent(context, appWidgetId, 2000, SCREEN_TREE),
                )

                // ── Button 3: Settings — open app ─────────────────────
                setOnClickPendingIntent(
                    R.id.widget_btn_settings,
                    appIntent(context, appWidgetId, 3000, SCREEN_SETTINGS),
                )

                // ── Button 4: + Extra — open app, signal flower award ──
                setOnClickPendingIntent(
                    R.id.widget_btn_extra,
                    appIntent(context, appWidgetId, 4000, SCREEN_EXTRA),
                )
            }

            // Flash alarm management
            if (state == CharacterState.DEJECTED) FlashAlarmReceiver.scheduleIfNeeded(context)
            else FlashAlarmReceiver.cancel(context)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /** Builds a [PendingIntent] that starts [MainActivity] with [screen] as an extra. */
        private fun appIntent(
            context: Context,
            appWidgetId: Int,
            baseRequestCode: Int,
            screen: String,
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_SCREEN, screen)
            }
            return PendingIntent.getActivity(
                context,
                baseRequestCode + appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
