import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../models/date_override.dart';
import '../models/schedule.dart';
import '../models/shift_type.dart';
import '../repositories/override_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/settings_repository.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  throw UnimplementedError('main에서 override 필요');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('main에서 override 필요');
});

// 일정 목록
final schedulesProvider =
    StateNotifierProvider<SchedulesNotifier, List<Schedule>>((ref) {
  return SchedulesNotifier(ref.watch(scheduleRepositoryProvider));
});

class SchedulesNotifier extends StateNotifier<List<Schedule>> {
  final ScheduleRepository _repo;

  SchedulesNotifier(this._repo) : super(_repo.getAll());

  Future<void> save(Schedule schedule) async {
    await _repo.save(schedule);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

// 현재 활성 일정
final activeScheduleProvider = Provider<Schedule?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final schedules = ref.watch(schedulesProvider);
  return schedules
      .where((s) => s.id == settings.activeScheduleId)
      .firstOrNull;
});

// 앱 설정
final appSettingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(_repo.settings);

  Future<void> update(AppSettings settings) async {
    await _repo.save(settings);
    state = settings;
  }
}

// 근무 유형 목록 (앱 메모리에만 저장, 기본값으로 시작)
final shiftTypesProvider =
    StateNotifierProvider<ShiftTypesNotifier, List<ShiftType>>((ref) {
  return ShiftTypesNotifier();
});

class ShiftTypesNotifier extends StateNotifier<List<ShiftType>> {
  ShiftTypesNotifier() : super(ShiftType.defaults());

  void add(ShiftType type) => state = [...state, type];

  void remove(String id) =>
      state = state.where((t) => t.id != id).toList();

  void update(ShiftType type) =>
      state = state.map((t) => t.id == type.id ? type : t).toList();
}

final overrideRepositoryProvider = Provider<OverrideRepository>((ref) {
  throw UnimplementedError('main에서 override 필요');
});

final overridesProvider =
    StateNotifierProvider<OverridesNotifier, List<DateOverride>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return OverridesNotifier(
    ref.watch(overrideRepositoryProvider),
    settings.activeScheduleId,
  );
});

class OverridesNotifier extends StateNotifier<List<DateOverride>> {
  final OverrideRepository _repo;
  final String? _scheduleId;

  OverridesNotifier(this._repo, this._scheduleId)
      : super(_scheduleId != null ? _repo.getForSchedule(_scheduleId) : []);

  Future<void> saveOverride(DateOverride override) async {
    if (_scheduleId == null || override.scheduleId != _scheduleId) return;
    await _repo.save(override);
    state = _repo.getForSchedule(_scheduleId);
  }

  Future<void> deleteOverride(String scheduleId, DateTime date) async {
    if (_scheduleId == null) return;
    await _repo.delete(scheduleId, date);
    state = _repo.getForSchedule(_scheduleId);
  }
}
