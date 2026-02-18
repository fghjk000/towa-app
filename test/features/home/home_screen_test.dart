import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/core/providers/schedule_providers.dart';
import 'package:shift_widget_app/features/home/home_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko', null);
  });

  testWidgets('일정이 없으면 안내 문구가 표시된다', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeScheduleProvider.overrideWithValue(null),
        shiftTypesProvider.overrideWith((_) => ShiftTypesNotifier()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));
    expect(find.text('설정에서 일정을 추가해주세요'), findsOneWidget);
  });

  testWidgets('오늘 근무 카드에 근무 이름이 표시된다', (tester) async {
    final today = DateTime.now();
    final schedule = Schedule(
      id: 's1',
      name: '직장A',
      cycleStartDate: today,
      cycleBlocks: [CycleBlock(shiftTypeId: 'day', days: 1)],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeScheduleProvider.overrideWithValue(schedule),
        shiftTypesProvider.overrideWith((_) => ShiftTypesNotifier()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));

    expect(find.text('주간'), findsOneWidget);
  });

  testWidgets('휴무일에는 시간이 표시되지 않는다', (tester) async {
    final today = DateTime.now();
    final schedule = Schedule(
      id: 's2',
      name: '직장B',
      cycleStartDate: today,
      cycleBlocks: [CycleBlock(shiftTypeId: 'off', days: 1)],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeScheduleProvider.overrideWithValue(schedule),
        shiftTypesProvider.overrideWith((_) => ShiftTypesNotifier()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));

    expect(find.text('휴무'), findsOneWidget);
  });
}
