import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io' show Platform;
import '../models/shift_type.dart';

class WidgetSyncService {
  static const _appGroupId = 'group.com.shiftwidget';
  static const _iOSWidgetName = 'ShiftWidget';
  static const _channel = MethodChannel('com.shiftwidget/widget_update');

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget(ShiftType? shift,
      {required bool hasSchedule}) async {
    if (!_supported) return;
    final name = !hasSchedule ? '일정 없음' : (shift?.name ?? '휴무');
    final shiftTime = hasSchedule && shift != null && !shift.isOff
        ? '${shift.startHour.toString().padLeft(2, '0')}:'
          '${shift.startMinute.toString().padLeft(2, '0')}'
          ' ~ '
          '${shift.endHour.toString().padLeft(2, '0')}:'
          '${shift.endMinute.toString().padLeft(2, '0')}'
        : '';
    final colorStr =
        '#${(shift?.colorValue ?? 0xFF9E9E9E).toRadixString(16).padLeft(8, '0')}';

    await HomeWidget.saveWidgetData<String>('shift_name', name);
    await HomeWidget.saveWidgetData<String>('shift_time', shiftTime);
    await HomeWidget.saveWidgetData<String>('shift_color', colorStr);

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('updateGlanceWidget', {
          'shiftName': name,
          'shiftTime': shiftTime,
          'shiftColor': colorStr,
        });
      } catch (_) {
        // 위젯 없거나 채널 없음 — 무시
      }
    } else {
      await HomeWidget.updateWidget(iOSName: _iOSWidgetName);
    }
  }
}
