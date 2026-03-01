import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/date_override.dart';
import 'core/providers/schedule_providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/shift_calculator.dart';
import 'core/services/widget_sync_service.dart';

// 동시 syncAll 실행 방지 — 중복 알림 스케줄 경쟁 조건 예방
bool _isSyncing = false;
bool _pendingSync = false;

/// 앱 시작 또는 설정 변경 시 위젯 및 알림 동기화
Future<void> syncAll(WidgetRef ref) async {
  if (_isSyncing) {
    // 이미 실행 중이면 완료 후 한 번 더 실행하도록 표시
    _pendingSync = true;
    return;
  }
  _isSyncing = true;
  try {
    await _doSync(ref);
    // 실행 중 설정 변경이 있었다면 한 번 더 실행
    if (_pendingSync) {
      _pendingSync = false;
      await _doSync(ref);
    }
  } finally {
    _isSyncing = false;
    _pendingSync = false;
  }
}

Future<void> _doSync(WidgetRef ref) async {
  final schedule = ref.read(activeScheduleProvider);
  final shiftTypes = ref.read(shiftTypesProvider);
  final settings = ref.read(appSettingsProvider);
  final List<DateOverride> overrides =
      schedule != null ? ref.read(overridesProvider) : const [];

  final todayId = schedule != null
      ? ShiftCalculator.getShiftTypeIdForDate(
          schedule,
          DateTime.now(),
          overrides: overrides,
        )
      : null;
  final todayShift = shiftTypes.where((t) => t.id == todayId).firstOrNull;

  // 위젯 동기화 — 실패해도 알림 스케줄링은 계속
  try {
    await WidgetSyncService.updateWidget(
        todayShift, hasSchedule: schedule != null);
  } catch (_) {}

  // 알림 (설정 ON이고 일정이 있을 때만)
  try {
    if (settings.notificationEnabled && schedule != null) {
      await NotificationService.scheduleWeekNotifications(
        schedule: schedule,
        shiftTypes: shiftTypes,
        minutesBefore: settings.notificationMinutesBefore,
        overrides: overrides,
      );
    } else {
      await NotificationService.cancelAll();
    }
  } catch (_) {}
}
