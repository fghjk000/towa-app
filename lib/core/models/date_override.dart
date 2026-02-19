import 'package:hive_flutter/hive_flutter.dart';
part 'date_override.g.dart';

@HiveType(typeId: 5)
class DateOverride {
  @HiveField(0)
  final String scheduleId;

  @HiveField(1)
  final DateTime date; // midnight normalized (DateTime(y,m,d))

  @HiveField(2)
  final String shiftTypeId;

  DateOverride({
    required this.scheduleId,
    required this.date,
    required this.shiftTypeId,
  });
}
