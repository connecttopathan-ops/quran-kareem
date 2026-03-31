package co.getquran.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import java.util.Calendar

// ── Shared helpers ────────────────────────────────────────────────────────────

private fun prefs(context: Context) =
    context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

private fun str(context: Context, key: String, default: String = "--") =
    prefs(context).getString("flutter.$key", default) ?: default

private fun launchIntent(context: Context): PendingIntent {
    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        ?: Intent(context, MainActivity::class.java)
    return PendingIntent.getActivity(
        context, 0, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
}

private data class PrayerData(
    val fajr: String,
    val dhuhr: String,
    val asr: String,
    val maghrib: String,
    val isha: String,
    val city: String,
    val hijri: String,
    val current: String,  // name of current/next prayer
)

private fun loadPrayerData(context: Context): PrayerData {
    return PrayerData(
        fajr    = str(context, "widget_fajr"),
        dhuhr   = str(context, "widget_dhuhr"),
        asr     = str(context, "widget_asr"),
        maghrib = str(context, "widget_maghrib"),
        isha    = str(context, "widget_isha"),
        city    = str(context, "widget_city", ""),
        hijri   = str(context, "widget_hijri", ""),
        current = str(context, "widget_next_prayer", ""),
    )
}

private val GOLD   = Color.parseColor("#C9A84C")
private val WHITE  = Color.parseColor("#F5ECD7")
private val DIM    = Color.parseColor("#9A8060")

// ── Small widget (2×1) ───────────────────────────────────────────────────────

class PrayerWidgetSmall : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = loadPrayerData(context)
        val nextTime = when (data.current) {
            "Fajr"    -> data.fajr
            "Dhuhr"   -> data.dhuhr
            "Asr"     -> data.asr
            "Maghrib" -> data.maghrib
            "Isha"    -> data.isha
            else      -> "--:--"
        }
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget_small)
            views.setTextViewText(R.id.next_prayer_name, data.current.ifEmpty { "Prayer" })
            views.setTextViewText(R.id.next_prayer_time, nextTime)
            views.setTextViewText(R.id.city_name, data.city)
            views.setOnClickPendingIntent(R.id.next_prayer_name, launchIntent(context))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ── Medium widget (4×2) ──────────────────────────────────────────────────────

class PrayerWidgetMedium : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = loadPrayerData(context)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget_medium)
            views.setTextViewText(R.id.city_name, data.city.ifEmpty { "Prayer Times" })
            views.setTextViewText(R.id.hijri_date, data.hijri)
            views.setTextViewText(R.id.time_fajr, data.fajr)
            views.setTextViewText(R.id.time_dhuhr, data.dhuhr)
            views.setTextViewText(R.id.time_asr, data.asr)
            views.setTextViewText(R.id.time_maghrib, data.maghrib)
            views.setTextViewText(R.id.time_isha, data.isha)

            // Highlight current prayer label in gold
            val prayers = listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
            val lblIds  = listOf(R.id.lbl_fajr, R.id.lbl_dhuhr, R.id.lbl_asr, R.id.lbl_maghrib, R.id.lbl_isha)
            val timeIds = listOf(R.id.time_fajr, R.id.time_dhuhr, R.id.time_asr, R.id.time_maghrib, R.id.time_isha)
            for (i in prayers.indices) {
                val isCurrent = prayers[i] == data.current
                views.setTextColor(lblIds[i],  if (isCurrent) GOLD  else DIM)
                views.setTextColor(timeIds[i], if (isCurrent) GOLD  else WHITE)
            }
            views.setOnClickPendingIntent(R.id.city_name, launchIntent(context))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

// ── Large widget (4×3) ───────────────────────────────────────────────────────

class PrayerWidgetLarge : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val data = loadPrayerData(context)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget_large)
            views.setTextViewText(R.id.city_name, data.city.ifEmpty { "Prayer Times" })
            views.setTextViewText(R.id.hijri_date, data.hijri)
            views.setTextViewText(R.id.next_prayer_name, data.current)
            views.setTextViewText(R.id.time_fajr, data.fajr)
            views.setTextViewText(R.id.time_dhuhr, data.dhuhr)
            views.setTextViewText(R.id.time_asr, data.asr)
            views.setTextViewText(R.id.time_maghrib, data.maghrib)
            views.setTextViewText(R.id.time_isha, data.isha)

            val prayers = listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
            val lblIds  = listOf(R.id.lbl_fajr, R.id.lbl_dhuhr, R.id.lbl_asr, R.id.lbl_maghrib, R.id.lbl_isha)
            val timeIds = listOf(R.id.time_fajr, R.id.time_dhuhr, R.id.time_asr, R.id.time_maghrib, R.id.time_isha)
            for (i in prayers.indices) {
                val isCurrent = prayers[i] == data.current
                views.setTextColor(lblIds[i],  if (isCurrent) GOLD  else DIM)
                views.setTextColor(timeIds[i], if (isCurrent) GOLD  else WHITE)
            }
            views.setOnClickPendingIntent(R.id.city_name, launchIntent(context))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
