import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import '../models/date_override.dart';
import '../models/schedule.dart';
import '../models/shift_type.dart';
import 'shift_calculator.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_supported) return;
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // 포그라운드에서도 알림 표시
    const iOS = DarwinInitializationSettings(
      defaultPresentAlert: true,   // iOS 13 이하 호환
      defaultPresentBanner: true,  // iOS 14+ 배너 표시
      defaultPresentList: true,    // iOS 14+ 알림 센터에 추가
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
      // iOS 포그라운드 알림 표시를 위해 콜백 등록 필수
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );
    _initialized = true;
  }

  /// 권한 요청 — true: 허용됨, false: 거부됨
  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    bool granted = false;
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      granted = result ?? false;
    } else if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // Android 13+: 알림 권한 요청
      final notifGranted = await android?.requestNotificationsPermission();
      // Android 12+: 정확한 알람 권한 요청 (설정 화면으로 이동)
      await android?.requestExactAlarmsPermission();
      granted = notifGranted ?? false;
    }
    return granted;
  }

  /// 현재 알림 권한 상태 확인
  static Future<bool> checkPermission() async {
    if (!_supported) return false;
    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await impl?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.areNotificationsEnabled() ?? false;
    }
    return true;
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

  /// 앞으로 60일치 알림 스케줄링 (iOS 최대 64개 제한 내)
  /// overrides: DateOverride 목록 (특근/예외 날짜 반영)
  static Future<void> scheduleWeekNotifications({
    required Schedule schedule,
    required List<ShiftType> shiftTypes,
    required int minutesBefore,
    List<DateOverride> overrides = const [],
  }) async {
    if (!_supported) return;

    // Android: 정확한 알람 권한 확인 — 없으면 스케줄링 건너뜀
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      if (!canExact) return;
    }

    try {
      await _plugin.cancelAll();

      final today = DateTime.now();

      for (var i = 0; i < 60; i++) {
        final day = today.add(Duration(days: i));
        // DateOverride 반영하여 해당 날의 근무 유형 조회
        final id = ShiftCalculator.getShiftTypeIdForDate(
          schedule,
          day,
          overrides: overrides,
        );
        final shift = shiftTypes.where((t) => t.id == id).firstOrNull;
        if (shift == null || shift.isOff) continue;

        final notifyAt = calcNotifyTime(
          shiftHour: shift.startHour,
          shiftMinute: shift.startMinute,
          minutesBefore: minutesBefore,
          baseDate: day,
        );

        if (notifyAt.isAfter(DateTime.now())) {
          // millisecondsSinceEpoch 기반: 시간대 설정 없이 정확한 절대 시각 사용
          final tzNotifyAt = tz.TZDateTime.fromMillisecondsSinceEpoch(
            tz.UTC,
            notifyAt.millisecondsSinceEpoch,
          );
          await _plugin.zonedSchedule(
            i, // 날짜 인덱스 기반 ID (0~59)
            '알림',
            '${shift.name} 근무 $minutesBefore분 전입니다'
                ' (${shift.startHour.toString().padLeft(2, '0')}:'
                '${shift.startMinute.toString().padLeft(2, '0')})',
            tzNotifyAt,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'shift_channel',
                '근무 알림',
                channelDescription: '근무 시작 전 알림',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,   // iOS 13 이하 호환
                presentBanner: true,  // iOS 14+ 배너 표시
                presentList: true,    // iOS 14+ 알림 센터에 추가
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } on PlatformException {
      // 권한 문제 등 플랫폼 예외는 무시 — 알림 없이 앱 동작 계속
    }
  }

  /// 즉시 테스트 알림 — 권한 및 알림 동작 확인용
  static Future<void> sendTestNotification() async {
    if (!_supported) return;
    await _plugin.show(
      100,
      '알림 테스트',
      '알림이 정상적으로 동작하고 있습니다',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,   // iOS 13 이하 호환
          presentBanner: true,  // iOS 14+ 배너 표시
          presentList: true,    // iOS 14+ 알림 센터에 추가
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'shift_channel',
          '근무 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> cancelAll() async {
    if (!_supported) return;
    await _plugin.cancelAll();
  }
}
