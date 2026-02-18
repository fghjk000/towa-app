import 'package:hive_flutter/hive_flutter.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4)
class AppSettings {
  @HiveField(0)
  String activeScheduleId;
  @HiveField(1)
  bool notificationEnabled;
  @HiveField(2)
  int notificationMinutesBefore;

  AppSettings({
    required this.activeScheduleId,
    this.notificationEnabled = true,
    this.notificationMinutesBefore = 30,
  });
}
