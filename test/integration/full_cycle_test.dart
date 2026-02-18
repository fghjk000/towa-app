import 'package:flutter_test/flutter_test.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';
import 'package:shift_widget_app/core/services/notification_service.dart';
import 'package:shift_widget_app/core/services/shift_calculator.dart';

void main() {
  group('전체 사이클 시나리오 — 주간2+야간2+휴무1+주간3+야간2 (10일)', () {
    // 주간2일 → 야간2일 → 휴무1일 → 주간3일 → 야간2일 (총 10일)
    final schedule = Schedule(
      id: 's1',
      name: '실제 패턴',
      cycleStartDate: DateTime(2024, 1, 1),
      cycleBlocks: [
        CycleBlock(shiftTypeId: 'day', days: 2),
        CycleBlock(shiftTypeId: 'night', days: 2),
        CycleBlock(shiftTypeId: 'off', days: 1),
        CycleBlock(shiftTypeId: 'day', days: 3),
        CycleBlock(shiftTypeId: 'night', days: 2),
      ],
    );

    test('totalDays는 10일', () {
      expect(schedule.totalDays, 10);
    });

    test('10일 주기 전체 날짜 검증', () {
      final expected = [
        'day',   // 1일 (1월 1일)
        'day',   // 2일
        'night', // 3일
        'night', // 4일
        'off',   // 5일
        'day',   // 6일
        'day',   // 7일
        'day',   // 8일
        'night', // 9일
        'night', // 10일
      ];
      for (var i = 0; i < 10; i++) {
        final date = DateTime(2024, 1, 1 + i);
        final result = ShiftCalculator.getShiftTypeIdForDate(schedule, date);
        expect(result, expected[i],
            reason: '${i + 1}번째 날(${date.month}/${date.day}) 실패');
      }
    });

    test('11번째 날은 사이클 반복 — day', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 11));
      expect(result, 'day');
    });

    test('20번째 날(2사이클 마지막)도 night', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 20));
      expect(result, 'night');
    });

    test('21번째 날(3사이클 시작)은 day', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 21));
      expect(result, 'day');
    });
  });

  group('ShiftType.defaults() 검증', () {
    test('주간 기본값 확인', () {
      final day = ShiftType.defaults().firstWhere((t) => t.id == 'day');
      expect(day.name, '주간');
      expect(day.startHour, 8);
      expect(day.endHour, 17);
      expect(day.isOff, false);
    });

    test('야간 기본값 확인', () {
      final night = ShiftType.defaults().firstWhere((t) => t.id == 'night');
      expect(night.name, '야간');
      expect(night.startHour, 22);
      expect(night.endHour, 6);
      expect(night.isOff, false);
    });

    test('휴무 기본값 확인', () {
      final off = ShiftType.defaults().firstWhere((t) => t.id == 'off');
      expect(off.isOff, true);
    });
  });

  group('NotificationService.calcNotifyTime 통합 검증', () {
    test('야간 22시 근무, 30분 전 알림은 21:30', () {
      final notify = NotificationService.calcNotifyTime(
        shiftHour: 22,
        shiftMinute: 0,
        minutesBefore: 30,
        baseDate: DateTime(2024, 1, 3), // 야간 근무 날
      );
      expect(notify, DateTime(2024, 1, 3, 21, 30));
    });

    test('주간 8시 근무, 15분 전 알림은 7:45', () {
      final notify = NotificationService.calcNotifyTime(
        shiftHour: 8,
        shiftMinute: 0,
        minutesBefore: 15,
        baseDate: DateTime(2024, 1, 1), // 주간 근무 날
      );
      expect(notify, DateTime(2024, 1, 1, 7, 45));
    });
  });

  group('엣지 케이스', () {
    test('단일 블록 사이클 (주간만) 무한 반복', () {
      final single = Schedule(
        id: 'single',
        name: '주간만',
        cycleStartDate: DateTime(2024, 1, 1),
        cycleBlocks: [CycleBlock(shiftTypeId: 'day', days: 1)],
      );
      // 365일 전부 day여야 함
      for (var i = 0; i < 365; i++) {
        final result = ShiftCalculator.getShiftTypeIdForDate(
            single, DateTime(2024, 1, 1).add(Duration(days: i)));
        expect(result, 'day', reason: '$i일째 실패');
      }
    });

    test('시작일 이전 날짜는 null', () {
      final schedule = Schedule(
        id: 'future',
        name: '미래',
        cycleStartDate: DateTime(2025, 1, 1),
        cycleBlocks: [CycleBlock(shiftTypeId: 'day', days: 1)],
      );
      expect(
        ShiftCalculator.getShiftTypeIdForDate(schedule, DateTime(2024, 12, 31)),
        null,
      );
    });
  });
}
