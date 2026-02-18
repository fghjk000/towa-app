import '../models/schedule.dart';

class ShiftCalculator {
  /// 주어진 날짜에 해당하는 근무 유형 ID를 반환한다.
  /// 사이클 시작일 이전이면 null 반환.
  /// cycleBlocks가 비어있으면 null 반환.
  static String? getShiftTypeIdForDate(Schedule schedule, DateTime date) {
    final start = DateTime(
      schedule.cycleStartDate.year,
      schedule.cycleStartDate.month,
      schedule.cycleStartDate.day,
    );
    final target = DateTime(date.year, date.month, date.day);
    final dayIndex = target.difference(start).inDays;

    if (dayIndex < 0) return null;

    final totalDays = schedule.totalDays;
    if (totalDays == 0) return null;

    final positionInCycle = dayIndex % totalDays;

    int cursor = 0;
    for (final block in schedule.cycleBlocks) {
      cursor += block.days;
      if (positionInCycle < cursor) {
        return block.shiftTypeId;
      }
    }
    return null;
  }
}
