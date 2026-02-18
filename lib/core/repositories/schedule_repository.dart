import 'package:hive_flutter/hive_flutter.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  static const _boxName = 'schedules';
  late Box<Schedule> _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<Schedule>(_boxName);
    } else {
      _box = await Hive.openBox<Schedule>(_boxName);
    }
  }

  List<Schedule> getAll() => _box.values.toList();

  Schedule? getById(String id) =>
      _box.values.where((s) => s.id == id).firstOrNull;

  Future<void> save(Schedule schedule) async {
    await _box.put(schedule.id, schedule);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
