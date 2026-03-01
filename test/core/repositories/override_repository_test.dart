import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shift_widget_app/core/models/app_settings.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/date_override.dart';
import 'package:shift_widget_app/core/models/overtime_entry.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';
import 'package:shift_widget_app/core/repositories/override_repository.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_test_db');
    Hive.registerAdapter(ShiftTypeAdapter());
    Hive.registerAdapter(CycleBlockAdapter());
    Hive.registerAdapter(ScheduleAdapter());
    Hive.registerAdapter(OvertimeEntryAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(DateOverrideAdapter());
  });

  tearDown(() async {
    if (Hive.isBoxOpen('dateOverrides')) {
      await Hive.box<DateOverride>('dateOverrides').clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('OverrideRepository', () {
    test('override를 저장하고 스케줄 ID로 조회할 수 있다', () async {
      final repo = OverrideRepository();
      await repo.init();

      await repo.save(DateOverride(
        scheduleId: 's1',
        date: DateTime(2024, 1, 1),
        shiftTypeId: 'night',
      ));

      final result = repo.getForSchedule('s1');
      expect(result.length, 1);
      expect(result.first.shiftTypeId, 'night');
    });

    test('특정 날짜의 override를 삭제할 수 있다', () async {
      final repo = OverrideRepository();
      await repo.init();

      await repo.save(DateOverride(
        scheduleId: 's1',
        date: DateTime(2024, 1, 1),
        shiftTypeId: 'night',
      ));
      await repo.delete('s1', DateTime(2024, 1, 1));

      expect(repo.getForSchedule('s1').length, 0);
    });

    // ─── P1 Bug #3: deleteAllForSchedule 검증 ───────────────────────────
    test('deleteAllForSchedule는 해당 스케줄의 모든 override를 삭제한다', () async {
      final repo = OverrideRepository();
      await repo.init();

      // 스케줄 's1'에 여러 날짜 override 저장
      for (var day = 1; day <= 5; day++) {
        await repo.save(DateOverride(
          scheduleId: 's1',
          date: DateTime(2024, 1, day),
          shiftTypeId: 'night',
        ));
      }
      // 다른 스케줄 's2'에도 저장
      await repo.save(DateOverride(
        scheduleId: 's2',
        date: DateTime(2024, 1, 1),
        shiftTypeId: 'day',
      ));

      // 's1' 전체 삭제
      await repo.deleteAllForSchedule('s1');

      expect(repo.getForSchedule('s1').length, 0, reason: 's1 override가 모두 삭제돼야 함');
      expect(repo.getForSchedule('s2').length, 1, reason: 's2 override는 유지돼야 함');
    });
  });
}
