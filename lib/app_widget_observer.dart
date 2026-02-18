import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/schedule_providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/shift_calculator.dart';
import 'core/services/widget_sync_service.dart';

/// 앱 시작 또는 설정 변경 시 위젯 및 알림 동기화
Future<void> syncAll(WidgetRef ref) async {
  final schedule = ref.read(activeScheduleProvider);
  final shiftTypes = ref.read(shiftTypesProvider);
  final settings = ref.read(appSettingsProvider);

  final todayId = schedule != null
      ? ShiftCalculator.getShiftTypeIdForDate(schedule, DateTime.now())
      : null;
  final todayShift = shiftTypes.where((t) => t.id == todayId).firstOrNull;

  // 위젯 동기화
  await WidgetSyncService.updateWidget(todayShift);

  // 알림 (설정 ON이고 일정이 있을 때만)
  if (settings.notificationEnabled && schedule != null) {
    await NotificationService.scheduleWeekNotifications(
      schedule: schedule,
      shiftTypes: shiftTypes,
      minutesBefore: settings.notificationMinutesBefore,
    );
    if (todayShift != null) {
      await NotificationService.showPersistentTodayNotification(todayShift);
    }
  } else {
    await NotificationService.cancelAll();
  }
}
