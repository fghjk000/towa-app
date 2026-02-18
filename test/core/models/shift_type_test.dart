import 'package:flutter_test/flutter_test.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';

void main() {
  group('ShiftType', () {
    test('기본 필드가 올바르게 저장된다', () {
      final shift = ShiftType(
        id: 'day',
        name: '주간',
        startHour: 8,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        colorValue: 0xFFFFEB3B,
      );
      expect(shift.id, 'day');
      expect(shift.name, '주간');
      expect(shift.startHour, 8);
      expect(shift.endHour, 17);
    });

    test('isOff가 true이면 휴무임을 나타낸다', () {
      final off = ShiftType(
        id: 'off',
        name: '휴무',
        startHour: 0,
        startMinute: 0,
        endHour: 0,
        endMinute: 0,
        colorValue: 0xFF9E9E9E,
        isOff: true,
      );
      expect(off.isOff, true);
    });

    test('defaults()는 주간, 야간, 휴무 3개를 반환한다', () {
      final defaults = ShiftType.defaults();
      expect(defaults.length, 3);
      expect(defaults.any((t) => t.id == 'day'), true);
      expect(defaults.any((t) => t.id == 'night'), true);
      expect(defaults.any((t) => t.id == 'off'), true);
    });
  });
}
