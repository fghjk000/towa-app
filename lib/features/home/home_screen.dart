import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/shift_type.dart';
import '../../core/providers/schedule_providers.dart';
import '../../core/services/shift_calculator.dart';
import 'widgets/today_shift_card.dart';
import 'widgets/week_preview.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(activeScheduleProvider);
    final shiftTypes = ref.watch(shiftTypesProvider);
    final today = DateTime.now();

    if (schedule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('교대근무')),
        body: const Center(child: Text('설정에서 일정을 추가해주세요')),
      );
    }

    final todayId = ShiftCalculator.getShiftTypeIdForDate(schedule, today);
    final todayShift = shiftTypes.where((t) => t.id == todayId).firstOrNull;

    // 이번 주 일요일부터 7일 데이터 계산
    final weekdayOffset = today.weekday % 7; // 일=0, 월=1 ... 토=6
    final weekStart = today.subtract(Duration(days: weekdayOffset));
    final weekData = <DateTime, ShiftType?>{};
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final id = ShiftCalculator.getShiftTypeIdForDate(schedule, day);
      weekData[day] = shiftTypes.where((t) => t.id == id).firstOrNull;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('yyyy년 M월 d일 EEEE', 'ko').format(today),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (todayShift != null)
              TodayShiftCard(shiftType: todayShift)
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('사이클 시작일 이전입니다'),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              '이번 주',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            WeekPreview(weekData: weekData),
          ],
        ),
      ),
    );
  }
}
