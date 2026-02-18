import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/schedule.dart';
import '../models/shift_type.dart';
import 'shift_calculator.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 알림 시각 계산 (순수 함수 — 테스트 가능)
  static DateTime calcNotifyTime({
    required int shiftHour,
    required int shiftMinute,
    required int minutesBefore,
    required DateTime baseDate,
  }) {
    final shiftTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      shiftHour,
      shiftMinute,
    );
    return shiftTime.subtract(Duration(minutes: minutesBefore));
  }

  /// 앞으로 7일치 알림 스케줄링
  static Future<void> scheduleWeekNotifications({
    required Schedule schedule,
    required List<ShiftType> shiftTypes,
    required int minutesBefore,
  }) async {
    await _plugin.cancelAll();

    final today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = today.add(Duration(days: i));
      final id = ShiftCalculator.getShiftTypeIdForDate(schedule, day);
      final shift = shiftTypes.where((t) => t.id == id).firstOrNull;
      if (shift == null || shift.isOff) continue;

      final notifyAt = calcNotifyTime(
        shiftHour: shift.startHour,
        shiftMinute: shift.startMinute,
        minutesBefore: minutesBefore,
        baseDate: day,
      );

      if (notifyAt.isAfter(DateTime.now())) {
        await _plugin.zonedSchedule(
          i,
          '교대근무 알림',
          '${shift.name} 근무 $minutesBefore분 전입니다'
              ' (${shift.startHour.toString().padLeft(2, '0')}:'
              '${shift.startMinute.toString().padLeft(2, '0')})',
          tz.TZDateTime.from(notifyAt, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'shift_channel',
              '근무 알림',
              channelDescription: '근무 시작 전 알림',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Android 잠금화면 대체 — 오늘 근무 상시 알림
  static Future<void> showPersistentTodayNotification(
      ShiftType shift) async {
    final body = shift.isOff
        ? '휴무일입니다'
        : '${shift.name} '
            '${shift.startHour.toString().padLeft(2, '0')}:'
            '${shift.startMinute.toString().padLeft(2, '0')}'
            ' ~ '
            '${shift.endHour.toString().padLeft(2, '0')}:'
            '${shift.endMinute.toString().padLeft(2, '0')}';

    await _plugin.show(
      999,
      '오늘 근무',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'today_channel',
          '오늘 근무 현황',
          channelDescription: '잠금화면에 오늘 근무를 표시',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          showWhen: false,
        ),
      ),
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
