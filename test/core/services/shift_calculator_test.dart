import 'package:flutter_test/flutter_test.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/core/services/shift_calculator.dart';

void main() {
  late Schedule schedule;

  setUp(() {
    // 사이클: 주간2일 → 야간2일 → 휴무1일 (총 5일)
    schedule = Schedule(
      id: 'test',
      name: '테스트',
      cycleStartDate: DateTime(2024, 1, 1),
      cycleBlocks: [
        CycleBlock(shiftTypeId: 'day', days: 2),
        CycleBlock(shiftTypeId: 'night', days: 2),
        CycleBlock(shiftTypeId: 'off', days: 1),
      ],
    );
  });

  group('ShiftCalculator.getShiftTypeIdForDate', () {
    test('시작일(0번째)은 첫 번째 블록 유형(day)', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 1));
      expect(result, 'day');
    });

    test('2번째 날도 첫 번째 블록 (주간 2일)', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 2));
      expect(result, 'day');
    });

    test('3번째 날은 두 번째 블록 (야간)', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 3));
      expect(result, 'night');
    });

    test('4번째 날도 야간', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 4));
      expect(result, 'night');
    });

    test('5번째 날은 휴무', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 5));
      expect(result, 'off');
    });

    test('6번째 날은 사이클 반복 — 주간(day)', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2024, 1, 6));
      expect(result, 'day');
    });

    test('시작일 이전 날짜는 null 반환', () {
      final result = ShiftCalculator.getShiftTypeIdForDate(
          schedule, DateTime(2023, 12, 31));
      expect(result, null);
    });

    test('cycleBlocks가 비어있으면 null 반환', () {
      final empty = Schedule(
        id: 'empty', name: '빈', cycleStartDate: DateTime(2024, 1, 1),
        cycleBlocks: [],
      );
      final result = ShiftCalculator.getShiftTypeIdForDate(
          empty, DateTime(2024, 1, 1));
      expect(result, null);
    });
  });
}
