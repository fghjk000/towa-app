import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io' show Platform;
import '../models/shift_type.dart';

class WidgetSyncService {
  static const _appGroupId = 'group.com.shiftwidget';
  static const _iOSWidgetName = 'ShiftWidget';
  static const _androidWidgetName = 'com.shiftwidget.widget.ShiftWidgetReceiver';

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget(ShiftType? shift) async {
    if (!_supported) return;
    await HomeWidget.saveWidgetData<String>(
        'shift_name', shift?.name ?? '휴무');
    await HomeWidget.saveWidgetData<String>(
        'shift_time',
        shift == null || shift.isOff
            ? ''
            : '${shift.startHour.toString().padLeft(2, '0')}:'
              '${shift.startMinute.toString().padLeft(2, '0')}'
              ' ~ '
              '${shift.endHour.toString().padLeft(2, '0')}:'
              '${shift.endMinute.toString().padLeft(2, '0')}');
    await HomeWidget.saveWidgetData<int>(
        'shift_color', shift?.colorValue ?? 0xFF9E9E9E);

    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
