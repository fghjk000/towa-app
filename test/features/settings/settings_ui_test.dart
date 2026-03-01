import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_widget_app/core/models/app_settings.dart';
import 'package:shift_widget_app/core/models/date_override.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';
import 'package:shift_widget_app/core/providers/schedule_providers.dart';
import 'package:shift_widget_app/core/repositories/override_repository.dart';
import 'package:shift_widget_app/core/repositories/schedule_repository.dart';
import 'package:shift_widget_app/core/repositories/settings_repository.dart';
import 'package:shift_widget_app/core/repositories/shift_type_repository.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/features/settings/settings_screen.dart';

class _FakeScheduleRepository implements ScheduleRepository {
  @override Future<void> init() async {}
  @override List<Schedule> getAll() => [];
  @override Schedule? getById(String id) => null;
  @override Future<void> save(Schedule schedule) async {}
  @override Future<void> delete(String id) async {}
}

class _FakeSettingsRepository implements SettingsRepository {
  @override Future<void> init() async {}
  @override AppSettings get settings => AppSettings(
      activeScheduleId: '',
      notificationEnabled: false,
      notificationMinutesBefore: 30);
  @override Future<void> save(AppSettings s) async {}
}

class _FakeShiftTypeRepository implements ShiftTypeRepository {
  final List<ShiftType> _items = ShiftType.defaults();
  @override Future<void> init() async {}
  @override List<ShiftType> getAll() => _items;
  @override Future<void> save(ShiftType type) async {}
  @override Future<void> delete(String id) async {}
}

class _FakeOverrideRepository implements OverrideRepository {
  @override Future<void> init() async {}
  @override List<DateOverride> getForSchedule(String id) => [];
  @override Future<void> save(DateOverride o) async {}
  @override Future<void> delete(String scheduleId, DateTime date) async {}
  @override Future<void> deleteAllForSchedule(String scheduleId) async {}
}

Widget _buildSettingsApp() => ProviderScope(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(_FakeScheduleRepository()),
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        shiftTypeRepositoryProvider.overrideWithValue(_FakeShiftTypeRepository()),
        overrideRepositoryProvider.overrideWithValue(_FakeOverrideRepository()),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );

void main() {
  // ─── P2 Bug #5: "iPad" 하드코딩 텍스트 없어야 함 ───────────────────────
  testWidgets('알림 권한 거부 안내 메시지에 "iPad"가 하드코딩되지 않는다', (tester) async {
    await tester.pumpWidget(_buildSettingsApp());
    // pumpAndSettle로 _checkPermission() 비동기 완료까지 대기
    await tester.pumpAndSettle();

    // 권한 거부 상태에서 "iPad 설정 앱" 하드코딩 문구가 없어야 함
    // iPhone 사용자 혼란 방지 — "이 기기" 같은 범용 표현 사용
    expect(find.textContaining('iPad 설정 앱'), findsNothing,
        reason: '"iPad" 단독 하드코딩 안내문이 없어야 함');
  });
}
