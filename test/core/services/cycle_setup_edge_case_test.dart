import 'package:flutter_test/flutter_test.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';
import 'package:shift_widget_app/core/services/shift_calculator.dart';
import 'package:shift_widget_app/core/models/schedule.dart';

// _extractBlocks 로직을 직접 테스트하기 위해 추출한 순수 함수
List<CycleBlock> extractBlocks(
    Map<DateTime, String> paintedDays, List<ShiftType> shiftTypes) {
  if (paintedDays.isEmpty) return [];
  final sorted = paintedDays.keys.toList()..sort();
  final start = sorted.first;
  final end = sorted.last;

  // P3 Bug: shiftTypes가 비어있거나 isOff가 없을 때 안전하게 처리
  final offId = shiftTypes
          .where((t) => t.isOff)
          .map((t) => t.id)
          .firstOrNull ??
      (shiftTypes.isNotEmpty ? shiftTypes.first.id : 'off');

  final blocks = <CycleBlock>[];
  String? currentId;
  int count = 0;

  for (int i = 0; i <= end.difference(start).inDays; i++) {
    final d = start.add(Duration(days: i));
    final key = DateTime(d.year, d.month, d.day);
    final typeId = paintedDays[key] ?? offId;

    if (typeId == currentId) {
      count++;
    } else {
      if (currentId != null) {
        blocks.add(CycleBlock(shiftTypeId: currentId, days: count));
      }
      currentId = typeId;
      count = 1;
    }
  }
  if (currentId != null) {
    blocks.add(CycleBlock(shiftTypeId: currentId, days: count));
  }
  return blocks;
}

void main() {
  group('extractBlocks 엣지 케이스', () {
    // ─── P3 Bug: shiftTypes 빈 리스트일 때 크래시 방어 ──────────────────
    test('shiftTypes가 비어있어도 크래시 없이 동작한다', () {
      final paintedDays = {
        DateTime(2024, 1, 1): 'day',
        DateTime(2024, 1, 2): 'day',
      };
      // 빈 리스트여도 예외 없이 동작해야 함
      expect(
        () => extractBlocks(paintedDays, []),
        returnsNormally,
        reason: 'shiftTypes 빈 리스트에서 크래시가 없어야 함',
      );
    });

    test('isOff 유형이 없어도 첫 번째 유형으로 fallback된다', () {
      final shiftTypesNoOff = [
        ShiftType(
          id: 'day',
          name: '주간',
          startHour: 8,
          startMinute: 0,
          endHour: 17,
          endMinute: 0,
          colorValue: 0xFFFFEB3B,
        ),
      ];
      final paintedDays = {
        DateTime(2024, 1, 1): 'day',
        // 1월 3일은 공백 → fallback offId = 'day' (첫 번째 유형)
        DateTime(2024, 1, 3): 'day',
      };
      final blocks = extractBlocks(paintedDays, shiftTypesNoOff);
      expect(blocks.isNotEmpty, true);
      expect(blocks.every((b) => b.shiftTypeId.isNotEmpty), true);
    });

    test('페인트된 날짜가 없으면 빈 블록 리스트를 반환한다', () {
      final blocks = extractBlocks({}, ShiftType.defaults());
      expect(blocks.isEmpty, true);
    });
  });

  group('ShiftCalculator totalDays=0 방어', () {
    test('cycleBlocks가 비어있으면 null을 반환한다', () {
      final schedule = Schedule(
        id: 'empty',
        name: '빈',
        cycleStartDate: DateTime(2024, 1, 1),
        cycleBlocks: [],
      );
      expect(
        ShiftCalculator.getShiftTypeIdForDate(schedule, DateTime(2024, 1, 1)),
        null,
      );
    });
  });
}
