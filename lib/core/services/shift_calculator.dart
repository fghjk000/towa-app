import '../models/date_override.dart';
import '../models/schedule.dart';

class ShiftCalculator {
  /// overrides가 주어지면 해당 날짜에 override가 있을 경우 우선 반환.
  static String? getShiftTypeIdForDate(
    Schedule schedule,
    DateTime date, {
    List<DateOverride> overrides = const [],
  }) {
    final target = DateTime(date.year, date.month, date.day);

    // 오버라이드 우선 확인
    final override = overrides
        .where((o) =>
            o.scheduleId == schedule.id &&
            o.date.year == target.year &&
            o.date.month == target.month &&
            o.date.day == target.day)
        .firstOrNull;
    if (override != null) return override.shiftTypeId;

    // 기존 사이클 계산
    final start = DateTime(
      schedule.cycleStartDate.year,
      schedule.cycleStartDate.month,
      schedule.cycleStartDate.day,
    );
    final dayIndex = target.difference(start).inDays;
    if (dayIndex < 0) return null;

    final totalDays = schedule.totalDays;
    if (totalDays == 0) return null;

    final positionInCycle = dayIndex % totalDays;
    int cursor = 0;
    for (final block in schedule.cycleBlocks) {
      cursor += block.days;
      if (positionInCycle < cursor) return block.shiftTypeId;
    }
    return null;
  }
}
