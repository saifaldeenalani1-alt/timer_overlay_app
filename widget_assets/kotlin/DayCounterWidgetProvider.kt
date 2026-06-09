package com.timer.timer_overlay_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.util.Calendar
import java.util.Locale

class DayCounterWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "day_counter_widget"

        fun saveAndUpdateAll(context: Context, countersJson: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString("counters", countersJson).apply()
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, DayCounterWidgetProvider::class.java)
            )
            for (id in ids) {
                updateWidget(context, appWidgetManager, id)
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val countersJson = prefs.getString("counters", "[]") ?: "[]"
            var label: String
            var daysText: String

            try {
                val arr = org.json.JSONArray(countersJson)
                if (arr.length() > 0) {
                    val pinIdx = appWidgetId % arr.length()
                    val obj = arr.getJSONObject(pinIdx)
                    label = obj.optString("label", "Counter")
                    val dateStr = obj.optString("targetDate", "")
                    if (dateStr.isEmpty()) {
                        daysText = "--"
                    } else {
                        val parts = dateStr.split("-")
                        val targetCal = Calendar.getInstance()
                        targetCal.set(parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt(), 0, 0, 0)
                        targetCal.set(Calendar.MILLISECOND, 0)
                        val nowCal = Calendar.getInstance()
                        nowCal.set(Calendar.HOUR_OF_DAY, 0)
                        nowCal.set(Calendar.MINUTE, 0)
                        nowCal.set(Calendar.SECOND, 0)
                        nowCal.set(Calendar.MILLISECOND, 0)
                        val diffMs = targetCal.timeInMillis - nowCal.timeInMillis
                        val days = (diffMs / (1000L * 60 * 60 * 24)).toInt()
                        val absDays = kotlin.math.abs(days)
                        val s = if (absDays != 1) "s" else ""
                        daysText = if (days >= 0) "$absDays day$s left"
                                   else "$absDays day$s ago"
                    }
                } else {
                    label = "No counters"
                    daysText = "Add in app"
                }
            } catch (e: Exception) {
                label = "Error"
                daysText = "--"
            }

            val views = RemoteViews(context.packageName, R.layout.day_counter_layout)
            views.setTextViewText(R.id.widget_label, label)
            views.setTextViewText(R.id.widget_days, daysText)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
