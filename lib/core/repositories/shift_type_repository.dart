import 'package:hive_flutter/hive_flutter.dart';
import '../models/shift_type.dart';

class ShiftTypeRepository {
  static const _boxName = 'shiftTypes';
  late Box<ShiftType> _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<ShiftType>(_boxName);
    } else {
      _box = await Hive.openBox<ShiftType>(_boxName);
    }
    // 최초 실행 시 기본값 저장
    if (_box.isEmpty) {
      for (final t in ShiftType.defaults()) {
        await _box.put(t.id, t);
      }
    } else {
      // 기존 사용자: 새로 추가된 기본 유형이 없으면 추가
      for (final t in ShiftType.defaults()) {
        if (!_box.containsKey(t.id)) {
          await _box.put(t.id, t);
        }
      }
    }
  }

  List<ShiftType> getAll() => _box.values.toList();

  Future<void> save(ShiftType type) async {
    await _box.put(type.id, type);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
