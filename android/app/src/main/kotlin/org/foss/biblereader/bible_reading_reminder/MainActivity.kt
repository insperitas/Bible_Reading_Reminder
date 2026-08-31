package org.foss.biblereader.bible_reading_reminder

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.foss.biblereader/daily_text"

    /**
     * Screen name passed from a widget button tap.
     * Consumed once by [getTargetScreen] so it only fires once per launch.
     */
    private var pendingScreen: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DailyWidgetRefreshWorker.schedule(applicationContext)
        pendingScreen = intent?.getStringExtra(BibleWidget.EXTRA_SCREEN)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Store the screen target so Flutter can consume it on next query.
        pendingScreen = intent.getStringExtra(BibleWidget.EXTRA_SCREEN)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDailyText" -> {
                    val urlDate = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())
                    val dailyTextUrl = "https://www.jw.org/finder" +
                        "?srcid=jwlshare&alias=daily-text&date=$urlDate&wtlocale=E"
                    val intent = Intent(ReadingActionReceiver.ACTION_READ_TAPPED).apply {
                        setPackage(this@MainActivity.packageName)
                        putExtra(ReadingActionReceiver.EXTRA_URL, dailyTextUrl)
                    }
                    applicationContext.sendBroadcast(intent)
                    result.success(null)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url == null) {
                        result.error("invalid-arg", "Missing url", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        applicationContext.startActivity(intent)
                        result.success(null)
                    } catch (ex: Exception) {
                        result.error("launch-failed", ex.message, null)
                    }
                }
                // Flutter calls this on resume to check if a widget button launched the app.
                // Returns the target screen name ("tree", "settings", "extra") or null.
                // Clears the value after returning so it fires at most once.
                "getTargetScreen" -> {
                    val screen = pendingScreen
                    pendingScreen = null
                    result.success(screen)
                }
                else -> result.notImplemented()
            }
        }
    }
}
