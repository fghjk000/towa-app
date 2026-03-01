package com.shiftwidget.shift_widget_app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.*
import androidx.glance.GlanceId
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.color.ColorProvider
import androidx.glance.layout.*
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.*
import com.shiftwidget.shift_widget_app.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ShiftWidget : GlanceAppWidget() {

    companion object {
        val SHIFT_NAME_KEY = stringPreferencesKey("shift_name")
        val SHIFT_TIME_KEY = stringPreferencesKey("shift_time")
        val SHIFT_COLOR_KEY = stringPreferencesKey("shift_color")

        private val SMALL  = DpSize(110.dp,  50.dp)  // 2×1
        private val MEDIUM = DpSize(110.dp, 110.dp)  // 2×2
        private val LARGE  = DpSize(220.dp, 110.dp)  // 4×2
    }

    override val stateDefinition: GlanceStateDefinition<*> = PreferencesGlanceStateDefinition

    override val sizeMode = SizeMode.Responsive(setOf(SMALL, MEDIUM, LARGE))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val launchIntent = Intent(context, MainActivity::class.java)
        provideContent {
            val prefs = currentState<Preferences>()
            val shiftName = prefs[SHIFT_NAME_KEY] ?: "로딩 중"
            val shiftTime = prefs[SHIFT_TIME_KEY] ?: ""

            val size = LocalSize.current
            val baseMod = GlanceModifier
                .fillMaxSize()
                .background(Color.Transparent)
                .clickable(actionStartActivity(launchIntent))

            val white = ColorProvider(day = Color.White, night = Color.White)
            val whiteSecondary = ColorProvider(
                day = Color.White.copy(alpha = 0.7f),
                night = Color.White.copy(alpha = 0.7f),
            )

            when {
                // 2×1: 이름 + 시간 한 줄
                size.height < 80.dp -> {
                    Row(
                        modifier = baseMod.padding(horizontal = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = shiftName,
                            style = TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 18.sp,
                                color = white,
                            )
                        )
                        if (shiftTime.isNotEmpty()) {
                            Text(
                                text = shiftTime,
                                style = TextStyle(
                                    fontSize = 13.sp,
                                    color = whiteSecondary,
                                ),
                                modifier = GlanceModifier.padding(start = 10.dp)
                            )
                        }
                    }
                }
                // 4×2: 좌측 이름 크게, 우측 시간
                size.width >= 200.dp -> {
                    Row(
                        modifier = baseMod.padding(horizontal = 20.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = shiftName,
                            style = TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 30.sp,
                                color = white,
                            ),
                            modifier = GlanceModifier.defaultWeight()
                        )
                        if (shiftTime.isNotEmpty()) {
                            Text(
                                text = shiftTime,
                                style = TextStyle(
                                    fontSize = 16.sp,
                                    color = whiteSecondary,
                                )
                            )
                        }
                    }
                }
                // 2×2: 가운데 정렬
                else -> {
                    Box(modifier = baseMod, contentAlignment = Alignment.Center) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = shiftName,
                                style = TextStyle(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 24.sp,
                                    color = white,
                                )
                            )
                            if (shiftTime.isNotEmpty()) {
                                Text(
                                    text = shiftTime,
                                    style = TextStyle(
                                        fontSize = 13.sp,
                                        color = whiteSecondary,
                                    ),
                                    modifier = GlanceModifier.padding(top = 4.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

class ShiftWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = ShiftWidget()

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        CoroutineScope(Dispatchers.IO).launch {
            GlanceAppWidgetManager(context)
                .getGlanceIds(ShiftWidget::class.java)
                .forEach { id -> glanceAppWidget.update(context, id) }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        CoroutineScope(Dispatchers.IO).launch {
            GlanceAppWidgetManager(context)
                .getGlanceIds(ShiftWidget::class.java)
                .forEach { id -> glanceAppWidget.update(context, id) }
        }
    }
}
