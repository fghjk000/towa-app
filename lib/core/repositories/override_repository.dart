import 'package:hive_flutter/hive_flutter.dart';
import '../models/date_override.dart';

class OverrideRepository {
  static const _boxName = 'dateOverrides';
  late Box<DateOverride> _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<DateOverride>(_boxName);
    } else {
      _box = await Hive.openBox<DateOverride>(_boxName);
    }
  }

  List<DateOverride> getForSchedule(String scheduleId) =>
      _box.values.where((o) => o.scheduleId == scheduleId).toList();

  Future<void> save(DateOverride override) async {
    final key = '${override.scheduleId}_${override.date.millisecondsSinceEpoch}';
    await _box.put(key, override);
  }

  Future<void> delete(String scheduleId, DateTime date) async {
    final key = '${scheduleId}_${date.millisecondsSinceEpoch}';
    await _box.delete(key);
  }

  Future<void> deleteAllForSchedule(String scheduleId) async {
    final toDelete = _box.toMap().entries
        .where((e) => e.value.scheduleId == scheduleId)
        .map((e) => e.key)
        .toList();
    await _box.deleteAll(toDelete);
  }
}
