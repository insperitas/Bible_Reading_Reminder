package org.foss.biblereader.bible_reading_reminder

/**
 * Widget provider variant used for the 1x5 preset.
 * Inherits all behavior from [BibleWidget].
 */
class BibleWidgetTall1x5 : BibleWidget() {
    override fun widgetLayoutRes(): Int = R.layout.bible_widget_narrow

    override fun compactMode(): Boolean = true
}
