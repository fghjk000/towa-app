package com.shiftwidget.shift_widget_app.widget

import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.action.actionStartActivity
import android.content.Context
import com.shiftwidget.shift_widget_app.MainActivity

class ShiftWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val shiftName = prefs.getString("flutter.shift_name", "로딩 중") ?: "로딩 중"
        val shiftTime = prefs.getString("flutter.shift_time", "") ?: ""

        provideContent {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(androidx.glance.color.ColorProvider(
                        androidx.compose.ui.graphics.Color.White
                    ))
                    .clickable(actionStartActivity<MainActivity>()),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    modifier = GlanceModifier.padding(12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = shiftName,
                        style = TextStyle(
                            fontWeight = FontWeight.Bold,
                            fontSize = 20.sp
                        )
                    )
                    if (shiftTime.isNotEmpty()) {
                        Text(
                            text = shiftTime,
                            style = TextStyle(fontSize = 12.sp)
                        )
                    }
                    Text(
                        text = "오늘",
                        style = TextStyle(
                            fontSize = 10.sp,
                            color = ColorProvider(
                                androidx.compose.ui.graphics.Color.Gray
                            )
                        )
                    )
                }
            }
        }
    }
}

class ShiftWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = ShiftWidget()
}
