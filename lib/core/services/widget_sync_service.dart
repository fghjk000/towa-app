import 'package:home_widget/home_widget.dart';
import '../models/shift_type.dart';

class WidgetSyncService {
  static const _appGroupId = 'group.com.shiftwidget';
  static const _iOSWidgetName = 'ShiftWidget';
  static const _androidWidgetName = 'com.shiftwidget.widget.ShiftWidgetReceiver';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget(ShiftType? shift) async {
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
