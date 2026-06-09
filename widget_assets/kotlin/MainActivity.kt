package com.timer.timer_overlay_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.timer.timer_overlay_app/widget"
        ).setMethodCallHandler { call, result ->
            if (call.method == "updateDayCounterWidget") {
                val countersJson = call.argument<String>("counters") ?: "[]"
                DayCounterWidgetProvider.saveAndUpdateAll(this, countersJson)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
