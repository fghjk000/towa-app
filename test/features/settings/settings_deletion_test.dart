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

  @override
  Future<void> init() async {}
  @override
  List<Schedule> getAll() => List.unmodifiable(_items);
  @override
  Schedule? getById(String id) =>
      _items.where((s) => s.id == id).firstOrNull;
  @override
  Future<void> save(Schedule schedule) async {
    final idx = _items.indexWhere((s) => s.id == schedule.id);
    if (idx >= 0) { _items[idx] = schedule; }
    else { _items.add(schedule); }
  }
  @override
  Future<void> delete(String id) async {
    _items.removeWhere((s) => s.id == id);
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _current;
  _FakeSettingsRepository(this._current);

  @override
  Future<void> init() async {}
  @override
  AppSettings get settings => _current;
  @override
  Future<void> save(AppSettings s) async { _current = s; }
}

class _FakeShiftTypeRepository implements ShiftTypeRepository {
  final List<ShiftType> _items = ShiftType.defaults();
  @override Future<void> init() async {}
  @override List<ShiftType> getAll() => _items;
  @override Future<void> save(ShiftType type) async {}
  @override Future<void> delete(String id) async {}
}

class _FakeOverrideRepository implements OverrideRepository {
  final List<DateOverride> _items;
  _FakeOverrideRepository(List<DateOverride> items) : _items = List.of(items);

  @override Future<void> init() async {}
  @override
  List<DateOverride> getForSchedule(String scheduleId) =>
      _items.where((o) => o.scheduleId == scheduleId).toList();
  @override
  Future<void> save(DateOverride override) async { _items.add(override); }
  @override
  Future<void> delete(String scheduleId, DateTime date) async {}
  @override
  Future<void> deleteAllForSchedule(String scheduleId) async {
    _items.removeWhere((o) => o.scheduleId == scheduleId);
  }
}

// ─── 헬퍼 ────────────────────────────────────────────────────────────────────

const _scheduleId = 'sched-001';

Schedule _makeSchedule() => Schedule(
      id: _scheduleId,
      name: '직장A',
      cycleStartDate: DateTime(2024, 1, 1),
      cycleBlocks: [CycleBlock(shiftTypeId: 'day', days: 1)],
    );

AppSettings _makeSettingsWithActive() => AppSettings(
      activeScheduleId: _scheduleId,
      notificationEnabled: false,
      notificationMinutesBefore: 30,
    );

// ─── 테스트 ───────────────────────────────────────────────────────────────────

void main() {
  Widget buildApp({
    required _FakeScheduleRepository schedRepo,
    required _FakeSettingsRepository settRepo,
    required _FakeOverrideRepository overRepo,
  }) {
    return ProviderScope(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(schedRepo),
        settingsRepositoryProvider.overrideWithValue(settRepo),
        shiftTypeRepositoryProvider.overrideWithValue(_FakeShiftTypeRepository()),
        overrideRepositoryProvider.overrideWithValue(overRepo),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  // ─── P1 Bug #2: 활성 일정 삭제 후 activeScheduleId 초기화 ─────────────
  testWidgets('활성 일정을 삭제하면 activeScheduleId가 빈 문자열로 초기화된다',
      (tester) async {
    final schedRepo = _FakeScheduleRepository([_makeSchedule()]);
    final settRepo = _FakeSettingsRepository(_makeSettingsWithActive());
    final overRepo = _FakeOverrideRepository([]);

    await tester.pumpWidget(buildApp(
      schedRepo: schedRepo,
      settRepo: settRepo,
      overRepo: overRepo,
    ));
    await tester.pump();

    // 일정 항목 롱프레스 → 삭제 다이얼로그 열기
    await tester.longPress(find.text('직장A'));
    await tester.pumpAndSettle();

    // "삭제" 버튼 탭
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    // 활성 일정이 삭제되었으므로 activeScheduleId가 '' 이어야 함
    expect(settRepo.settings.activeScheduleId, '',
        reason: '활성 일정 삭제 후 activeScheduleId가 초기화돼야 함');
  });

  // ─── P1 Bug #3: 일정 삭제 시 DateOverride 고아 데이터 정리 ─────────────
  testWidgets('일정을 삭제하면 해당 일정의 DateOverride가 모두 삭제된다',
      (tester) async {
    final schedRepo = _FakeScheduleRepository([_makeSchedule()]);
    final settRepo = _FakeSettingsRepository(_makeSettingsWithActive());
    final overRepo = _FakeOverrideRepository([
      DateOverride(
          scheduleId: _scheduleId,
          date: DateTime(2024, 1, 1),
          shiftTypeId: 'night'),
      DateOverride(
          scheduleId: _scheduleId,
          date: DateTime(2024, 1, 2),
          shiftTypeId: 'night'),
    ]);

    await tester.pumpWidget(buildApp(
      schedRepo: schedRepo,
      settRepo: settRepo,
      overRepo: overRepo,
    ));
    await tester.pump();

    await tester.longPress(find.text('직장A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    // 해당 스케줄의 모든 override가 삭제돼야 함
    expect(overRepo.getForSchedule(_scheduleId).length, 0,
        reason: '삭제된 일정의 DateOverride가 모두 정리돼야 함');
  });

  // ─── 비활성 일정 삭제 시 activeScheduleId 변경 없음 ───────────────────
  testWidgets('비활성 일정을 삭제해도 activeScheduleId가 유지된다', (tester) async {
    const otherId = 'sched-other';
    final otherSchedule = Schedule(
      id: otherId,
      name: '직장B',
      cycleStartDate: DateTime(2024, 1, 1),
      cycleBlocks: [CycleBlock(shiftTypeId: 'day', days: 1)],
    );
    // 활성 일정은 _scheduleId, 삭제할 것은 otherId
    final schedRepo =
        _FakeScheduleRepository([_makeSchedule(), otherSchedule]);
    final settRepo = _FakeSettingsRepository(_makeSettingsWithActive());
    final overRepo = _FakeOverrideRepository([]);

    await tester.pumpWidget(buildApp(
      schedRepo: schedRepo,
      settRepo: settRepo,
      overRepo: overRepo,
    ));
    await tester.pump();

    await tester.longPress(find.text('직장B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    // 활성 일정 ID는 그대로여야 함
    expect(settRepo.settings.activeScheduleId, _scheduleId,
        reason: '비활성 일정 삭제 시 activeScheduleId 유지');
  });
}
