import 'package:flutter_test/flutter_test.dart';
import 'package:shift_widget_app/core/services/notification_service.dart';

void main() {
  group('NotificationService.calcNotifyTime', () {
    test('오전 8시 근무, 30분 전 알림은 7시 30분', () {
      final result = NotificationService.calcNotifyTime(
        shiftHour: 8,
        shiftMinute: 0,
        minutesBefore: 30,
        baseDate: DateTime(2024, 1, 1),
      );
      expect(result, DateTime(2024, 1, 1, 7, 30));
    });

    test('야간 22시 근무, 60분 전 알림은 21시', () {
      final result = NotificationService.calcNotifyTime(
        shiftHour: 22,
        shiftMinute: 0,
        minutesBefore: 60,
        baseDate: DateTime(2024, 1, 1),
      );
      expect(result, DateTime(2024, 1, 1, 21, 0));
    });

    test('15분 알림 설정', () {
      final result = NotificationService.calcNotifyTime(
        shiftHour: 9,
        shiftMinute: 30,
        minutesBefore: 15,
        baseDate: DateTime(2024, 6, 15),
      );
      expect(result, DateTime(2024, 6, 15, 9, 15));
    });
  });
}
