import 'package:hive_flutter/hive_flutter.dart';

part 'overtime_entry.g.dart';

@HiveType(typeId: 3)
class OvertimeEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String? note;
  @HiveField(3)
  final int? startHour;
  @HiveField(4)
  final int? startMinute;
  @HiveField(5)
  final int? endHour;
  @HiveField(6)
  final int? endMinute;

  OvertimeEntry({
    required this.id,
    required this.date,
    this.note,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
  });
}
