package co.getquran.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "co.getquran.app/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidgets") {
                    updateAllWidgets()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun updateAllWidgets() {
        val mgr = AppWidgetManager.getInstance(this)
        listOf(
            PrayerWidgetSmall::class.java,
            PrayerWidgetMedium::class.java,
            PrayerWidgetLarge::class.java,
            QiblaWidget::class.java,
        ).forEach { cls ->
            val ids = mgr.getAppWidgetIds(ComponentName(this, cls))
            if (ids.isNotEmpty()) {
                val intent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    component = ComponentName(this@MainActivity, cls)
                }
                sendBroadcast(intent)
            }
        }
    }
}
