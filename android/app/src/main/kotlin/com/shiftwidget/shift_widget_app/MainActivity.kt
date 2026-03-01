package com.shiftwidget.shift_widget_app

import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.state.PreferencesGlanceStateDefinition
import com.shiftwidget.shift_widget_app.widget.ShiftWidget
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "com.shiftwidget/widget_update"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "updateGlanceWidget") {
                    val shiftName = call.argument<String>("shiftName") ?: ""
                    val shiftTime = call.argument<String>("shiftTime") ?: ""
                    val shiftColor = call.argument<String>("shiftColor") ?: ""
                    CoroutineScope(Dispatchers.IO).launch {
                        val manager = GlanceAppWidgetManager(this@MainActivity)
                        val ids = manager.getGlanceIds(ShiftWidget::class.java)
                        ids.forEach { id ->
                            updateAppWidgetState(
                                this@MainActivity,
                                PreferencesGlanceStateDefinition,
                                id
                            ) { prefs ->
                                prefs.toMutablePreferences().apply {
                                    this[ShiftWidget.SHIFT_NAME_KEY] = shiftName
                                    this[ShiftWidget.SHIFT_TIME_KEY] = shiftTime
                                    this[ShiftWidget.SHIFT_COLOR_KEY] = shiftColor
                                }
                            }
                            ShiftWidget().update(this@MainActivity, id)
                        }
                        withContext(Dispatchers.Main) {
                            result.success(null)
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
