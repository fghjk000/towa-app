import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/date_override.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';
import 'package:shift_widget_app/core/providers/schedule_providers.dart';
import 'package:shift_widget_app/core/repositories/override_repository.dart';
import 'package:shift_widget_app/core/repositories/shift_type_repository.dart';
import 'package:shift_widget_app/features/home/home_screen.dart';

class _FakeShiftTypeRepository implements ShiftTypeRepository {
  final List<ShiftType> _items = ShiftType.defaults();

  @override
  Future<void> init() async {}

  @override
  List<ShiftType> getAll() => _items;

  @override
  Future<void> save(ShiftType type) async {
    final idx = _items.indexWhere((t) => t.id == type.id);
    if (idx >= 0) {
      _items[idx] = type;
    } else {
      _items.add(type);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((t) => t.id == id);
  }
}

class _FakeOverrideRepository implements OverrideRepository {
  final List<DateOverride> _items;
  _FakeOverrideRepository(this._items);

  @override
  Future<void> init() async {}

  @override
  List<DateOverride> getForSchedule(String scheduleId) =>
      _items.where((o) => o.scheduleId == scheduleId).toList();

  @override
  Future<void> save(DateOverride override) async {
    _items.removeWhere((o) =>
        o.scheduleId == override.scheduleId &&
        o.date.year == override.date.year &&
        o.date.month == override.date.month &&
        o.date.day == override.date.day);
    _items.add(override);
  }

  @override
  Future<void> delete(String scheduleId, DateTime date) async {
    _items.removeWhere((o) =>
        o.scheduleId == scheduleId &&
        o.date.year == date.year &&
        o.date.month == date.month &&
        o.date.day == date.day);
  }

  @override
  Future<void> deleteAllForSchedule(String scheduleId) async {
    _items.removeWhere((o) => o.scheduleId == scheduleId);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko', null);
  });

  testWidgets('일정이 없으면 안내 문구가 표시된다', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeScheduleProvider.overrideWithValue(null),
        shiftTypesProvider.overrideWith((_) => ShiftTypesNotifier(_FakeShiftTypeRepository())),
        overridesProvider.overrideWith(
          (ref) => OverridesNotifier(_FakeOverrideRepository([]), null),
        ),
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
        shiftTypesProvider.overrideWith((_) => ShiftTypesNotifier(_FakeShiftTypeRepository())),
        overridesProvider.overrideWith(
          (ref) => OverridesNotifier(_FakeOverrideRepository([]), schedule.id),
        ),
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
        shiftTypesProvider.overrideWith((_) => ShiftTypesNotifier(_FakeShiftTypeRepository())),
        overridesProvider.overrideWith(
          (ref) => OverridesNotifier(_FakeOverrideRepository([]), schedule.id),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));

    expect(find.text('휴무'), findsOneWidget);
  });

  // ─── P1 Bug #1: DateOverride 미반영 검증 ───────────────────────────────
  testWidgets('캘린더 수동 변경(DateOverride)이 홈 화면 오늘 카드에 반영된다', (tester) async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    const scheduleId = 's_override_test';

    final schedule = Schedule(
      id: scheduleId,
      name: '직장',
      cycleStartDate: todayNorm,
      // 사이클 기본은 주간(day)
      cycleBlocks: [CycleBlock(shiftTypeId: 'day', days: 1)],
    );

    // 오늘을 야간으로 수동 변경
    final override = DateOverride(
      scheduleId: scheduleId,
      date: todayNorm,
      shiftTypeId: 'night',
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        activeScheduleProvider.overrideWithValue(schedule),
        shiftTypesProvider.overrideWith((_) => ShiftTypesNotifier(_FakeShiftTypeRepository())),
        overridesProvider.overrideWith(
          (ref) => OverridesNotifier(_FakeOverrideRepository([override]), scheduleId),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ));

    // 사이클 기본값(주간)이 아닌 수동 변경된 야간이 표시돼야 함
    expect(find.text('야간'), findsOneWidget);
    expect(find.text('주간'), findsNothing);
  });
}
