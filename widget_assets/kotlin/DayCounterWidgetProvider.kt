package com.timer.timer_overlay_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.text.SimpleDateFormat
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
            val label: String
            val daysText: String

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
                        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                        val targetMs = sdf.parse(dateStr)?.time ?: 0L
                        val nowMs = System.currentTimeMillis()
                        val diffMs = targetMs - nowMs
                        val days = (diffMs / (1000L * 60 * 60 * 24)).toInt()
                        daysText = if (days >= 0) "$days day${if (days != 1) "s" else ""} left"
                                   else "${-days} day${if (days != -1) "s" else ""} ago"
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
