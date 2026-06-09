package com.timer.timer_overlay_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.widget.RemoteViews
import java.util.Calendar

class DayCounterWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            updateWidget(context, appWidgetManager, appWidgetId, options)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, newOptions)
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
                val options = appWidgetManager.getAppWidgetOptions(id)
                updateWidget(context, appWidgetManager, id, options)
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            options: Bundle? = null
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val countersJson = prefs.getString("counters", "[]") ?: "[]"
            var label: String
            var daysText: String

            val minW = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 250
            val fontSizeDays = (minW / 12).coerceIn(16, 48)
            val fontSizeLabel = (minW / 20).coerceIn(10, 20)

            var bgColorInt = 0xFF1C1C1E
            var textColorInt = 0xFFFFFFFF
            var opacity = 1.0

            try {
                val arr = org.json.JSONArray(countersJson)
                if (arr.length() > 0) {
                    val pinIdx = appWidgetId % arr.length()
                    val obj = arr.getJSONObject(pinIdx)
                    label = obj.optString("label", "\u0627\u0644\u0639\u0646\u0648\u0627\u0646")
                    bgColorInt = obj.optInt("bgColor", 0xFF1C1C1E)
                    textColorInt = obj.optInt("textColor", 0xFFFFFFFF)
                    opacity = obj.optDouble("opacity", 1.0)
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
                        daysText = if (days >= 0) "\u0645\u062A\u0628\u0642\u064A $absDays \u064A\u0648\u0645"
                                   else "\u0645\u0646\u0630 $absDays \u064A\u0648\u0645"
                    }
                } else {
                    label = "\u0644\u0627 \u064A\u0648\u062C\u062F \u0645\u0624\u0642\u062A\u0627\u062A"
                    daysText = "\u0623\u0636\u0641 \u0645\u0646 \u0627\u0644\u062A\u0637\u0628\u064A\u0642"
                }
            } catch (e: Exception) {
                label = "\u062E\u0637\u0623"
                daysText = "--"
            }

            val alpha = (opacity * 255).toInt().coerceIn(0, 255)
            val bgWithAlpha = (alpha shl 24) or (bgColorInt and 0x00FFFFFF)

            val views = RemoteViews(context.packageName, R.layout.day_counter_layout)
            views.setTextViewText(R.id.widget_label, label)
            views.setTextViewText(R.id.widget_days, daysText)
            views.setTextViewTextSize(R.id.widget_label, android.util.TypedValue.COMPLEX_UNIT_SP, fontSizeLabel.toFloat())
            views.setTextViewTextSize(R.id.widget_days, android.util.TypedValue.COMPLEX_UNIT_SP, fontSizeDays.toFloat())
            views.setInt(R.id.widget_root, "setBackgroundColor", bgWithAlpha)
            views.setTextColor(R.id.widget_label, textColorInt)
            views.setTextColor(R.id.widget_days, textColorInt)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
