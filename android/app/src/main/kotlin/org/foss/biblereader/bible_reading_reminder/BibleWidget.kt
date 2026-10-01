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
open class BibleWidget : AppWidgetProvider() {

    protected open fun widgetLayoutRes(): Int = R.layout.bible_widget

    protected open fun compactMode(): Boolean = false

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val layoutRes = widgetLayoutRes()
        val compact = compactMode()
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id, layoutRes, compact)
        }
    }

    companion object {

        // ── Intent extras ──────────────────────────────────────────────
        const val EXTRA_SCREEN    = "extra_screen"
        const val SCREEN_TREE     = "tree"
        const val SCREEN_SETTINGS = "settings"
        const val SCREEN_EXTRA    = "extra"
        const val SCREEN_READING  = "reading"
        const val SCREEN_FEED     = "feed"

        // ── Date formatters ────────────────────────────────────────────
        private val DISPLAY_DATE_FORMAT = SimpleDateFormat("EEEE, d MMMM", Locale.getDefault())
        private const val TALL_THIN_HEIGHT_RATIO = 1.2

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            layoutRes: Int = R.layout.bible_widget,
            compactMode: Boolean = false,
        ) {
            val now         = Date()
            val displayDate = DISPLAY_DATE_FORMAT.format(now)
            val hasReadToday = ReadingTracker.hasReadToday(context)

            // ── Streak ─────────────────────────────────────────────────
            val streak = ReadingTracker.getStreak(context)

            // ── Background mood (still driven by reading state + time) ─
            val state      = CharacterState.current(hasReadToday)
            val flashPhase = state == CharacterState.DEJECTED && FlashPhaseTracker.get(context)

            // ── Build RemoteViews ──────────────────────────────────────
            val views = RemoteViews(context.packageName, layoutRes).apply {

                // Header
                setTextViewText(R.id.widget_date_label, displayDate)
                setInt(R.id.widget_root, "setBackgroundResource",
                    state.backgroundDrawableRes(flashPhase))
                val preferPoplar = isTallThinWidget(appWidgetManager, appWidgetId)
                setImageViewResource(
                    R.id.widget_tree_image,
                    resolveTreeImageRes(context, state, preferPoplar),
                )

                // Streak
                if (streak > 0) {
                    val days = if (streak == 1) "day" else "days"
                    setTextViewText(R.id.widget_streak, "🔥 $streak $days")
                    setViewVisibility(R.id.widget_streak, android.view.View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_streak, android.view.View.GONE)
                }

                // ── Water: open Daily Text ─────────────────────────────
                setOnClickPendingIntent(
                    R.id.widget_btn_water,
                    appIntent(context, appWidgetId, 1000, SCREEN_READING),
                )

                // ── Feed: open Bible Reading ────────────────────────────
                setOnClickPendingIntent(
                    R.id.widget_btn_feed,
                    appIntent(context, appWidgetId, 2000, SCREEN_FEED),
                )

                if (compactMode || !hasReadToday) {
                    setViewVisibility(R.id.widget_btn_feed, android.view.View.GONE)
                } else {
                    setViewVisibility(R.id.widget_btn_feed, android.view.View.VISIBLE)
                }
            }

            // Flash alarm management
            if (state == CharacterState.DEJECTED) FlashAlarmReceiver.scheduleIfNeeded(context)
            else FlashAlarmReceiver.cancel(context)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun resolveTreeImageRes(
            context: Context,
            state: CharacterState,
            preferPoplar: Boolean,
        ): Int {
            // Tall/thin widgets prefer poplar-style art.
            // Wider widgets prefer legacy named trees first so those assets are visible.
            val names = if (preferPoplar) {
                preferredPoplarTreeNames(state) + listOf(state.photoDrawableName) + state.photoDrawableFallbackNames
            } else {
                state.photoDrawableFallbackNames + listOf(state.photoDrawableName)
            }
            for (name in names) {
                val photoResId = context.resources.getIdentifier(
                    name,
                    "drawable",
                    context.packageName,
                )
                if (photoResId != 0) return photoResId
            }
            return state.drawableRes
        }

        private fun isTallThinWidget(
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ): Boolean {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            if (minWidthDp <= 0 || minHeightDp <= 0) return false
            return minHeightDp.toDouble() / minWidthDp.toDouble() >= TALL_THIN_HEIGHT_RATIO
        }

        private fun preferredPoplarTreeNames(state: CharacterState): List<String> = when (state) {
            CharacterState.SATISFIED,
            CharacterState.HAPPY,
            CharacterState.NEUTRAL -> listOf("poplar_version")
            CharacterState.CONCERNED,
            CharacterState.SAD,
            CharacterState.DEJECTED -> listOf("poplar_moody")
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
