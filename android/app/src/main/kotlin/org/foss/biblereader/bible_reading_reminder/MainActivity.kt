package org.foss.biblereader.bible_reading_reminder

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Schedule the daily widget refresh task (no-op if already scheduled)
        DailyWidgetRefreshWorker.schedule(applicationContext)
    }
}
