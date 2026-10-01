package org.foss.biblereader.bible_reading_reminder

import java.util.Calendar

/**
 * Elijah's six emotional states, driven by time of day and whether the user
 * has read today's text. The beard direction is the primary mood indicator:
 *
 *   SATISFIED  — beard up-forward   (read today, at any hour)
 *   HAPPY      — beard forward      (before 9am, not read)
 *   NEUTRAL    — beard straight down (9am–noon, not read)
 *   CONCERNED  — beard down-forward (noon–3pm, not read)
 *   SAD        — beard drooping back (3pm–6pm, not read)
 *   DEJECTED   — beard surrendered  (6pm+, not read)
 */
enum class CharacterState {
    SATISFIED, HAPPY, NEUTRAL, CONCERNED, SAD, DEJECTED;

    val drawableRes: Int
        get() = when (this) {
            SATISFIED -> R.drawable.ic_elijah_satisfied
            HAPPY     -> R.drawable.ic_elijah_happy
            NEUTRAL   -> R.drawable.ic_elijah_neutral
            CONCERNED -> R.drawable.ic_elijah_concerned
            SAD       -> R.drawable.ic_elijah_sad
            DEJECTED  -> R.drawable.ic_elijah_dejected
        }

    val photoDrawableName: String
        get() = when (this) {
            SATISFIED -> "tree_photo_satisfied"
            HAPPY     -> "tree_photo_happy"
            NEUTRAL   -> "tree_photo_neutral"
            CONCERNED -> "tree_photo_concerned"
            SAD       -> "tree_photo_sad"
            DEJECTED  -> "tree_photo_dejected"
        }

    val photoDrawableFallbackNames: List<String>
        get() = when (this) {
            SATISFIED -> listOf("full_healthy", "single_tree_isoltaed")
            HAPPY     -> listOf("full_healthy", "single_tree_isoltaed")
            NEUTRAL   -> listOf("single_tree_isoltaed", "moody")
            CONCERNED -> listOf("moody", "autumn_tree")
            SAD       -> listOf("autumn_tree", "silhouette")
            DEJECTED  -> listOf("wilting", "silhouette")
        }

    fun backgroundDrawableRes(flashPhase: Boolean = false): Int = when (this) {
        SATISFIED -> R.drawable.widget_background_satisfied
        HAPPY     -> R.drawable.widget_background
        NEUTRAL   -> R.drawable.widget_background_neutral
        CONCERNED -> R.drawable.widget_background_concerned
        SAD       -> R.drawable.widget_background_sad
        DEJECTED  -> if (flashPhase) R.drawable.widget_background_flash
                     else            R.drawable.widget_background_dejected
    }

    companion object {
        fun current(hasReadToday: Boolean): CharacterState {
            if (hasReadToday) return SATISFIED
            return when (Calendar.getInstance().get(Calendar.HOUR_OF_DAY)) {
                in 0..8   -> HAPPY
                in 9..11  -> NEUTRAL
                in 12..14 -> CONCERNED
                in 15..17 -> SAD
                else      -> DEJECTED
            }
        }
    }
}
