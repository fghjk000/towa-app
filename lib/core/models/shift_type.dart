import 'package:hive_flutter/hive_flutter.dart';

part 'shift_type.g.dart';

@HiveType(typeId: 0)
class ShiftType {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int startHour;
  @HiveField(3)
  final int startMinute;
  @HiveField(4)
  final int endHour;
  @HiveField(5)
  final int endMinute;
  @HiveField(6)
  final int colorValue;
  @HiveField(7)
  final bool isOff;

  ShiftType({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorValue,
    this.isOff = false,
  });

  static List<ShiftType> defaults() => [
    ShiftType(id: 'day', name: '주간', startHour: 8, startMinute: 0,
        endHour: 17, endMinute: 0, colorValue: 0xFFFFEB3B),
    ShiftType(id: 'night', name: '야간', startHour: 22, startMinute: 0,
        endHour: 6, endMinute: 0, colorValue: 0xFF3F51B5),
    ShiftType(id: 'off', name: '휴무', startHour: 0, startMinute: 0,
        endHour: 0, endMinute: 0, colorValue: 0xFF9E9E9E, isOff: true),
  ];
}
