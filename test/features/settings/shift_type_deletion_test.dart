import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_widget_app/core/models/app_settings.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/date_override.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';
import 'package:shift_widget_app/core/providers/schedule_providers.dart';
import 'package:shift_widget_app/core/repositories/override_repository.dart';
import 'package:shift_widget_app/core/repositories/schedule_repository.dart';
import 'package:shift_widget_app/core/repositories/settings_repository.dart';
import 'package:shift_widget_app/core/repositories/shift_type_repository.dart';
import 'package:shift_widget_app/features/settings/settings_screen.dart';

// ─── Fake Repositories ────────────────────────────────────────────────────────

class _FakeScheduleRepository implements ScheduleRepository {
  final List<Schedule> _items;
  _FakeScheduleRepository(List<Schedule> items) : _items = List.of(items);

  @override Future<void> init() async {}
  @override List<Schedule> getAll() => List.unmodifiable(_items);
  @override Schedule? getById(String id) =>
      _items.where((s) => s.id == id).firstOrNull;
  @override Future<void> save(Schedule schedule) async {}
  @override Future<void> delete(String id) async {
    _items.removeWhere((s) => s.id == id);
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _current;
  _FakeSettingsRepository(this._current);
  @override Future<void> init() async {}
  @override AppSettings get settings => _current;
  @override Future<void> save(AppSettings s) async { _current = s; }
}

class _FakeShiftTypeRepository implements ShiftTypeRepository {
  final List<ShiftType> _items;
  _FakeShiftTypeRepository(List<ShiftType> items) : _items = List.of(items);
  @override Future<void> init() async {}
  @override List<ShiftType> getAll() => List.unmodifiable(_items);
  @override Future<void> save(ShiftType type) async {}
  @override Future<void> delete(String id) async {
    _items.removeWhere((t) => t.id == id);
  }
}

class _FakeOverrideRepository implements OverrideRepository {
  @override Future<void> init() async {}
  @override List<DateOverride> getForSchedule(String id) => [];
  @override Future<void> save(DateOverride o) async {}
  @override Future<void> delete(String scheduleId, DateTime date) async {}
  @override Future<void> deleteAllForSchedule(String scheduleId) async {}
}

// ─── 공유 헬퍼 ──────────────────────────────────────────────────────────────

const _customTypeId = 'custom-001';

ShiftType _makeCustomType() => ShiftType(
      id: _customTypeId,
      name: '스페셜',
      startHour: 6,
      startMinute: 0,
      endHour: 14,
      endMinute: 0,
      colorValue: 0xFF4CAF50,
    );

/// 커스텀 근무 유형을 사용하는 스케줄
Schedule _makeScheduleUsingCustom() => Schedule(
      id: 'sched-custom',
      name: '커스텀 포함 일정',
      cycleStartDate: DateTime(2024, 1, 1),
      cycleBlocks: [
        CycleBlock(shiftTypeId: _customTypeId, days: 2),
        CycleBlock(shiftTypeId: 'off', days: 1),
      ],
    );

Widget _buildApp({
  required List<ShiftType> shiftTypes,
  List<Schedule> schedules = const [],
  String activeScheduleId = '',
}) {
  final defaultTypes = ShiftType.defaults();
  final allTypes = [...defaultTypes, ...shiftTypes];

  return ProviderScope(
    overrides: [
      scheduleRepositoryProvider.overrideWithValue(
          _FakeScheduleRepository(schedules)),
      settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository(
        AppSettings(
          activeScheduleId: activeScheduleId,
          notificationEnabled: false,
          notificationMinutesBefore: 30,
        ),
      )),
      shiftTypeRepositoryProvider.overrideWithValue(
          _FakeShiftTypeRepository(allTypes)),
      overrideRepositoryProvider.overrideWithValue(_FakeOverrideRepository()),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

// ─── 테스트 ───────────────────────────────────────────────────────────────────

void main() {
  // ─── P2 Bug #4: 사용 중인 커스텀 유형 삭제 시 경고 다이얼로그 ──────────
  testWidgets('사용 중인 커스텀 근무 유형 삭제 시 경고 다이얼로그가 표시된다',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      shiftTypes: [_makeCustomType()],
      schedules: [_makeScheduleUsingCustom()],
      activeScheduleId: 'sched-custom',
    ));
    await tester.pump();

    // 커스텀 유형의 삭제 버튼 탭 (스크롤로 화면에 표시 후 탭)
    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // 경고 다이얼로그가 표시돼야 함
    expect(find.textContaining('사용 중'), findsOneWidget,
        reason: '사용 중인 근무 유형 삭제 시 경고 메시지가 표시돼야 함');
  });

  testWidgets('사용 중인 커스텀 근무 유형은 경고 없이 바로 삭제되지 않는다',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      shiftTypes: [_makeCustomType()],
      schedules: [_makeScheduleUsingCustom()],
      activeScheduleId: 'sched-custom',
    ));
    await tester.pump();

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // 경고 다이얼로그가 있어야 하고 아직 유형이 삭제되지 않았어야 함
    expect(find.text('스페셜'), findsWidgets,
        reason: '경고 다이얼로그 닫기 전에는 유형이 유지돼야 함');
  });

  testWidgets('사용되지 않는 커스텀 근무 유형은 경고 없이 즉시 삭제된다',
      (tester) async {
    await tester.pumpWidget(_buildApp(
      shiftTypes: [_makeCustomType()],
      schedules: [], // 이 유형을 사용하는 스케줄 없음
    ));
    await tester.pump();

    await tester.ensureVisible(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // 경고 없이 즉시 삭제 (다이얼로그 없음)
    expect(find.textContaining('사용 중'), findsNothing,
        reason: '미사용 근무 유형은 경고 없이 삭제돼야 함');
  });
}
