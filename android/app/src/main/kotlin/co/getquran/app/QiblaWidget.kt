package co.getquran.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Matrix
import android.graphics.drawable.BitmapDrawable
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import kotlin.math.roundToInt

class QiblaWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val degrees = prefs.getFloat("flutter.widget_qibla_degrees", Float.MIN_VALUE)
        val city    = prefs.getString("flutter.widget_city", "") ?: ""

        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.qibla_widget)

            if (degrees != Float.MIN_VALUE) {
                views.setTextViewText(R.id.qibla_degrees, "${degrees.roundToInt()}°")

                // Rotate the arrow drawable
                val drawable = ContextCompat.getDrawable(context, R.drawable.ic_widget_qibla)
                if (drawable != null) {
                    val bitmap = drawable.toBitmap(96, 96)
                    val matrix = Matrix().apply { postRotate(degrees, 48f, 48f) }
                    val rotated = android.graphics.Bitmap.createBitmap(
                        bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
                    )
                    views.setImageViewBitmap(R.id.qibla_arrow, rotated)
                }
            } else {
                views.setTextViewText(R.id.qibla_degrees, "Open app")
            }

            views.setTextViewText(R.id.qibla_city, city)
            views.setOnClickPendingIntent(R.id.qibla_degrees, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
