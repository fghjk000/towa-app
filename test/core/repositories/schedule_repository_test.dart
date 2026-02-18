import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shift_widget_app/core/models/app_settings.dart';
import 'package:shift_widget_app/core/models/cycle_block.dart';
import 'package:shift_widget_app/core/models/overtime_entry.dart';
import 'package:shift_widget_app/core/models/schedule.dart';
import 'package:shift_widget_app/core/models/shift_type.dart';
import 'package:shift_widget_app/core/repositories/schedule_repository.dart';
import 'package:shift_widget_app/core/repositories/settings_repository.dart';

void main() {
  setUpAll(() async {
    Hive.init('./test/hive_test_db');
    Hive.registerAdapter(ShiftTypeAdapter());
    Hive.registerAdapter(CycleBlockAdapter());
    Hive.registerAdapter(ScheduleAdapter());
    Hive.registerAdapter(OvertimeEntryAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
  });

  tearDown(() async {
    final box1 = Hive.isBoxOpen('schedules')
        ? Hive.box<Schedule>('schedules')
        : null;
    await box1?.clear();
    final box2 = Hive.isBoxOpen('settings')
        ? Hive.box<AppSettings>('settings')
        : null;
    await box2?.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('ScheduleRepository', () {
    test('일정을 저장하고 불러올 수 있다', () async {
      final repo = ScheduleRepository();
      await repo.init();

      final schedule = Schedule(
        id: 's1',
        name: '직장A',
        cycleStartDate: DateTime(2024, 1, 1),
        cycleBlocks: [CycleBlock(shiftTypeId: 'day', days: 2)],
      );

      await repo.save(schedule);
      final all = repo.getAll();
      expect(all.length, 1);
      expect(all.first.name, '직장A');
    });

    test('일정을 삭제할 수 있다', () async {
      final repo = ScheduleRepository();
      await repo.init();

      final schedule = Schedule(
        id: 's2',
        name: '직장B',
        cycleStartDate: DateTime(2024, 1, 1),
        cycleBlocks: [],
      );

      await repo.save(schedule);
      await repo.delete('s2');
      expect(repo.getAll().length, 0);
    });

    test('id로 일정을 조회할 수 있다', () async {
      final repo = ScheduleRepository();
      await repo.init();

      final schedule = Schedule(
        id: 's3',
        name: '직장C',
        cycleStartDate: DateTime(2024, 1, 1),
        cycleBlocks: [],
      );
      await repo.save(schedule);

      final found = repo.getById('s3');
      expect(found?.name, '직장C');
    });
  });

  group('SettingsRepository', () {
    test('기본 설정을 반환한다', () async {
      final repo = SettingsRepository();
      await repo.init();

      final settings = repo.settings;
      expect(settings.notificationEnabled, true);
      expect(settings.notificationMinutesBefore, 30);
    });

    test('설정을 저장하고 불러올 수 있다', () async {
      final repo = SettingsRepository();
      await repo.init();

      final newSettings = AppSettings(
        activeScheduleId: 'test-id',
        notificationEnabled: false,
        notificationMinutesBefore: 60,
      );
      await repo.save(newSettings);

      final loaded = repo.settings;
      expect(loaded.activeScheduleId, 'test-id');
      expect(loaded.notificationEnabled, false);
      expect(loaded.notificationMinutesBefore, 60);
    });
  });
}
